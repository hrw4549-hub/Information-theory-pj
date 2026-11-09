function crc = crc_compute(info_bits, crc_poly)
%CRC_COMPUTE  二进制 CRC 校验位计算 (LFSR 多项式除法)
%
%   crc = CRC_COMPUTE(info_bits, crc_poly)
%
%   输入:
%       info_bits : 0/1 信息比特行向量
%       crc_poly  : 1×(L+1) 行向量, 生成多项式系数, 高次项在前;
%                   例如 CRC-8 (x^8 + x^2 + x + 1) -> [1 0 0 0 0 0 1 1 1]
%                   crc_poly 首位必须为 1.
%
%   输出:
%       crc       : 1×L 行向量, CRC 校验位 (高次项在前)
%
%   说明:
%       本函数采用最直观的"信息位+L 个 0 -> 多项式除法"实现, 适合教学,
%       不追求硬件级速度。

    info_bits = info_bits(:).';
    crc_poly  = crc_poly(:).';
    if crc_poly(1) ~= 1
        error('crc_compute:poly', '生成多项式首位必须为 1');
    end
    L = numel(crc_poly) - 1;
    if L < 1
        error('crc_compute:poly', '生成多项式长度过短');
    end

    msg = [info_bits, zeros(1, L)];
    Nm  = numel(info_bits);
    for i = 1:Nm
        if msg(i) == 1
            msg(i:i + L) = mod(msg(i:i + L) + crc_poly, 2);
        end
    end
    crc = msg(end - L + 1:end);
end
