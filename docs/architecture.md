# 架构与行为约束

`Shape` 在乘积前用除法检查样本预算，最多 8 维；第零轴 stride 为 1。`Tensor` 私有保存 shape、标量类型、Double 样本及元数据，公开 getter 返回数据及嵌套数组拷贝。所有构造都检查标量规范化和元数据形状。

读取分为 header_lex 的有界 ASCII 扫描、header 的字段与语义计划、reader 的载荷选择，再进入 ascii/raw/hex 纯编码器。载荷不会作为头部文本处理。分离文件由上层提供 Bytes，不对 data file 字段进行隐式 I/O。未知标准字段明确拒绝，自定义 `:=` 原样保存值。

writer 先验证目标预算并产生确定性头部，自定义键排序；随后生成编码载荷。Encoded 分开保存 header/payload，只有附带计划允许 attached()。所有八种数值范围在 scalar 中集中维护，raw 使用显式位操作，避免宿主字节序差异。

coordinates 用 origin + Σ(index × direction) 求位置；none 方向代表非空间轴。permute/crop/flip/slice 同步轴属性和原点；归约空间轴清除几何位置；concatenate 检查网格连续而不简单丢弃右侧元数据。统计忽略非有限值并单独计数；Sum 使用补偿累加，溢出返回错误，Mean 使用加权增量以减少中间和溢出。

错误分为非法输入、明确未支持、预算超限和截断。库没有文件系统、网络、平台专属 FFI 或后台状态。Python 只用于开发期独立对照，不进入运行时。
