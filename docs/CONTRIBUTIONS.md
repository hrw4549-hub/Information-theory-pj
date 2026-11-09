# 模块与团队贡献

项目按端到端通信链路组织，成员职责与代码模块一一对应。仓库保留原始实验报告和测试报告，代码入口按统一的 `src/` 目录整理。

| 成员职责 | 项目成果 | 对应文件 |
|---|---|---|
| 信源编解码与图像压缩 | Huffman 字典构建、比特流编码、图像解码和尺寸恢复 | `src/source_encode.m`、`src/source_decode.m` |
| 信道编码与纠错 | 卷积码、Viterbi 硬/软判决、极化码 SC/SCL、CRC-8 | `src/conv_encode.m`、`src/viterbi_decode.m`、`src/polar_*.m`、`src/crc_*.m` |
| 调制与信道仿真 | BPSK、AWGN、硬判决解调、软信息计算 | `src/modulate_bpsk.m`、`src/awgn_channel.m`、`src/awgn_llr.m`、`src/demodulate_bpsk.m` |
| 系统集成与性能评估 | 统一数据流、端到端图像实验、BER/FER/PSNR 指标和结果图 | `run_image_demo.m`、`run_channel_demo.m`、`src/evaluate_performance.m` |
| 测试、实验分析与报告 | 固定种子测试、可复现实验、算法推导和结果解读 | `run_tests.m`、`tests/`、`docs/PROJECT_GUIDE.md`、`docs/original-reports/` |

原分工文档中五类职责在仓库中的呈现，按实际完成的模块和交付物归并说明。
