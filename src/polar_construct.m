function info_idx = polar_construct(N, K, design_snr_dB)
%POLAR_CONSTRUCT  极化码信息位选取 (高斯近似 GA, AWGN 设计信道)
%
%   info_idx = POLAR_CONSTRUCT(N, K)
%   info_idx = POLAR_CONSTRUCT(N, K, design_snr_dB)
%
%   输入:
%       N             : 码长, 必须是 2 的整数次幂
%       K             : 信息位数, 1 <= K <= N
%       design_snr_dB : (可选) 设计 Eb/N0 (dB), 默认 2.5 dB
%
%   输出:
%       info_idx : 1×K 行向量, 信息比特放置位置 (1-based, 升序),
%                  其余 N-K 个位置是冻结位 (置 0)。
%
%   原理:
%       BPSK + AWGN 下 LLR 近似为高斯随机变量, 用其均值 mu 衡量子信道可靠性。
%
%       初始值 (BPSK, x=±1, sigma^2 = 1/(2 R 10^{SNR/10})):
%           mu_0 = 2 / sigma^2
%
%       GA 极化递推:
%           mu(W^{(2i-1)}_N) = phi^{-1}( 1 - (1 - phi(mu))^2 )   % 较差子信道
%           mu(W^{(2i)  }_N) = 2 * mu                            % 较好子信道
%
%       mu 越大 -> 子信道越可靠 -> 选 mu 最大的 K 个位置承载信息位。

    if nargin < 3 || isempty(design_snr_dB)
        design_snr_dB = 2.5;
    end

    n_levels = log2(N);
    if abs(n_levels - round(n_levels)) > 1e-9
        error('polar_construct:N', 'N=%d 不是 2 的幂', N);
    end
    if K < 1 || K > N
        error('polar_construct:K', 'K 必须满足 1 <= K <= N');
    end

    R      = K / N;
    sigma2 = 1 / (2 * R * 10^(design_snr_dB / 10));
    mu     = 2 / sigma2;

    for lvl = 1:n_levels
        mu_new = zeros(1, 2 * numel(mu));
        for i = 1:numel(mu)
            mu_new(2*i - 1) = phi_inv(1 - (1 - phi_func(mu(i)))^2);  % 较差
            mu_new(2*i)     = 2 * mu(i);                             % 较好
        end
        mu = mu_new;
    end

    [~, order] = sort(mu, 'descend');     % mu 大 -> 信道好
    info_idx   = sort(order(1:K));        % 升序便于后续顺序处理
end


function y = phi_func(x)
%PHI_FUNC  GA 中 phi(x) 的分段近似 (Trifonov 2012)
    if x < 1e-10
        y = 1;
    elseif x < 10
        y = exp(-0.4527 * x^0.86 + 0.0218);
    else
        y = sqrt(pi / x) * exp(-x / 4) * (1 - 10 / (7 * x));
    end
end


function x = phi_inv(y)
%PHI_INV  phi(x) 的数值反函数 (phi 在 (0,inf) 上单调下降)
    if y >= 1
        x = 0;
        return;
    end
    if y <= 0
        x = inf;
        return;
    end
    y_boundary = exp(-0.4527 * 10^0.86 + 0.0218);     % phi(10)
    if y > y_boundary
        % 0 < x < 10, 闭式反解
        x = ((0.0218 - log(y)) / 0.4527)^(1 / 0.86);
    else
        % x >= 10, 二分搜索
        lo = 10;
        hi = 10;
        while phi_func(hi) > y
            hi = hi * 2;
            if hi > 1e8
                x = hi;
                return;
            end
        end
        for k = 1:100
            mid = 0.5 * (lo + hi);
            if phi_func(mid) > y
                lo = mid;
            else
                hi = mid;
            end
            if (hi - lo) < 1e-6
                break;
            end
        end
        x = 0.5 * (lo + hi);
    end
end
