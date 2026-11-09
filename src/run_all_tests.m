function results = run_all_tests()
%RUN_ALL_TESTS  执行所有信道编解码单元测试
%
%   用法 (在 MATLAB 命令窗口):
%       >> run_all_tests
%
%   会依次运行卷积码与极化码的测试脚本, 并打印汇总结果。

    fprintf('================================================\n');
    fprintf(' 信道编解码 MATLAB 仿真 - 单元测试\n');
    fprintf('================================================\n\n');

    fprintf('--- 卷积码 (rate 1/2, K=3, Viterbi) ---\n');
    r1 = test_conv_code(true);

    fprintf('\n--- 极化码 (N=16, K=8, SC) ---\n');
    r2 = test_polar_code(true);

    fprintf('\n--- 极化码 SCL/CRC (N=64) ---\n');
    r3 = test_polar_scl(true);

    fprintf('\n================================================\n');
    total_pass = r1.pass + r2.pass + r3.pass;
    total_fail = r1.fail + r2.fail + r3.fail;
    total_all  = r1.total + r2.total + r3.total;
    fprintf(' 总汇总: %d 通过 / %d 失败 (共 %d)\n', ...
            total_pass, total_fail, total_all);
    fprintf('================================================\n');
    results.total = total_all;
    results.pass = total_pass;
    results.fail = total_fail;
end
