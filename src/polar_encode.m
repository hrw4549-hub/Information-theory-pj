function [coded_bits, info_idx] = polar_encode(info_bits, N, info_idx)
%POLAR_ENCODE  极化码编码器 (自然顺序, 不带 CRC)
%
%   [coded_bits, info_idx] = POLAR_ENCODE(info_bits, N)
%   [coded_bits, info_idx] = POLAR_ENCODE(info_bits, N, info_idx)
%
%   输入:
%       info_bits : 1×K 信息比特行向量, 元素 0/1
%       N         : 码长, 2 的整数次幂, 必须 >= K
%       info_idx  : (可选) 信息位的位置索引 (1..N, 升序)。
%                   不提供时由 polar_construct 自动生成。
%
%   输出:
%       coded_bits : 1×N 编码后比特流 (0/1)
%       info_idx   : 实际使用的信息位索引 (供译码端使用)
%
%   原理:
%       u : 长度 N 的源向量, 信息位放 info_bits, 冻结位置 0;
%       x = u * G_N, 其中 G_N = F^{⊗ n}, F = [1 0; 1 1].
%       这里使用蝶形递推, 复杂度 O(N log N).

    info_bits = info_bits(:).';
    K         = numel(info_bits);

    n_levels = log2(N);
    if abs(n_levels - round(n_levels)) > 1e-9
        error('polar_encode:N', 'N=%d 不是 2 的幂', N);
    end
    if K > N
        error('polar_encode:K', 'K=%d 超过码长 N=%d', K, N);
    end
    if any(info_bits ~= 0 & info_bits ~= 1)
        error('polar_encode:badInput', '信息比特必须为 0/1');
    end

    if nargin < 3 || isempty(info_idx)
        info_idx = polar_construct(N, K);
    else
        info_idx = sort(info_idx(:).');
        if numel(info_idx) ~= K
            error('polar_encode:idx', 'info_idx 长度与信息比特数不一致');
        end
    end

    % 1) 摆位: 信息位 + 冻结位 -> u
    u            = zeros(1, N);
    u(info_idx)  = info_bits;

    % 2) 极化变换 (蝶形, 原地实现)
    %    递推关系: x_{2i-1} = u_{2i-1} XOR u_{2i}, x_{2i} = u_{2i}
    x = u;
    n_levels = round(n_levels);
    for lvl = 1:n_levels
        block = 2^lvl;
        half  = block / 2;
        for blk_start = 1:block:N
            idx_l = blk_start : blk_start + half - 1;
            idx_r = blk_start + half : blk_start + block - 1;
            x(idx_l) = mod(x(idx_l) + x(idx_r), 2);
        end
    end

    coded_bits = x;
end
