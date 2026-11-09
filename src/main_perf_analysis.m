%% 成员4：信息传输全链路性能分析与批量测试主脚本（学术规范版）
clear; clc; close all;

%% ==========================================
%% 1. 自动挂载各成员的平行宇宙（传送门）
%% ==========================================
addpath('../member1'); % 信源模块：source_encode, source_decode
addpath('../member2'); % 信道模块：conv_encode, viterbi_decode
addpath('../member3'); % 调制与信道：modulate_bpsk, awgn_channel, demodulate_bpsk

%% ==========================================
%% 2. 仿真参数设置与图像预处理
%% ==========================================
EbN0_range = 0:2:10;  % 完美对齐成员3和4的信噪比遍历范围 (dB)
LEN = length(EbN0_range);

% 读取测试图像
img_org = imread('lena.png');
if size(img_org, 3) == 3
    img_org = rgb2gray(img_org); % 确保转换为标准二维灰度矩阵
end
img_size = size(img_org);

% 预分配性能收集矩阵
[ber_trans_A, psnr_A] = deal(zeros(1, LEN)); % 方案A：全链路体制（有源有道联合设计）
[ber_trans_B, psnr_B] = deal(zeros(1, LEN)); % 方案B：未编码体制（仅作信源压缩，无信道纠错保护）
[ber_trans_C, psnr_C] = deal(zeros(1, LEN)); % 方案C：定长传输体制（无信源压缩，仅作信道纠错）

