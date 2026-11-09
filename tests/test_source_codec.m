function results = test_source_codec(verbose)
%TEST_SOURCE_CODEC Verify lossless Huffman roundtrip and stream validation.
    if nargin < 1, verbose = true; end
    rng(20261109);
    img = uint8(randi([0 255], 32, 32));
    [bits, dict, image_size] = source_encode(img);
    reconstructed = source_decode(bits, dict, image_size);

    results.total = 3;
    results.pass = 0;
    results.pass = results.pass + report('lossless image roundtrip', isequal(img, reconstructed), verbose);
    results.pass = results.pass + report('compressed stream is binary', all(bits(:) == 0 | bits(:) == 1), verbose);
    rejected_truncation = false;
    try
        source_decode(bits(1:end-1), dict, image_size);
    catch
        rejected_truncation = true;
    end
    results.pass = results.pass + report('truncated stream is rejected', rejected_truncation, verbose);
    results.fail = results.total - results.pass;
end

function passed = report(name, ok, verbose)
    passed = double(ok);
    if verbose
        if ok, state = 'PASS'; else, state = 'FAIL'; end
        fprintf('  [%s] %s\n', state, name);
    end
end
