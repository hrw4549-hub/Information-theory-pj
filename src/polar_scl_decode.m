function info_hat = polar_scl_decode(rx_llr, N, info_idx, L_max, crc_poly)
%POLAR_SCL_DECODE  极化码 SC-List 译码 (LLR 域路径度量, 可选 CRC 选路)
%
%   info_hat = POLAR_SCL_DECODE(rx_llr, N, info_idx, L_max)
%   info_hat = POLAR_SCL_DECODE(rx_llr, N, info_idx, L_max, crc_poly)
%
%   输入:
%       rx_llr   : 1×N 接收信道 LLR (与 polar_sc_decode 同约定)
%       N        : 码长 (2 的幂)
%       info_idx : 信息位索引 (与编码端一致)
%       L_max    : 列表大小, 通常取 4/8/16/32
%       crc_poly : (可选) CRC 多项式. 提供时 info_idx 上的比特解释为
%                  [info, crc], 选路时优先选 CRC 通过的路径; 不提供则
%                  按最小路径度量返回。返回的 info_hat 已剥离 CRC。
%
%   输出:
%       info_hat : 1×K_info 译出的信息比特 (已去掉 CRC, 若使用)
%
%   原理:
%       - 同时维护 ≤ L_max 条候选路径; 每碰到信息位, 每条路径分裂成两条
%         (尝试 0/1), 然后按路径度量 PM 升序保留前 L_max 条。
%       - 路径度量增量 (LLR 域 min-sum 近似):
%             u=0:  pen = max(0, -LLR)     (LLR<0 时罚 |LLR|)
%             u=1:  pen = max(0,  LLR)
%       - 末尾若有 CRC, 按 PM 顺序遍历, 第一条 CRC 通过的路径胜出。
%
%   参考: Tal & Vardy 2011, "List decoding of polar codes".

    if nargin < 5
        crc_poly = [];
    end
    has_crc = ~isempty(crc_poly);
    crc_len = 0;
    if has_crc
        crc_len = numel(crc_poly) - 1;
    end

    rx_llr = rx_llr(:).';
    if numel(rx_llr) ~= N
        error('polar_scl_decode:length', 'LLR 长度应为 N=%d', N);
    end
    if abs(log2(N) - round(log2(N))) > 1e-9
        error('polar_scl_decode:N', 'N 必须是 2 的幂');
    end

    is_info             = false(1, N);
    is_info(info_idx)   = true;

    % 路径状态: paths_u 为 nP×N, 每行一条路径的 u_hat (按位填充)
    paths_u  = zeros(1, N);
    paths_pm = 0;                    % 列向量 (单元素)

    for i = 1:N
        nP   = size(paths_u, 1);
        llrs = zeros(nP, 1);
        for p = 1:nP
            llrs(p) = compute_llr_for_bit(rx_llr, paths_u(p, 1:i - 1), i, N);
        end

        if is_info(i)
            % --- 分裂每条路径为 2, 然后修剪到 L_max ---
            new_u  = repelem(paths_u,  2, 1);            % 2nP × N
            new_pm = repelem(paths_pm, 2, 1);            % 2nP × 1
            new_u(1:2:end, i) = 0;
            new_u(2:2:end, i) = 1;
            new_pm(1:2:end) = paths_pm + max(0, -llrs);  % 选 0 的代价
            new_pm(2:2:end) = paths_pm + max(0,  llrs);  % 选 1 的代价

            [new_pm, order] = sort(new_pm, 'ascend');
            new_u           = new_u(order, :);
            keep            = min(L_max, size(new_u, 1));
            paths_u         = new_u(1:keep, :);
            paths_pm        = new_pm(1:keep);
        else
            % --- 冻结位强制 0 ---
            paths_u(:, i) = 0;
            paths_pm      = paths_pm + max(0, -llrs);
        end
    end

    % --- 终选 ---
    if has_crc
        [paths_pm, order] = sort(paths_pm, 'ascend');
        paths_u           = paths_u(order, :);
        for p = 1:size(paths_u, 1)
            payload = paths_u(p, info_idx);
            if crc_check(payload, crc_poly)
                info_hat = payload(1:end - crc_len);
                return;
            end
        end
        % 全部 CRC 失败 -> 回退到最小 PM, 剥离 CRC
        info_hat = paths_u(1, info_idx);
        info_hat = info_hat(1:end - crc_len);
    else
        [~, p]  = min(paths_pm);
        info_hat = paths_u(p, info_idx);
    end
end


% =========================================================================
% 局部辅助: 用单条路径已确定的 u_hat 在子树上求 u_target 的 LLR
% =========================================================================
function llr = compute_llr_for_bit(L_top, u_known, target, N)
    L     = L_top;
    u_rem = u_known;
    t     = target;
    Nsub  = N;
    while Nsub > 1
        half = Nsub / 2;
        a    = L(1:half);
        b    = L(half + 1:end);
        if t <= half
            % --- 上半子树 (f 节点) ---
            L = sign(a) .* sign(b) .* min(abs(a), abs(b));
        else
            % --- 下半子树 (g 节点), 需上半已译比特的部分编码 ---
            x_up = partial_polar_encode(u_rem(1:half));
            L    = b + (1 - 2 * x_up) .* a;
            u_rem = u_rem(half + 1:end);
            t     = t - half;
        end
        Nsub = half;
    end
    llr = L(1);
end


function x = partial_polar_encode(u)
%PARTIAL_POLAR_ENCODE  对长度 M (2 的幂) 的 u 做 F^{⊗log2 M} 变换
    M = numel(u);
    x = u;
    if M <= 1
        return;
    end
    for lvl = 1:log2(M)
        block = 2^lvl;
        half  = block / 2;
        for blk_start = 1:block:M
            idx_l = blk_start : blk_start + half - 1;
            idx_r = blk_start + half : blk_start + block - 1;
            x(idx_l) = mod(x(idx_l) + x(idx_r), 2);
        end
    end
end
