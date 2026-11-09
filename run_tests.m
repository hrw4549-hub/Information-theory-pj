function run_tests()
%RUN_TESTS Run source-code and channel-code checks from the project root.
    project_root = fileparts(mfilename('fullpath'));
    addpath(fullfile(project_root, 'src'));
    addpath(fullfile(project_root, 'tests'));

    fprintf('=== Huffman source codec ===\n');
    source = test_source_codec(true);
    fprintf('\n=== Convolutional and polar codes ===\n');
    codes = run_all_tests();
    channel = test_channel();

    failed = source.fail + codes.fail + channel.fail;
    fprintf('\n=== Verification summary ===\n');
    fprintf('Source codec: %d/%d passed\n', source.pass, source.total);
    fprintf('Channel coding: %d/%d passed\n', codes.pass, codes.total);
    fprintf('AWGN channel: %d/%d passed\n', channel.pass, channel.total);
    if failed > 0
        error('run_tests:failed', '%d checks failed.', failed);
    end
    fprintf('All project checks passed.\n');
end
