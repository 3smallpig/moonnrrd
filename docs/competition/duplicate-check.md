# 选题、需求依据与语义查重

核查日期：2026-11-09。执行已安装 osc2026-guide Project Research Guide：moon search --limit100、MoonCakes 文档、GitHub实际源码/测试/接口、永久注册表全量能力筛查及匹配完整指纹。本记录是有界检索判断，非官方裁决或绝对唯一证明。

## 三个不同领域候选

八项分数各1–5：广度、需求依据、复用、低重合风险、深度、验证、可行性、维护。

|候选|完整工作流与成熟依据|分数|决定|
|---|---|---|---|
|BDF 字体|嵌入式/渲染器/资产工具：字形→度量/位图→布局；FreeType|4/5/4/1/4/5/4/4=31|成熟直接替代，淘汰|
|Touchstone 射频|仪器/设计/教学：S参数→转换/串接→指标；Touchstone/scikit-rf|4/5/5/1/5/5/4/4=33|成熟直接替代，淘汰|
|NRRD 多维栅格|模拟/科研影像/张量工具：栅格→轴及载荷解释→可交换NRRD与张量；Teem/pynrrd|5/5/5/4/4/5/5/4=37|通过，自动选择|

另探查 JCAMP-DX：zbhzs1/moonjcamp 直接替代；EBML：FFmpeg MoonBit 已有通用层及Matroska实现，避免重复。未进入实现。

## 需求依据、核心与可验证结果

[NRRD规格](https://teem.sourceforge.net/nrrd/format.html)、[pynrrd文档](https://pynrrd.readthedocs.io/en/stable/) 提供成熟跨生态依据；没有编造参与者经验或用户访谈。

1. 科学模拟工具：输入1–8维标量场、轴尺寸及属性，经第零轴最快布局校验与数值编码，输出附带或分离NRRD，交给Teem/Python工具；逐元素互操作对照。
2. 科研影像集成：输入带空间方向、非空间通道及原点的NRRD，解析并轴置换/区域截取，输出保持坐标含义的新文件；验证对应样本与世界坐标，不作临床诊断。
3. 张量流水线：ASCII/hex/raw输入，显式选轴/切片/拼接/归约，输出类型、形状可检查的张量及交换文件；外部消费者导入API完成流程。

完整核心：有界文本头、注释与自定义键值、1–8维布局、8种标量类型、大小端raw/ASCII/hex、attached与单文件detached（调用者传载荷，不访问路径）、非空间轴与元数据、坐标、张量变换与统计。标准未支持分支显式拒绝。

不做gzip/bzip2、block/int64/uint64、LIST/printf多文件、非零line/byte skip、隐式文件系统或网络、NIfTI/DICOM、医学诊断、通用图像/线代框架。

完成标准：三可运行流程；类型/编码/错误/边界测试；pynrrd独立双向对照；四目标check/build/test和真实CI；无凭据全新消费者安装精确公开版本。

## 检索范围与限制

MoonCakes查询 bdf/bitmap/font/glyph、touchstone/sparameter/rf、nrrd/teem/pynrrd/nifti/medical/ndarray/voxel/volume，limit100。宽词rf/media等有100条截断，不据宽词排除全生态。nrrd/teem/pynrrd零命中；nifti返回MoonNIfTI。NRRD规范与pynrrd文档访问成功。GitHub代码 nrrd返回6个CA证书误匹配，NRRD000为0，space directions返回1个BioSeqs热力学误匹配，data file+NRRD为0；仓库 nrrd MoonBit为0。per_page100且incomplete_results=false，仍受索引/公开可见性限制。按返回路径核查，不把标题或零结果当唯一证据。

永久注册表完整载入并按能力筛查，匹配完整指纹读取，所有reserved/completed/rejected/external-checked受保护。MoonBench/MoonContract/MoonRecur/MoonShard早期硬排除。NRRD曾作为另一项目探索项未选，不是已实现的项目，本次重新论证。新目录和仓库，不继续或包装旧项目。

## 近邻源码与能力比较

|近邻|实际证据|重合与决定|
|---|---|---|
|[bikallem/freetype](https://github.com/bikallem/freetype)0.5.3|README、src/bdf/bdf.mbt、bdf_wbtest.mbt|BDF字形/度量/位图直接替代，拒绝|
|[guolei-dev/touchstone](https://github.com/guolei-dev/moonbit-touchstone)0.2.1；0b456ae3a7553b2951d876b7e740fbfcfe42f24e|README、analysis.mbt及analysis_test.mbt|RF网络交换/分析直接替代，拒绝|
|[wangjiale6036-dotcom/moonnifti](https://github.com/wangjiale6036-dotcom/moonnifti)0.2.0；1230efe6e6accbbfcb63e041fe9b07326b398717|README、pkg.generated.mbti、affine.mbt和affine_wbtest.mbt|高度相邻：标量、3D/4D体素、坐标和裁剪。其核心为NIfTI单文件、qform/sform与影像缩放；本项目为1–8维NRRD轴/非空间方向、扩展文本头、分离载荷与多编码。向NIfTI库加入这些会改变其文件与轴契约，因此独立。共享基础坐标概念不冒充原创算法；调用者可显式转换数据。|
|[milkbobo/ffmpeg-moonbit](https://github.com/milkbobo/ffmpeg-moonbit)0.4.0|libavformat/ebml.mbt与真实样本测试及Matroska源|EBML相邻/直接可复用，不选|

[官方生态清单](https://github.com/moonbitlang/awesome-moonbit)README已实际读取；旧moonbit-community/awesome-moonbit地址404，不作为有效证据。社区组织仓库逐页读取，四页分别100、100、100、58项，已完整筛查。Token2Tensor 的 README 声明从零运行神经网络，属于模型训练方向，非 NRRD/栅格格式替代。官方清单未命中 NRRD。读取对方测试不等于运行测试；原始响应和受限访问保存在仓库外证据。不声称绝对唯一。没有复制上述项目代码。

## 并发预留与发布复核

使用固定project-registry.md.lock排他句柄重读相关指纹，同目录临时文件原子替换追加预留。发布前重查核心接口read_nrrd、space directions、detached NRRD并补记实测结果。

## 发布前实际复核（2026-11-09）

GitHub code search 对 read_nrrd、space directions + NRRD、NRRD0005 三项核心行为查询均 total_count=0，incomplete_results=false，排除本项目；这仅证明当前公开索引范围内未发现对应结果，不是唯一性裁决。MoonCakes 精确模块版本查询返回404，发布门禁仍会重新检查权威manifest。官方组织358项仓库、官方清单及相邻MoonNIfTI源码/测试的比较如上。
