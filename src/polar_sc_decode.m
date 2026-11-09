function info_hat = polar_sc_decode(received_llr, N, info_idx)
%POLAR_SC_DECODE  极化码连续消除 (Successive Cancellation, SC) 译码
%
%   info_hat = POLAR_SC_DECODE(received_llr, N, info_idx)
%
%   输入:
%       received_llr : 1×N 接收信道 LLR (log p(0|y) - log p(1|y)).
%                      约定: BPSK 映射 0->+1, 1->-1, 即 LLR>0 倾向于判 0.
%                      若仅有硬判决 0/1 比特, 可调用 hard2llr 转换。
%       N            : 码长 (2 的幂)
%       info_idx     : 信息位索引 (1..N), 与编码端一致
%
%   输出:
%       info_hat : 1×K 译出的信息比特 (K = numel(info_idx))
%
%   原理:
%       使用 LLR 域递归 SC 算法, f/g 节点分别对应 min-sum 与
%       带反馈的合并:
%           f(a,b) = sign(a) sign(b) min(|a|,|b|)
%           g(a,b,u_hat) = b + (1 - 2 u_hat) a
%       复杂度 O(N log N).
%
%   参考: Arikan 2009, "Channel polarization".

    received_llr = received_llr(:).';
    if numel(received_llr) ~= N
        error('polar_sc_decode:length', 'LLR 长度应等于 N=%d', N);
    end
    n_levels = log2(N);
    if abs(n_levels - round(n_levels)) > 1e-9
        error('polar_sc_decode:N', 'N=%d 不是 2 的幂', N);
    end

    frozen_mask                = true(1, N);
    frozen_mask(info_idx)      = false;          % info 位不冻结

    [u_hat, ~] = sc_recursion(received_llr, frozen_mask);

    info_hat = u_hat(info_idx);
end


function [u_hat, x_hat] = sc_recursion(L, frozen_mask)
%SC_RECURSION  长度 N 的子树 SC 译码, 返回源端 u 和编码端 x 两个估计向量
    N = numel(L);
    if N == 1
        if frozen_mask(1)
            u_hat = 0;                     % 冻结位
        else
            u_hat = double(L(1) < 0);      % LLR<0 -> 判 1
        end
        x_hat = u_hat;
        return;
    end

    half = N / 2;
    La   = L(1:half);
    Lb   = L(half + 1:end);

    % --- 上半子树: 用 f-节点求 LLR
    L_up  = f_node(La, Lb);
    [u_a, x_a] = sc_recursion(L_up, frozen_mask(1:half));

    % --- 下半子树: 用 g-节点 (需要上半的硬判) 求 LLR
    L_dn  = g_node(La, Lb, x_a);
    [u_b, x_b] = sc_recursion(L_dn, frozen_mask(half + 1:end));

    u_hat = [u_a, u_b];
    x_hat = [mod(x_a + x_b, 2), x_b];
end


function L = f_node(a, b)
% f 节点: min-sum 近似的"较差子信道" LLR 计算
%   严格 LLR: 2*atanh(tanh(a/2)*tanh(b/2)), 数值上不稳定;
%   工程实现常用 min-sum: sign(a)*sign(b)*min(|a|,|b|).
    L = sign(a) .* sign(b) .* min(abs(a), abs(b));
end


function L = g_node(a, b, u)
% g 节点: 带反馈的"较好子信道" LLR 计算
%   L = (-1)^u * a + b
    L = b + (1 - 2 * u) .* a;
end
