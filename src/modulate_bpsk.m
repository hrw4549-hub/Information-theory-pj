function symbols = modulate_bpsk(bits)
% BPSK调制：0 -> -1, 1 -> +1
% 输入：bits - 一维逻辑数组 (logical 0/1)
% 输出：symbols - 双精度复数向量 (1 x N)

    bits = double(bits(:)).';  % 转为行向量
    symbols = 2 * bits - 1;   % 0->-1, 1->+1
end
