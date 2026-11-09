function results = test_polar_code(verbose)
%TEST_POLAR_CODE  极化码 + SC 译码单元测试 (AWGN 信道)
%
%   results = TEST_POLAR_CODE()
%   results = TEST_POLAR_CODE(false)

    if nargin < 1, verbose = true; end
    rng(20260507);
    pass = 0; fail = 0; total = 0;

    N = 16;             % 码长
    K = 8;              % 信息位
    R = K / N;          % 码率
    design_snr_dB = 2.5;% GA 构造点

    info_idx = polar_construct(N, K, design_snr_dB);
    if verbose
        fprintf('  使用 N=%d, K=%d, info_idx=[%s]\n', N, K, ...
                num2str(info_idx));
    end

    % ----------------------------------------------------------------
    % 用例 1: 高 SNR 无差错往返
    % ----------------------------------------------------------------
    EbN0_clean = 8;     % dB
    info  = randi([0 1], 1, K);
    coded = polar_encode(info, N, info_idx);
    llr   = awgn_llr(coded, EbN0_clean, R);
    dec   = polar_sc_decode(llr, N, info_idx);
    [pass, fail, total] = report('高 SNR 无差错往返', isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 2: 中 SNR (5 dB) 仍能纠正噪声
    % ----------------------------------------------------------------
    EbN0_mid = 5;       % dB
    info  = randi([0 1], 1, K);
    coded = polar_encode(info, N, info_idx);
    llr   = awgn_llr(coded, EbN0_mid, R);
    dec   = polar_sc_decode(llr, N, info_idx);
    [pass, fail, total] = report('中 SNR (5 dB) 仍能译出', ...
                                 isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 3: 信息位与冻结位错位的负面测试
    %         译码端故意用错误的 info_idx, 译出应不等于原信息
    % ----------------------------------------------------------------
    info       = randi([0 1], 1, K);
    coded      = polar_encode(info, N, info_idx);
    llr        = awgn_llr(coded, EbN0_clean, R);
    bad_idx    = circshift(info_idx, 1);    % 错位
    dec_bad    = polar_sc_decode(llr, N, bad_idx);
    [pass, fail, total] = report('错误索引应解错', ~isequal(dec_bad, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 4: 统计实验, AWGN Eb/N0=3 dB, 200 帧, 期望帧错率较低
    % ----------------------------------------------------------------
    EbN0_test = 3;      % dB
    n_frames  = 200;
    n_err_frames = 0;
    for f = 1:n_frames
        info  = randi([0 1], 1, K);
        coded = polar_encode(info, N, info_idx);
        llr   = awgn_llr(coded, EbN0_test, R);
        dec   = polar_sc_decode(llr, N, info_idx);
        if ~isequal(dec, info), n_err_frames = n_err_frames + 1; end
    end
    fer = n_err_frames / n_frames;
    if verbose
        fprintf('  AWGN Eb/N0=%.1f dB 下 200 帧的帧错率 FER=%.3f\n', ...
                EbN0_test, fer);
    end
    % 该工作点未编码时单比特 BER ≈ Q(sqrt(2*R*EbN0_lin)) ≈ 0.08,
    % 8 个独立信息位的 FER 上界 ≈ 1-(1-0.08)^8 ≈ 0.49;
    % 编码后应明显改善
    [pass, fail, total] = report('编码后 FER 优于未编码 (<0.30)', fer < 0.30, ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 5: N=8, K=4 小规模, 全 0 信息穿越高 SNR 信道
    % ----------------------------------------------------------------
    N2 = 8; K2 = 4; R2 = K2 / N2;
    idx2  = polar_construct(N2, K2);
    info  = zeros(1, K2);
    coded = polar_encode(info, N2, idx2);
    llr   = awgn_llr(coded, EbN0_clean, R2);
    dec   = polar_sc_decode(llr, N2, idx2);
    [pass, fail, total] = report('小规模全零穿越', isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    results.total = total;
    results.pass  = pass;
    results.fail  = fail;
    if verbose
        fprintf('\n[极化码] 总计 %d, 通过 %d, 失败 %d\n', total, pass, fail);
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
