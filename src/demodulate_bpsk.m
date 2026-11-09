function bits = demodulate_bpsk(rx_symbols)
% BPSK解调：硬判决，实部>0判1，否则判0
% 输入：rx_symbols - 接收符号向量 (1 x N)
% 输出：bits - 一维逻辑数组 (logical 0/1)

    bits = logical(real(rx_symbols) > 0);
end
