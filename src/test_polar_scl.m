function results = test_polar_scl(verbose)
%TEST_POLAR_SCL  极化码 SCL / SCL+CRC / AWGN 单元测试
%
%   results = TEST_POLAR_SCL()
%   results = TEST_POLAR_SCL(false)

    if nargin < 1, verbose = true; end
    rng(20260507);
    pass = 0; fail = 0; total = 0;

    % ----------------------------------------------------------------
    % 用例 1: SCL(L=1) 必须与 SC 完全一致 (退化等价性)
    % ----------------------------------------------------------------
    N = 64; K = 32;
    idx   = polar_construct(N, K);
    info  = randi([0 1], 1, K);
    coded = polar_encode(info, N, idx);
    rx_llr = hard2llr(coded, 0.07);
    d_sc  = polar_sc_decode(rx_llr, N, idx);
    d_l1  = polar_scl_decode(rx_llr, N, idx, 1);
    [pass, fail, total] = report('SCL(L=1) 等价于 SC', isequal(d_sc, d_l1), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 2: AWGN 信道, SCL(L=8) FER 应优于或等于 SC
    % ----------------------------------------------------------------
    EbN0_dB = 1.5;            % 较低 SNR 处差距明显
    R = K / N;
    n_frames = 80;
    n_err_sc  = 0;
    n_err_scl = 0;
    for f = 1:n_frames
        info  = randi([0 1], 1, K);
        coded = polar_encode(info, N, idx);
        rx_llr = awgn_llr(coded, EbN0_dB, R);
        d_sc  = polar_sc_decode(rx_llr, N, idx);
        d_scl = polar_scl_decode(rx_llr, N, idx, 8);
        if ~isequal(d_sc,  info), n_err_sc  = n_err_sc  + 1; end
        if ~isequal(d_scl, info), n_err_scl = n_err_scl + 1; end
    end
    fer_sc  = n_err_sc  / n_frames;
    fer_scl = n_err_scl / n_frames;
    if verbose
        fprintf('  AWGN Eb/N0=%.1f dB | SC FER=%.3f | SCL(8) FER=%.3f\n', ...
                EbN0_dB, fer_sc, fer_scl);
    end
    [pass, fail, total] = report('AWGN 下 SCL(8) FER <= SC FER', ...
                                 fer_scl <= fer_sc, ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 3: SCL + CRC 端到端正确性 (无错信道)
    % ----------------------------------------------------------------
    N2 = 64;
    K_total  = 32;          % info + crc8
    crc_poly = [1 0 0 0 0 0 1 1 1];
    crc_len  = numel(crc_poly) - 1;
    K_info   = K_total - crc_len;
    info     = randi([0 1], 1, K_info);
    [c, idx2, ~] = polar_encode_crc(info, N2, K_total, crc_poly);
    rx_llr   = hard2llr(c, 0.01);     % 几乎无错的强信道
    info_hat = polar_scl_decode(rx_llr, N2, idx2, 8, crc_poly);
    [pass, fail, total] = report('SCL+CRC 无错往返', ...
                                 isequal(info_hat, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 4: SCL+CRC 在 AWGN 上应优于 SCL (CRC 选路减少误检)
    % ----------------------------------------------------------------
    EbN0_dB = 1.5;
    R       = K_total / N2;
    n_frames = 80;
    n_err_scl   = 0;
    n_err_crc   = 0;
    for f = 1:n_frames
        info = randi([0 1], 1, K_info);
        [c, idx2, ~] = polar_encode_crc(info, N2, K_total, crc_poly);
        rx_llr = awgn_llr(c, EbN0_dB, R);

        % 不带 CRC 的 SCL: 取最小 PM, 但要把 info_idx 上的 K_total bit
        % 砍掉 CRC 来与 info 对齐
        d_scl_full = polar_scl_decode(rx_llr, N2, idx2, 8);
        d_scl      = d_scl_full(1:end - crc_len);

        d_crc = polar_scl_decode(rx_llr, N2, idx2, 8, crc_poly);

        if ~isequal(d_scl, info), n_err_scl = n_err_scl + 1; end
        if ~isequal(d_crc, info), n_err_crc = n_err_crc + 1; end
    end
    fer_scl = n_err_scl / n_frames;
    fer_crc = n_err_crc / n_frames;
    if verbose
        fprintf('  AWGN Eb/N0=%.1f dB | SCL(8) FER=%.3f | SCL(8)+CRC8 FER=%.3f\n', ...
                EbN0_dB, fer_scl, fer_crc);
    end
    [pass, fail, total] = report('SCL+CRC FER <= SCL FER', fer_crc <= fer_scl, ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 5: CRC 工具自身的编/校验互逆
    % ----------------------------------------------------------------
    rng(2);
    info     = randi([0 1], 1, 24);
    crc_bits = crc_compute(info, crc_poly);
    ok       = crc_check([info, crc_bits], crc_poly);
    [pass, fail, total] = report('CRC 编/校验互逆', ok, ...
                                 pass, fail, total, verbose);

    bad_ok   = crc_check([1 - info(1), info(2:end), crc_bits], crc_poly);
    [pass, fail, total] = report('CRC 检测翻转', ~bad_ok, ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    results.total = total;
    results.pass  = pass;
    results.fail  = fail;
    if verbose
        fprintf('\n[极化码 SCL+CRC] 总计 %d, 通过 %d, 失败 %d\n', ...
                total, pass, fail);
    end
end


function [pass, fail, total] = report(name, ok, pass, fail, total, verbose)
    total = total + 1;
    if ok
        pass = pass + 1;
        if verbose, fprintf('  [PASS] %s\n', name); end
    else
        fail = fail + 1;
        if verbose, fprintf('  [FAIL] %s\n', name); end
    end
end