%% ==========================================
%% 3. 批量测试与多链路循环对比
%% ==========================================
for i = 1:LEN
    EbN0_dB = EbN0_range(i);
    fprintf('=== 正在运行全链路仿真：Eb/N0 = %d dB ===\n', EbN0_dB);
    
    %% --------------------------------------
    %% 方案 A：完整全链路体制（哈夫曼压缩 -> 卷积码 -> BPSK -> 软判决译码 -> 解压）
    %% --------------------------------------
    % 【成员1】信源编码（转换为行向量以适配信道编码接口）
    [bit_source_A_col, huff_dict_A, ~] = source_encode(img_org); 
    bit_source_A = double(bit_source_A_col(:)'); 
    
    % 【成员2】信道编码：引入卷积码进行纠错保护
    [bit_channel_A, T_A] = conv_encode(bit_source_A);
    
    % 【成员3】调制 -> 噪声信道 -> 解调
    tx_symbols_A = modulate_bpsk(bit_channel_A);
    rx_symbols_A = awgn_channel(tx_symbols_A, EbN0_dB);
    rx_bits_channel_A = demodulate_bpsk(rx_symbols_A);
    
    % 【接口转换】计算对数似然比(LLR)，为后级 Viterbi 软判决译码器提供输入
    R_conv = numel(bit_source_A) / numel(bit_channel_A);
    rx_llr_A = 4 * rx_symbols_A * (10^(EbN0_dB/10)) * R_conv; 
    
    % 【成员2】信道译码：执行最大似然软判决 Viterbi 纠错译码
    rx_bits_source_A = viterbi_decode(rx_llr_A, T_A, 'soft');
    
    % 【成员1】信源解码：重构图像矩阵
    try
        img_rec_A = source_decode(rx_bits_source_A(:), huff_dict_A, img_size);
    catch
        img_rec_A = zeros(img_size, 'uint8'); % 异常保护：低信噪比下变长码错位引发冲突时赋零
    end
    
    % 性能指标量化（成员4核心任务）
    ber_trans_A(i) = sum(bit_source_A ~= rx_bits_source_A) / length(bit_source_A);
    [~, psnr_A(i), ~] = evaluate_performance(img_org, img_rec_A);

    %% --------------------------------------
    %% 方案 B：对照组——未编码体制（信源压缩流直接置于 AWGN 信道传输）
    %% --------------------------------------
    [bit_source_B_col, huff_dict_B, ~] = source_encode(img_org);
    bit_source_B = double(bit_source_B_col(:)');
    
    % 绕过信道编码，直接进行物理层调制与传输
    tx_symbols_B = modulate_bpsk(bit_source_B);
    rx_symbols_B = awgn_channel(tx_symbols_B, EbN0_dB);
    rx_bits_source_B = demodulate_bpsk(rx_symbols_B);
    
    try
        img_rec_B = source_decode(rx_bits_source_B(:), huff_dict_B, img_size);
    catch
        img_rec_B = zeros(img_size, 'uint8');
    end
    
    ber_trans_B(i) = sum(bit_source_B ~= rx_bits_source_B) / length(bit_source_B);
    [~, psnr_B(i), ~] = evaluate_performance(img_org, img_rec_B);

    %% --------------------------------------
    %% 方案 C：对照组——定长传输体制（无信源编码，原始像素比特流 + 卷积码纠错）
    %% --------------------------------------
    % 绕过哈夫曼，直接按 8-bit 定长将原始图像展开（加入 double 转换防报错）
    bit_source_C = rem(floor(double(img_org(:)) * 2.^(-7:0)), 2).'; 
    bit_source_C = double(bit_source_C(:).');
    
    % 【成员2】信道编码
    [bit_channel_C, T_C] = conv_encode(bit_source_C);
    
    % 【成员3】调制 -> 噪声信道 -> 解调
    tx_symbols_C = modulate_bpsk(bit_channel_C);
    rx_symbols_C = awgn_channel(tx_symbols_C, EbN0_dB);
    
    % 软判决 LLR 映射
    R_conv_C = numel(bit_source_C) / numel(bit_channel_C);
    rx_llr_C = 4 * rx_symbols_C * (10^(EbN0_dB/10)) * R_conv_C;
    
    % 【成员2】信道译码
    rx_bits_source_C = viterbi_decode(rx_llr_C, T_C, 'soft');
    
    % 纯数学逻辑替代 bit2int 恢复图像
    rx_bits_mat = reshape(rx_bits_source_C(:), 8, []).';
    img_rec_bits = rx_bits_mat * (2.^(7:-1:0)).';
    img_rec_C = uint8(reshape(img_rec_bits, img_size));
    
    ber_trans_C(i) = sum(bit_source_C ~= rx_bits_source_C) / length(bit_source_C);
    [~, psnr_C(i), ~] = evaluate_performance(img_org, img_rec_C);
end

%% ==========================================
%% 4. 绘制性能对比曲线（PPT 答辩核心成果展示）
%% ==========================================
EbN0_fine = 0:0.1:10;
ber_theory = 0.5 * erfc(sqrt(10.^(EbN0_fine/10)));

% 图 1：SNR-BER 瀑布曲线
figure('Color', 'w', 'Position', [100, 100, 600, 450]);
semilogy(EbN0_fine, ber_theory, 'k-', 'LineWidth', 1.2); hold on;
semilogy(EbN0_range, ber_trans_A, 'r-o', 'LineWidth', 1.8, 'MarkerSize', 6);
semilogy(EbN0_range, ber_trans_B, 'b--x', 'LineWidth', 1.5, 'MarkerSize', 6);
semilogy(EbN0_range, ber_trans_C, 'g-.s', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('E_b/N_0 (dB)', 'FontSize', 11);
ylabel('信息序列译码后误码率 (BER)', 'FontSize', 11);
title('不同通信体制下的译码误码率 (BER) 性能对比', 'FontSize', 12);
legend('BPSK理论未编码基准', '方案A: 全链路体制(信源压缩+信道纠错)', '方案B: 未编码体制(信源压缩无保护)', '方案C: 定长传输体制(无信源压缩+有纠错)', 'Location', 'southwest');
ylim([1e-5 1]);

% 图 2：SNR-PSNR 质量演进曲线
figure('Color', 'w', 'Position', [720, 100, 600, 450]);
plot(EbN0_range, psnr_A, 'r-o', 'LineWidth', 1.8, 'MarkerSize', 6); hold on;
plot(EbN0_range, psnr_B, 'b--x', 'LineWidth', 1.5, 'MarkerSize', 6);
plot(EbN0_range, psnr_C, 'g-.s', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('E_b/N_0 (dB)', 'FontSize', 11);
ylabel('重建图像峰值信噪比 PSNR (dB)', 'FontSize', 11);
title('不同通信体制下的图像重建质量 (PSNR) 演进趋势', 'FontSize', 12);
legend('方案A: 全链路体制(信源压缩+信道纠错)', '方案B: 未编码体制(信源压缩无保护)', '方案C: 定长传输体制(无信源压缩+有纠错)', 'Location', 'southeast');