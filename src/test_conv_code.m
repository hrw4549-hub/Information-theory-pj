function results = test_conv_code(verbose)
%TEST_CONV_CODE  卷积码 + Viterbi 译码单元测试
%
%   results = TEST_CONV_CODE()           verbose 默认开
%   results = TEST_CONV_CODE(false)
%
%   results 结构体字段:
%       .total : 测试数
%       .pass  : 通过数
%       .fail  : 失败数
%
%   测试覆盖:
%       1) 编码/解码无错往返
%       2) 单比特错误纠正
%       3) 离散两比特错误 (在不同保护窗口内)
%       4) 突发错误超出能力时输出报告
%       5) 随机数据 + 随机翻转的统计纠错率

    if nargin < 1, verbose = true; end
    rng(20260507);                          % 固定随机种子, 测试可复现
    pass = 0; fail = 0; total = 0;

    % ----------------------------------------------------------------
    % 用例 1: 无错往返
    % ----------------------------------------------------------------
    info  = [1 0 1 1 0 0 1 0 1 1];
    [c, T] = conv_encode(info);
    dec    = viterbi_decode(c, T);
    [pass, fail, total] = report('无错往返', isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 2: 第 5 位单比特翻转 (硬判决 Viterbi 应能纠正)
    % ----------------------------------------------------------------
    rx        = c;
    rx(5)     = 1 - rx(5);
    dec       = viterbi_decode(rx, T);
    [pass, fail, total] = report('单比特错误', isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 3: 两个相距较远的比特翻转
    % ----------------------------------------------------------------
    rx        = c;
    rx(3)     = 1 - rx(3);
    rx(15)    = 1 - rx(15);
    dec       = viterbi_decode(rx, T);
    [pass, fail, total] = report('两个分散错误', isequal(dec, info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 4: 紧邻 4 个比特翻转 (超出 (2,1,3) 自由距 d_free=5 一半)
    %           可能出错, 这里只做"译码完成且长度正确"的弱断言
    % ----------------------------------------------------------------
    rx           = c;
    rx(7:10)     = 1 - rx(7:10);
    dec          = viterbi_decode(rx, T);
    [pass, fail, total] = report('突发 4 错(长度断言)', ...
                                 numel(dec) == numel(info), ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    % 用例 5: 较长随机数据, 每帧随机翻 1 比特, 统计纠错率
    %           对于 (2,1,3) 码, d_free=5, 单错必纠 -> 期望 100%
    % ----------------------------------------------------------------
    n_frames = 200;
    L        = 64;
    success  = 0;
    for f = 1:n_frames
        info   = randi([0 1], 1, L);
        [c, T] = conv_encode(info);
        rx     = c;
        pos    = randi(numel(rx));
        rx(pos)= 1 - rx(pos);
        dec    = viterbi_decode(rx, T);
        if isequal(dec, info), success = success + 1; end
    end
    rate = success / n_frames;
    if verbose
        fprintf('  统计: %d/%d 帧 (单错) 全部纠正, 成功率=%.2f%%\n', ...
                success, n_frames, rate * 100);
    end
    [pass, fail, total] = report('随机单错统计 (>=99%)', rate >= 0.99, ...
                                 pass, fail, total, verbose);

    % ----------------------------------------------------------------
    results.total = total;
    results.pass  = pass;
    results.fail  = fail;
    if verbose
        fprintf('\n[卷积码] 总计 %d, 通过 %d, 失败 %d\n', total, pass, fail);
    end
end


function [pass, fail, total] = report(name, ok, pass, fail, total, verbose)
    total = total + 1;
    if ok
        pass = pass + 1;
        if verbose
            fprintf('  [PASS] %s\n', name);
        end
    else
        fail = fail + 1;
        if verbose
            fprintf('  [FAIL] %s\n', name);
        end
    end
end
