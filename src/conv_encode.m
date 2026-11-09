function [coded_bits, trellis] = conv_encode(info_bits, G)
%CONV_ENCODE  (n,1,K) 卷积码编码器
%   [coded_bits, trellis] = CONV_ENCODE(info_bits) 使用默认 (2,1,3) 码
%   生成多项式 g1=7(111), g2=5(101) 进行编码。
%   [coded_bits, trellis] = CONV_ENCODE(info_bits, G) 使用指定生成矩阵 G,
%   G 为 n×K 的 0/1 矩阵, 每一行表示一条生成多项式 (高位在前)。
%
%   输入:
%       info_bits : 1×L 行向量, 元素为 0/1 的信息比特流
%       G         : (可选) 生成矩阵, 默认 [1 1 1; 1 0 1]
%
%   输出:
%       coded_bits : 1×n*(L+K-1) 行向量, 编码后比特流 (含 K-1 个尾比特)
%       trellis    : 网格图结构体, 供 Viterbi 译码使用, 包含字段:
%                       .K, .n, .G, .num_states,
%                       .next_state(s+1, u+1) 下一状态
%                       .output(s+1, u+1)     n bit 列向量输出 (0/1)
%
%   示例:
%       bits   = [1 0 1 1 0 0 1];
%       [c, T] = conv_encode(bits);

    if nargin < 2 || isempty(G)
        G = [1 1 1; 1 0 1];   % g1=7, g2=5, K=3
    end

    info_bits = info_bits(:).';
    if any(info_bits ~= 0 & info_bits ~= 1)
        error('conv_encode:badInput', '信息比特只能是 0 或 1');
    end

    [n, K] = size(G);              % n 输出位数, K 约束长度
    m      = K - 1;                % 寄存器长度
    L      = numel(info_bits);

    % 添加 m 个 0 尾比特, 使最终回到全零状态, 便于译码回溯
    tail_bits   = zeros(1, m);
    input_bits  = [info_bits, tail_bits];
    Lx          = numel(input_bits);

    % 编码主循环
    shift_reg  = zeros(1, m);          % [u_{n-1}, u_{n-2}, ...]
    coded_bits = zeros(1, n * Lx);

    for k = 1:Lx
        u    = input_bits(k);
        regs = [u, shift_reg];          % 长度 K, 当前 + 历史
        out  = mod(G * regs.', 2);      % n×1
        coded_bits((k - 1) * n + (1:n)) = out.';
        shift_reg = regs(1:m);          % 更新寄存器
    end

    % 同时构造网格图 (Viterbi 译码会用到)
    if nargout > 1
        trellis = build_trellis(G);
    end
end


function trellis = build_trellis(G)
%BUILD_TRELLIS  根据生成矩阵构造网格图
    [n, K]     = size(G);
    m          = K - 1;
    num_states = 2^m;

    next_state = zeros(num_states, 2);
    output     = zeros(num_states, 2, n);

    for s = 0:num_states - 1
        % 状态 s 的二进制表示: [u_{n-1}, u_{n-2}, ...]
        regs_old = de2bi_local(s, m);
        for u = 0:1
            regs_full = [u, regs_old];                 % 长度 K
            out       = mod(G * regs_full.', 2);       % n×1
            new_regs  = regs_full(1:m);                % 新寄存器
            ns        = bi2de_local(new_regs);

            next_state(s + 1, u + 1)    = ns;
            output(s + 1, u + 1, :)     = out;
        end
    end

    trellis.K          = K;
    trellis.n          = n;
    trellis.G          = G;
    trellis.num_states = num_states;
    trellis.next_state = next_state;
    trellis.output     = output;     % num_states × 2 × n
end


function v = de2bi_local(d, n)
% 将十进制 d 转为长度 n 的行向量 (高位在前 -> 与状态约定一致)
    v = zeros(1, n);
    for i = 1:n
        v(i) = mod(d, 2);
        d    = floor(d / 2);
    end
end


function d = bi2de_local(v)
% 行向量 v 转十进制 (与 de2bi_local 互逆)
    d = 0;
    for i = numel(v):-1:1
        d = d * 2 + v(i);
    end
end
