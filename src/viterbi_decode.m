function [decoded_bits, metric] = viterbi_decode(received_bits, trellis, mode)
%VITERBI_DECODE  卷积码 Viterbi 译码 (硬判决, Hamming 距离作为分支度量)
%
%   decoded_bits = VITERBI_DECODE(received_bits, trellis)
%   decoded_bits = VITERBI_DECODE(received_bits, trellis, 'hard'|'soft')
%   [decoded_bits, metric] = VITERBI_DECODE(...)
%
%   输入:
%       received_bits : 1×N 接收向量, hard 模式下为 0/1, soft 模式下为
%                       接收的 BPSK 软值 (e.g. y = (1-2x)+n, x∈{0,1})
%       trellis       : 由 conv_encode 返回的网格图结构体
%       mode          : 'hard' (默认) 或 'soft'
%
%   输出:
%       decoded_bits  : 1×L 行向量, 译出的信息比特 (已去掉 K-1 尾比特)
%       metric        : 最终路径度量 (越小越好, soft 模式为相关度的相反数)
%
%   说明:
%       编码方在末尾追加了 K-1 个 0 尾比特, 因此译码起点和终点都强制为
%       全零状态, 这样可以显著提升尾部比特的译码可靠性。

    if nargin < 3 || isempty(mode)
        mode = 'hard';
    end

    n          = trellis.n;
    K          = trellis.K;
    m          = K - 1;
    num_states = trellis.num_states;
    next_state = trellis.next_state;
    output     = trellis.output;        % num_states × 2 × n

    received_bits = received_bits(:).';
    if mod(numel(received_bits), n) ~= 0
        error('viterbi_decode:length', ...
              '接收比特长度必须是 n=%d 的整数倍', n);
    end
    Lx     = numel(received_bits) / n;     % 网格图深度
    L_info = Lx - m;                       % 真正的信息比特数

    if L_info < 0
        error('viterbi_decode:tooShort', '接收数据过短, 不足以包含尾比特');
    end

    INF = 1e9;

    % path_metric(s) : 走到状态 s 的累计度量
    path_metric          = INF * ones(num_states, 1);
    path_metric(1)       = 0;     % 初始状态强制为 0
    survivor_state       = zeros(num_states, Lx);   % 前继状态 (1-based)
    survivor_input       = zeros(num_states, Lx);   % 该步输入

    for k = 1:Lx
        rk      = received_bits((k - 1) * n + (1:n));    % 1×n
        new_pm  = INF * ones(num_states, 1);
        new_ps  = zeros(num_states, 1);
        new_pi  = zeros(num_states, 1);

        for s = 1:num_states
            if path_metric(s) >= INF
                continue;            % 该状态尚不可达, 跳过
            end
            for u = 0:1
                ns_idx = next_state(s, u + 1) + 1;       % 下一状态索引
                expect = squeeze(output(s, u + 1, :)).'; % 1×n 期望输出

                if strcmpi(mode, 'hard')
                    % 硬判决: Hamming 距离
                    bm = sum(rk ~= expect);
                else
                    % 软判决: 期望输出 0->+1, 1->-1, 与 rk 做相关
                    sym = 1 - 2 * expect;                % BPSK
                    bm  = -sum(rk .* sym);               % 相关度的相反数
                end

                cand = path_metric(s) + bm;
                if cand < new_pm(ns_idx)
                    new_pm(ns_idx) = cand;
                    new_ps(ns_idx) = s;        % 1-based
                    new_pi(ns_idx) = u;
                end
            end
        end

        path_metric          = new_pm;
        survivor_state(:, k) = new_ps;
        survivor_input(:, k) = new_pi;
    end

    % 由于尾比特强制清零, 终点必为状态 0
    end_state = 1;          % 1-based, 对应状态 0
    metric    = path_metric(end_state);

    % 回溯
    decoded_full = zeros(1, Lx);
    cur_state    = end_state;
    for k = Lx:-1:1
        decoded_full(k) = survivor_input(cur_state, k);
        cur_state       = survivor_state(cur_state, k);
        if cur_state == 0
            % 不可达路径回溯, 应该不会发生
            warning('viterbi_decode:traceback', '回溯过程出现不可达状态');
            cur_state = 1;
        end
    end

    decoded_bits = decoded_full(1:L_info);
end
