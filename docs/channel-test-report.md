# 成员3 信道模块测试报告

## 文件清单

| 文件 | 功能 | 输入 | 输出 |
|------|------|------|------|
| `modulate_bpsk.m` | BPSK调制：0映射为-1，1映射为+1 | logical数组 | double数组 |
| `awgn_channel.m` | AWGN信道：按Eb/N0添加高斯白噪声 | double数组 + EbN0_dB标量 | double数组 |
| `demodulate_bpsk.m` | BPSK硬判决解调：实部>0判1，否则判0 | double数组 | logical数组 |
| `channel_process.m` | 封装接口：调制->信道->解调一条龙 | logical数组 + EbN0_dB标量 | logical数组 |
| `test_channel.m` | 集成测试：仿真BER vs 理论BER对比 | 无（独立脚本） | BER曲线图 |

## 接口契约（给成员2）

```matlab
rx_bits = channel_process(encoded_bits, EbN0_dB);
```

- 输入：`encoded_bits` — 一维 logical 数组，来自编码器输出
- 输入：`EbN0_dB` — 每比特信噪比，标量，单位 dB
- 输出：`rx_bits` — 一维 logical 数组，长度与输入相同，传给译码器

## 测试内容与结果

### 1. modulate_bpsk 单元测试

- 输入 `[0 1 0 1 1 0]`，输出 `[-1 1 -1 1 1 -1]`
- 输出类型为 double，值域仅为 +1/-1
- **通过**

### 2. awgn_channel 单元测试

- 50dB（几乎无噪声）下，输入 `[1 -1 1 -1]`，输出 `[1.0012 -0.9959 0.9949 -0.9981]`，偏差极小
- 10dB 下噪声幅度实测 0.1204，理论标准差 0.2236，量级合理
- **通过**

### 3. demodulate_bpsk 单元测试

- 输入 `[0.5, -0.3, 0.8, -0.1, 0, -1.2]`，输出 `[1 0 1 0 0 0]`，判决逻辑正确
- **通过**

### 4. channel_process 接口测试

- 高SNR(20dB)下输入输出一致，无误码
- 输出类型为 logical，与输入类型一致
- 输出长度与输入长度一致
- **通过**

### 5. test_channel 集成测试

- 10万比特，Eb/N0 = 0~10 dB
- 仿真BER曲线与理论BER曲线基本吻合
- 高SNR处（9dB）仿真值 1×10⁻⁵ vs 理论值 3.36×10⁻⁵，属正常统计波动（期望错误数仅3~4个）
- **通过**

## 结论

5个文件全部测试通过，模块功能正确，可交付给成员2（编码）和成员4（译码）集成。
