# 来源、归属与许可

|来源|用途|许可与代码边界|
|---|---|---|
|[Teem NRRD 格式规范](https://teem.sourceforge.net/nrrd/format.html)|字段、轴 0 最快、编码及空间语义的行为依据|遵循格式，未复制规范正文或 Teem C 实现|
|[pynrrd](https://github.com/mhe/pynrrd) 1.1.3|开发期独立读写对照|MIT；运行其包生成合成 fixture，未复制实现|
|[NumPy](https://numpy.org/) 2.2.6|开发期类型、数组布局及比较|BSD-3-Clause；仅开发依赖，未打包上游源码|
|[MoonBit core](https://github.com/moonbitlang/core)|字符串、UTF-8、浮点基础接口|官方 core；按工具链附带许可证使用|
|[MoonNIfTI](https://github.com/wangjiale6036-dotcom/moonnifti)|查重、相邻能力对比|仅阅读公开接口、源码与测试；未复制实现|

项目独立实现 NRRD 标量子集与轴变换，以 MIT 发布。固定测试数据由本仓库脚本合成，没有下载临床图像或私人数据。生成的 oracle_test.mbt 和 promotions.mbt 不计生产代码行数。
