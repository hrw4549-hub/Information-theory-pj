function rx_symbols = awgn_channel(tx_symbols, EbN0_dB)
% AWGN信道：根据Eb/N0(dB)向发送信号添加高斯白噪声
% 输入：tx_symbols - 发送符号向量 (1 x N)
%        EbN0_dB   - 每比特信噪比 (dB)，标量
% 输出：rx_symbols - 接收符号向量 (1 x N)

    EbN0 = 10^(EbN0_dB / 10);  % dB转线性值
    noise_std = sqrt(1 / (2 * EbN0));  % BPSK: N0/2 = 1/(2*EbN0)

    noise = noise_std * randn(size(tx_symbols));
    rx_symbols = tx_symbols + noise;
end
