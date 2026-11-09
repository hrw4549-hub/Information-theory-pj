function [coded_bits, info_idx, crc_poly] = polar_encode_crc(info_bits, N, K_total, crc_poly)
%POLAR_ENCODE_CRC  极化码 + CRC 包装编码
%
%   [coded_bits, info_idx, crc_poly] = POLAR_ENCODE_CRC(info_bits, N, K_total)
%   [coded_bits, info_idx, crc_poly] = POLAR_ENCODE_CRC(info_bits, N, K_total, crc_poly)
%
%   编码流程:
%       info_bits (K_info)  --CRC-->  [info_bits, crc] (K_total)
%                                       --放入 N 极化码--> coded_bits (N)
%
%   输入:
%       info_bits : 1×K_info 信息比特
%       N         : 极化码长 (2 的幂), >= K_total
%       K_total   : 信息位 + CRC 位的总长度. 等于 numel(info_bits) + (numel(crc_poly)-1).
%       crc_poly  : (可选) 生成多项式, 默认 CRC-8 (x^8+x^2+x+1)
%                   = [1 0 0 0 0 0 1 1 1]
%
%   输出:
%       coded_bits : 1×N 编码后比特流
%       info_idx   : 1×K_total 极化码信息位索引 (供 SCL 译码端使用)
%       crc_poly   : 实际使用的 CRC 多项式

    if nargin < 4 || isempty(crc_poly)
        crc_poly = [1 0 0 0 0 0 1 1 1];     % CRC-8
    end

    info_bits = info_bits(:).';
    crc_len   = numel(crc_poly) - 1;
    K_info    = numel(info_bits);

    if K_info + crc_len ~= K_total
        error('polar_encode_crc:K', ...
              'K_info(%d) + CRC(%d) 应等于 K_total(%d)', ...
              K_info, crc_len, K_total);
    end

    crc       = crc_compute(info_bits, crc_poly);
    payload   = [info_bits, crc];                  % 1×K_total

    info_idx  = polar_construct(N, K_total);
    coded_bits = polar_encode(payload, N, info_idx);
end
