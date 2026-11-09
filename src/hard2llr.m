function llr = hard2llr(bits, p)
%HARD2LLR  二进制对称信道 (BSC) 硬判决比特转 LLR
%
%   llr = HARD2LLR(bits)         默认 p = 0.1
%   llr = HARD2LLR(bits, p)      指定信道翻转概率 p
%
%   输入:
%       bits : 0/1 接收硬判决向量
%       p    : (可选) BSC 翻转概率, 0 < p < 0.5
%
%   输出:
%       llr  : 与 bits 等长的 LLR 向量
%              收到 0 -> +log((1-p)/p), 收到 1 -> -log((1-p)/p)
%              (与 polar_sc_decode 的 LLR 约定一致)

    if nargin < 2 || isempty(p)
        p = 0.1;
    end
    if p <= 0 || p >= 0.5
        error('hard2llr:p', 'BSC 翻转概率应在 (0, 0.5) 之间');
    end
    bits = bits(:).';
    L0   = log((1 - p) / p);     % 接收 0 时的 LLR
    llr  = (1 - 2 * bits) * L0;  % 0 -> +L0, 1 -> -L0
end
