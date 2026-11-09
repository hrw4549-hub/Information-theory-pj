function ok = crc_check(bits_with_crc, crc_poly)
%CRC_CHECK  校验 [info, crc] 比特序列是否符合 CRC
%
%   ok = CRC_CHECK(bits_with_crc, crc_poly)
%
%   输入:
%       bits_with_crc : 1×(K_info + L) 行向量, 末 L 位是 CRC
%       crc_poly      : 与 crc_compute 相同的生成多项式
%
%   输出:
%       ok : 逻辑值, true 表示 CRC 通过

    bits_with_crc = bits_with_crc(:).';
    crc_poly      = crc_poly(:).';
    L             = numel(crc_poly) - 1;
    if numel(bits_with_crc) <= L
        ok = false;
        return;
    end
    info     = bits_with_crc(1:end - L);
    crc_rx   = bits_with_crc(end - L + 1:end);
    crc_calc = crc_compute(info, crc_poly);
    ok       = isequal(crc_calc, crc_rx);
end
