# 项目原理与实验指南

## 1. 研究问题

一幅图像经过压缩和有噪传输后，哪些处理能降低传输开销，哪些处理能提高接收质量？本项目用一条可观察的数字通信链路回答这个问题：

```text
灰度图像 → Huffman 信源编码 → 信道编码 → BPSK → AWGN
         → 软信息译码 → Huffman 解码 → 重建图像
```

每个箭头对应独立 MATLAB 函数，便于单独验证和替换。

## 2. 信源编码：Huffman 码

图像像素是 0 到 255 的离散符号。若符号概率为 `p(x)`，Huffman 算法为常见符号分配较短码字，为少见符号分配较长码字。平均码长为

`L = sum_x p(x) * l(x)`，其中 `l(x)` 是符号 `x` 的码字长度。

编码不改变像素信息，干净链路下应逐像素还原。`source_encode` 输出压缩比特流、码字字典和图像尺寸；接收端必须使用同一字典和原始尺寸恢复图像。

## 3. 信道编码：卷积码与 Viterbi

卷积编码器将当前输入与移位寄存器状态组合，形成有记忆的有限状态机。本项目使用约束长度 `K=3`、生成多项式 `(7,5)` 的速率 `1/2` 卷积码，并附加两个尾比特回到零状态。

Viterbi 译码在网格图上逐时刻执行加、比、选（ACS），保留到达每个状态的最优路径，最后回溯得到信息序列。软判决直接使用接收符号幅度；硬判决只使用 0/1 决策，软信息在 AWGN 下能保留更多关于接收可靠性的线索。

## 4. 极化码：信道极化与列表译码

极化变换将 `N` 个物理信道组合并拆分成可靠性不同的子信道。GA 构造根据设计 `Eb/N0` 估计子信道可靠性，把 `K` 个信息位放到最可靠的位置，其余位置固定为冻结位 0。

- **SC（Successive Cancellation）**：按顺序估计每个信息位，已作出的决定会参与后续判断。
- **SCL（Successive Cancellation List）**：在信息位上保留多个候选路径，按路径度量排序并限制列表长度 `L`。
- **CRC-8 辅助选路**：对列表候选逐一做 CRC 检查，选择第一个校验通过的路径。

这些实现共享 LLR（对数似然比）输入接口。LLR 正负表示更倾向 0 或 1，绝对值表示置信程度。

## 5. BPSK 与 AWGN

本项目采用 `0 → +1`、`1 → -1` 的 BPSK 映射。AWGN 信道模型为

`y = x + n`，`n ~ N(0, sigma^2)`。

对于码率 `R` 和每信息比特信噪比 `Eb/N0`，噪声方差设为

`sigma^2 = 1 / (2 * R * 10^(EbN0_dB/10))`。

未编码 BPSK 的理论误码率为 `Q(sqrt(2*Eb/N0))`，也可写为 `0.5*erfc(sqrt(Eb/N0))`。`run_channel_demo` 同时绘制仿真值和理论基准，检验信道实现与信噪比换算。

## 6. 实验如何阅读

### 信道编码对比

`run_channel_demo` 比较未编码 BPSK、卷积码软 Viterbi、极化 SC、极化 SCL(8) 与极化 SCL(8)+CRC-8。BER 表示错误信息位数占比；FER 表示至少发生一个信息位错误的帧占比。曲线随 `Eb/N0` 增大而下降，反映噪声减弱后的传输改善。

### 图像全链路

`run_source_demo` 展示 64×64 测试图像的 Huffman 无损往返与实际码长。`run_image_demo` 取相同测试图像，在相同 `Eb/N0` 网格上比较：原始像素直接传输、Huffman 压缩后直接传输、Huffman 压缩后再用卷积码保护。输出包括原图和各链路重建图、图像比特 BER、PSNR，以及 Huffman 压缩比。

PSNR 定义为 `10*log10(255^2/MSE)`，其中 `MSE` 是原图与重建图逐像素平方差的平均值。PSNR 越高代表像素级重建越接近原图。Huffman 码是变长码，误码会改变后续码字边界；卷积码保护压缩流时能减少这类传输差错。

## 7. 源码地图

| 文件 | 作用 |
|---|---|
| `src/source_encode.m`、`src/source_decode.m` | Huffman 信源编码和图像重建 |
| `src/conv_encode.m`、`src/viterbi_decode.m` | 卷积编码和硬/软 Viterbi 译码 |
| `src/polar_construct.m`、`src/polar_encode.m` | GA 子信道构造和极化变换 |
| `src/polar_sc_decode.m`、`src/polar_scl_decode.m` | SC、SCL 与 CRC 辅助译码 |
| `src/awgn_llr.m`、`src/hard2llr.m` | AWGN 接收量和 LLR 计算 |
| `src/modulate_bpsk.m`、`src/awgn_channel.m`、`src/demodulate_bpsk.m` | BPSK 调制、噪声信道和判决 |
| `src/evaluate_performance.m` | MSE、PSNR、像素 BER |

## 8. 推荐答辩演示顺序

1. 从一张图像说明像素符号和冗余表示。
2. 展示 Huffman 前后比特数，说明源压缩的作用。
3. 展示 AWGN 下的理论 BER 与仿真 BER，说明信道模型可信。
4. 展示卷积码、SC、SCL、SCL+CRC 曲线，解释状态搜索和候选路径。
5. 打开图像链路重建结果，结合 PSNR/BER 解释端到端质量。
