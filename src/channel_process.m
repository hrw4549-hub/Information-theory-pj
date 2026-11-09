function rx_bits = channel_process(encoded_bits, EbN0_dB)
% 信道模块封装函数：调制 -> AWGN信道 -> 解调
% 符合团队接口契约
% 输入：encoded_bits - 一维逻辑数组 (logical 0/1)，来自成员2
%        EbN0_dB     - 每比特信噪比 (dB)，标量
% 输出：rx_bits      - 一维逻辑数组 (logical 0/1)，传给成员2译码

    tx_symbols = modulate_bpsk(encoded_bits);
    rx_symbols = awgn_channel(tx_symbols, EbN0_dB);
    rx_bits    = demodulate_bpsk(rx_symbols);
end
