function [rx_llr, rx_y] = awgn_llr(coded_bits, EbN0_dB, code_rate)
%AWGN_LLR  BPSK 调制 + AWGN 信道, 返回软 LLR
%
%   [rx_llr, rx_y] = AWGN_LLR(coded_bits, EbN0_dB)
%   [rx_llr, rx_y] = AWGN_LLR(coded_bits, EbN0_dB, code_rate)
%
%   输入:
%       coded_bits : 0/1 比特行向量 (编码后的码字)
%       EbN0_dB    : 比特信噪比 Eb/N0 (单位 dB)
%       code_rate  : (可选) 码率 R = K/N. 默认为 1.
%                    需要它把 Eb/N0 换算到 Es/N0 (Es = R*Eb).
%
%   输出:
%       rx_llr : 与 coded_bits 等长的软 LLR (= 2y/sigma^2),
%                与 polar_sc_decode / polar_scl_decode 的 LLR 约定一致:
%                LLR > 0 倾向判 0, LLR < 0 倾向判 1.
%       rx_y   : AWGN 后的实数样本 (BPSK + 噪声), 给软 Viterbi 用.
%
%   约定:
%       BPSK: bit 0 -> +1, bit 1 -> -1; 信号能量 Es = 1.
%       sigma^2 = N0/2 = 1 / (2 * R * 10^(EbN0_dB/10))

    if nargin < 3 || isempty(code_rate)
        code_rate = 1;
    end

    coded_bits = coded_bits(:).';
    bpsk       = 1 - 2 * coded_bits;        % 0/1 -> +1/-1

    EbN0_lin   = 10^(EbN0_dB / 10);
    sigma2     = 1 / (2 * code_rate * EbN0_lin);
    sigma      = sqrt(sigma2);

    noise      = sigma * randn(size(bpsk));
    rx_y       = bpsk + noise;
    rx_llr     = 2 * rx_y / sigma2;
end
