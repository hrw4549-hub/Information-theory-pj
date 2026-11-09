function results = run_source_demo()
%RUN_SOURCE_DEMO Show lossless Huffman coding and its bit-count reduction.
    project_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_root, 'src'));
    results_dir = fullfile(project_root, 'results');
    if ~exist(results_dir, 'dir'), mkdir(results_dir); end

    image = imread(fullfile(project_root, 'data', 'lena.png'));
    if ndims(image) == 3, image = rgb2gray(image); end
    image = imresize(image, [64 64]);
    [bits, dictionary, image_size] = source_encode(image);
    decoded = source_decode(bits, dictionary, image_size);
    results.original_bits = 8 * numel(image);
    results.huffman_bits = numel(bits);
    results.compression_ratio = results.huffman_bits / results.original_bits;
    results.lossless = isequal(image, decoded);

    fig = figure('Color', 'w', 'Position', [100 100 900 430]);
    tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    nexttile; imshow(image); title('Original 64×64 grayscale image');
    nexttile; imshow(decoded); title('Huffman decoded image');
    sgtitle(sprintf('Huffman: %d bits from %d (%.1f%%)', ...
        results.huffman_bits, results.original_bits, 100 * results.compression_ratio));
    exportgraphics(fig, fullfile(results_dir, 'source-codec-test.png'), 'Resolution', 160);
    close(fig);
    fprintf('Lossless roundtrip: %d | Huffman: %d / %d bits (%.1f%%)\n', ...
        results.lossless, results.huffman_bits, results.original_bits, ...
        100 * results.compression_ratio);
end
