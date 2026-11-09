function results = run_image_demo()
%RUN_IMAGE_DEMO Compare source compression and channel protection end to end.
    project_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_root, 'src'));
    results_dir = fullfile(project_root, 'results');
    if ~exist(results_dir, 'dir'), mkdir(results_dir); end

    rng(20261109);
    source_image = imread(fullfile(project_root, 'data', 'lena.png'));
    if ndims(source_image) == 3, source_image = rgb2gray(source_image); end
    source_image = imresize(source_image, [64 64]);
    [huffman_bits, dictionary, image_size] = source_encode(source_image);
    raw_bits = reshape(rem(floor(double(source_image(:)) * 2.^(-7:0)), 2).', [], 1).';

    ebn0_values = 0:2:8;
    names = {'Raw pixels, uncoded', 'Huffman, uncoded', 'Huffman + convolutional code'};
    psnr_values = nan(3, numel(ebn0_values));
    ber_values = nan(3, numel(ebn0_values));
    images = cell(3, numel(ebn0_values));
    compression_ratio = numel(huffman_bits) / (8 * numel(source_image));

    for s = 1:numel(ebn0_values)
        ebn0 = ebn0_values(s);
        rng(20261109 + s);

        rx_raw = awgn_llr(raw_bits, ebn0, 1);
        raw_hat = double(rx_raw < 0);
        raw_pixels = reshape(raw_hat, 8, []).' * (2.^(7:-1:0)).';
        img_raw = uint8(reshape(raw_pixels, image_size));
        [~, psnr_values(1,s), ber_values(1,s)] = evaluate_performance(source_image, img_raw);
        images{1,s} = img_raw;

        rx_huffman = awgn_llr(huffman_bits, ebn0, 1);
        huffman_hat = double(rx_huffman < 0);
        [img_huffman, ber_values(2,s)] = decode_image(huffman_hat, dictionary, image_size, source_image);
        [~, psnr_values(2,s)] = evaluate_performance(source_image, img_huffman);
        images{2,s} = img_huffman;

        [coded_bits, trellis] = conv_encode(huffman_bits);
        rate = numel(huffman_bits) / numel(coded_bits);
        rx_coded = awgn_llr(coded_bits, ebn0, rate);
        huffman_hat_coded = viterbi_decode(rx_coded, trellis, 'soft');
        [img_coded, ber_values(3,s)] = decode_image(huffman_hat_coded, dictionary, image_size, source_image);
        [~, psnr_values(3,s)] = evaluate_performance(source_image, img_coded);
        images{3,s} = img_coded;
    end

    results.ebn0_dB = ebn0_values;
    results.psnr_dB = psnr_values;
    results.pixel_ber = ber_values;
    results.compression_ratio = compression_ratio;
    results.huffman_bits = numel(huffman_bits);
    results.raw_bits = numel(raw_bits);
    save(fullfile(results_dir, 'image-channel-results.mat'), 'results', 'source_image', 'images');
    writematrix([ebn0_values(:), psnr_values.', ber_values.'], ...
        fullfile(results_dir, 'image-channel-results.csv'), ...
        'WriteMode', 'overwrite');

    fig = figure('Color', 'w', 'Position', [80 80 1200 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    representative = find(ebn0_values == 8, 1);
    nexttile; imshow(source_image); title('原始图像（64×64）');
    nexttile; imshow(images{1,representative}); title('原始像素直接传输，8 dB');
    nexttile; imshow(images{2,representative}); title('Huffman 直接传输，8 dB');
    nexttile; imshow(images{3,representative}); title('Huffman + 卷积码，8 dB');
    nexttile;
    plot(ebn0_values, min(psnr_values, 60), '-o', 'LineWidth', 1.5);
    grid on; xlabel('Eb/N0 (dB)'); ylabel('PSNR (dB)'); ylim([0 60]);
    legend(names, 'Location', 'southeast'); title('图像重建质量（完整还原显示为 60 dB）');
    nexttile;
    plot(ebn0_values, max(ber_values, 1e-6), '-o', 'LineWidth', 1.5);
    set(gca, 'YScale', 'log'); grid on;
    xlabel('Eb/N0 (dB)'); ylabel('Image bit BER');
    legend(names, 'Location', 'southwest'); title('像素误码率');
    sgtitle(sprintf('Eb/N0 sweep | Huffman uses %.1f%% of raw image bits | seed 20261109', ...
        100 * compression_ratio));
    exportgraphics(fig, fullfile(results_dir, 'image-channel-comparison.png'), 'Resolution', 160);
    close(fig);

    fprintf('Huffman stream: %d bits / %d raw bits (%.1f%%)\n', ...
        numel(huffman_bits), numel(raw_bits), 100 * compression_ratio);
    fprintf('Saved image comparison, CSV metrics, and MAT data in results/.\n');
end

function [img, pixel_ber] = decode_image(bits, dict, image_size, reference)
    try
        img = source_decode(bits, dict, image_size);
    catch
        img = zeros(image_size, 'uint8');
    end
    [~, ~, pixel_ber] = evaluate_performance(reference, img);
end
