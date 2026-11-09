function img_reconstructed = source_decode(bit_stream, huff_dict, img_size)
%SOURCE_DECODE Decode a Huffman bitstream into its original uint8 image.
% The decoder validates the complete stream so corrupted or truncated input
% cannot silently appear to be a valid reconstruction.

    bits = double(bit_stream(:).');
    if any(bits ~= 0 & bits ~= 1)
        error('source_decode:badBits', 'The bitstream must contain only 0 and 1.');
    end
    if ~isstruct(huff_dict) || ~isfield(huff_dict, 'symbols') || ~isfield(huff_dict, 'codes')
        error('source_decode:badDictionary', 'Expected a dictionary from source_encode.');
    end

    symbols = huff_dict.symbols(:);
    codes = huff_dict.codes(:);
    if numel(symbols) ~= numel(codes) || isempty(symbols)
        error('source_decode:badDictionary', 'The Huffman dictionary is empty or inconsistent.');
    end

    % Build a binary prefix tree once, then decode in linear time.
    max_nodes = 1 + sum(cellfun(@numel, codes));
    children = zeros(max_nodes, 2);
    leaf_symbol = zeros(max_nodes, 1);
    node_count = 1;
    for s = 1:numel(codes)
        code = codes{s}(:).';
        node = 1;
        for b = code
            branch = double(b) + 1;
            if children(node, branch) == 0
                node_count = node_count + 1;
                children(node, branch) = node_count;
            end
            node = children(node, branch);
        end
        leaf_symbol(node) = s;
    end

    expected_count = prod(img_size);
    decoded = zeros(expected_count, 1);
    out_idx = 1;
    node = 1;
    for k = 1:numel(bits)
        node = children(node, bits(k) + 1);
        if node == 0
            error('source_decode:invalidCodeword', 'The bitstream contains an invalid Huffman prefix.');
        end
        symbol_idx = leaf_symbol(node);
        if symbol_idx ~= 0
            if out_idx > expected_count
                error('source_decode:tooManySymbols', 'The bitstream decodes to more symbols than the image contains.');
            end
            decoded(out_idx) = symbols(symbol_idx);
            out_idx = out_idx + 1;
            node = 1;
        end
    end

    if node ~= 1 || out_idx ~= expected_count + 1
        error('source_decode:incompleteStream', ...
            'The bitstream decoded %d of %d expected pixels.', out_idx - 1, expected_count);
    end
    img_reconstructed = reshape(uint8(decoded), img_size);
end
