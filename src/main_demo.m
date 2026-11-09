function main_demo()
%MAIN_DEMO  信道编解码 MATLAB 仿真主演示 (AWGN + 大 N + SCL/CRC)
%
%   一站式展示:
%       1) 卷积码 (2,1,3) + Viterbi 软判决译码: 单帧打印
%       2) 极化码 (N=256) + SC 译码: 单帧打印
%       3) 极化码 (N=256) + SCL(L=8) + CRC-8 译码: 单帧打印
%       4) AWGN 信道下 5 种方案的 BER/FER 曲线 (Eb/N0 扫描)
%
%   运行: 在项目目录下 >> main_demo

    rng(20260507);
    fprintf('================================================\n');
    fprintf(' 信道编解码 MATLAB 仿真 - 主演示 (AWGN + SCL/CRC)\n');
    fprintf('================================================\n\n');

    %% ---------- 1) 卷积码 demo (软判决 Viterbi) ----------
    fprintf('--- 卷积码 (rate=1/2, K=3, g1=7, g2=5) + 软 Viterbi ---\n');
    info        = randi([0 1], 1, 16);
    [coded, T]  = conv_encode(info);
    R_conv      = numel(info) / numel(coded);
    [~, rx_y]   = awgn_llr(coded, 3, R_conv);
    dec         = viterbi_decode(rx_y, T, 'soft');
    fprintf('  原始信息 (%2d bit): %s\n', numel(info), num2str(info));
    fprintf('  AWGN 译码:        %s\n', num2str(dec));
    fprintf('  纠错%s\n\n', tern(isequal(dec, info), '成功', '失败'));

    %% ---------- 2) 极化码 SC demo (N=256) ----------
    fprintf('--- 极化码 (N=256, K=128) + SC ---\n');
    N   = 256;  K = 128;
    idx = polar_construct(N, K);
    info  = randi([0 1], 1, K);
    coded = polar_encode(info, N, idx);
    R     = K / N;
    rx_llr = awgn_llr(coded, 2, R);
    dec    = polar_sc_decode(rx_llr, N, idx);
    fprintf('  K=%d info bits, AWGN Eb/N0=2 dB\n', K);
    fprintf('  SC 译码错位数: %d/%d\n', sum(dec ~= info), K);

    %% ---------- 3) 极化码 SCL+CRC demo (N=256) ----------
    fprintf('\n--- 极化码 (N=256, K_total=128, CRC-8) + SCL(L=8)+CRC ---\n');
    crc_poly = [1 0 0 0 0 0 1 1 1];           % CRC-8: x^8+x^2+x+1
    crc_len  = numel(crc_poly) - 1;
    K_total  = 128;
    K_info   = K_total - crc_len;             % = 120
    info     = randi([0 1], 1, K_info);
    [c, idx2, ~] = polar_encode_crc(info, N, K_total, crc_poly);
    R_crc    = K_total / N;
    rx_llr   = awgn_llr(c, 2, R_crc);
    info_hat = polar_scl_decode(rx_llr, N, idx2, 8, crc_poly);
    fprintf('  K_info=%d, AWGN Eb/N0=2 dB, L=8\n', K_info);
    fprintf('  SCL+CRC 译码错位数: %d/%d\n\n', sum(info_hat ~= info), K_info);

    %% ---------- 4) AWGN BER/FER 曲线 ----------
    fprintf('--- AWGN 信道下 BER/FER 扫描 (会出图) ---\n');
    EbN0_list = 0:0.5:4;
    n_frames  = 50;        % 每个 SNR 的测试帧数

    % 卷积码参数
    L_info_conv = 128;
    R_conv      = L_info_conv / (2 * (L_info_conv + 2));

    % 极化码参数
    Np = 256; Kp = 128;
    idx_p   = polar_construct(Np, Kp);
    R_p     = Kp / Np;

    % 极化 + CRC 参数
    Kt   = 128;             % info+crc total
    Kinf = Kt - crc_len;
    idx_pc = polar_construct(Np, Kt);
    R_pc   = Kt / Np;

    nS = numel(EbN0_list);
    [ber_unc, ber_conv, ber_sc, ber_scl, ber_crc] = deal(zeros(1, nS));
    [fer_conv, fer_sc, fer_scl, fer_crc]          = deal(zeros(1, nS));

    for ii = 1:nS
        EbN0 = EbN0_list(ii);
        cnt_unc  = 0; err_unc  = 0;
        cnt_conv = 0; err_conv = 0; nf_conv = 0;
        cnt_sc   = 0; err_sc   = 0; nf_sc   = 0;
        cnt_scl  = 0; err_scl  = 0; nf_scl  = 0;
        cnt_crc  = 0; err_crc  = 0; nf_crc  = 0;

        for f = 1:n_frames
            % --- 未编码 BPSK ---
            info_u  = randi([0 1], 1, L_info_conv);
            [~, ry] = awgn_llr(info_u, EbN0, 1);
            dec_u   = double(ry < 0);
            err_unc = err_unc + sum(dec_u ~= info_u);
            cnt_unc = cnt_unc + L_info_conv;

            % --- 卷积码 (软 Viterbi) ---
            info_c     = randi([0 1], 1, L_info_conv);
            [c_c, T]   = conv_encode(info_c);
            [~, rx_y]  = awgn_llr(c_c, EbN0, R_conv);
            dec_c      = viterbi_decode(rx_y, T, 'soft');
            e          = sum(dec_c ~= info_c);
            err_conv   = err_conv + e;
            cnt_conv   = cnt_conv + L_info_conv;
            if e > 0, nf_conv = nf_conv + 1; end

            % --- 极化 SC ---
            info_p   = randi([0 1], 1, Kp);
            cw       = polar_encode(info_p, Np, idx_p);
            rx_llr   = awgn_llr(cw, EbN0, R_p);
            dec_p    = polar_sc_decode(rx_llr, Np, idx_p);
            e        = sum(dec_p ~= info_p);
            err_sc   = err_sc + e; cnt_sc = cnt_sc + Kp;
            if e > 0, nf_sc = nf_sc + 1; end

            % --- 极化 SCL(L=8) ---
            dec_l    = polar_scl_decode(rx_llr, Np, idx_p, 8);   % 复用同一接收
            e        = sum(dec_l ~= info_p);
            err_scl  = err_scl + e; cnt_scl = cnt_scl + Kp;
            if e > 0, nf_scl = nf_scl + 1; end

            % --- 极化 SCL(L=8)+CRC8 ---
            info_pc  = randi([0 1], 1, Kinf);
            cw       = polar_encode_crc(info_pc, Np, Kt, crc_poly);
            rx_llr2  = awgn_llr(cw, EbN0, R_pc);
            dec_pc   = polar_scl_decode(rx_llr2, Np, idx_pc, 8, crc_poly);
            e        = sum(dec_pc ~= info_pc);
            err_crc  = err_crc + e; cnt_crc = cnt_crc + Kinf;
            if e > 0, nf_crc = nf_crc + 1; end
        end

        ber_unc(ii)  = err_unc  / cnt_unc;
        ber_conv(ii) = err_conv / cnt_conv;
        ber_sc(ii)   = err_sc   / cnt_sc;
        ber_scl(ii)  = err_scl  / cnt_scl;
        ber_crc(ii)  = err_crc  / cnt_crc;
        fer_conv(ii) = nf_conv  / n_frames;
        fer_sc(ii)   = nf_sc    / n_frames;
        fer_scl(ii)  = nf_scl   / n_frames;
        fer_crc(ii)  = nf_crc   / n_frames;

        fprintf('  Eb/N0=%.1f dB | unc BER=%.4f | conv %.4f | SC %.4f | SCL %.4f | SCL+CRC %.4f\n', ...
                EbN0, ber_unc(ii), ber_conv(ii), ber_sc(ii), ber_scl(ii), ber_crc(ii));
    end

    floor_val = 1e-5;
    plot_y = @(v) max(v, floor_val);

    figure('Name', 'BER over AWGN', 'Color', 'w');
    semilogy(EbN0_list, plot_y(ber_unc),  'k--o', 'LineWidth', 1.4); hold on;
    semilogy(EbN0_list, plot_y(ber_conv), 'b-s',  'LineWidth', 1.4);
    semilogy(EbN0_list, plot_y(ber_sc),   'r-^',  'LineWidth', 1.4);
    semilogy(EbN0_list, plot_y(ber_scl),  'm-d',  'LineWidth', 1.4);
    semilogy(EbN0_list, plot_y(ber_crc),  'g-v',  'LineWidth', 1.4);
    grid on;
    xlabel('Eb/N0 (dB)');
    ylabel('BER');
    legend('未编码 BPSK', ...
           '卷积码 (2,1,3)+软 Viterbi', ...
           '极化码 (256,128)+SC', ...
           '极化码 (256,128)+SCL(L=8)', ...
           '极化码 (256,128)+SCL(8)+CRC8', ...
           'Location', 'southwest');
    title('AWGN 信道下五种方案的 BER 比较');
    saveas(gcf, 'ber_curve.png');

    figure('Name', 'FER over AWGN', 'Color', 'w');
    semilogy(EbN0_list, plot_y(fer_conv), 'b-s',  'LineWidth', 1.4); hold on;
    semilogy(EbN0_list, plot_y(fer_sc),   'r-^',  'LineWidth', 1.4);
    semilogy(EbN0_list, plot_y(fer_scl),  'm-d',  'LineWidth', 1.4);
    semilogy(EbN0_list, plot_y(fer_crc),  'g-v',  'LineWidth', 1.4);
    grid on;
    xlabel('Eb/N0 (dB)');
    ylabel('FER');
    legend('卷积码', '极化码 SC', '极化码 SCL(8)', '极化码 SCL(8)+CRC8', ...
           'Location', 'southwest');
    title('AWGN 信道下四种编码的 FER 比较');
    saveas(gcf, 'fer_curve.png');

    fprintf('\n  曲线已保存到 ber_curve.png 与 fer_curve.png\n');
end


function s = tern(cond, a, b)
    if cond, s = a; else, s = b; end
end
