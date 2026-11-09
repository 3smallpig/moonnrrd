# MoonNRRD

纯 MoonBit 的有界 NRRD 标量栅格交换库与轴语义变换工具。模块为 `3smallpig/moonnrrd@0.1.0`，许可证为 MIT。

科学模拟产生的多维数组、含通道的科研栅格以及传感器时间序列，都需要在数组样本、轴含义和外部交换文件之间保持一致。本库直接处理 NRRD 文本头及载荷，并在裁剪、翻转、置换时同步空间原点和方向。它提供数据交换与数值处理能力，不提供医学诊断。

## 已实现功能

- 1–8 维、严格正尺寸、轴 0 最快变化的布局，显式索引和尺寸检查。
- `I8/U8/I16/U16/I32/U32/F32/F64` 八种标量；整数转换拒绝小数、非有限值和越界，F32 转换拒绝有限值溢出。
- `NRRD0001` 至 `NRRD0005` 文件标识；必需字段、注释、标签、单位、轴种类、间距、自定义键值和空间属性。
- raw、ASCII、hex；raw/hex 显式小端或大端；附带载荷与单文件分离载荷。
- 空间与非空间轴、世界坐标求值、轴置换、翻转、区域截取、切片及严格相邻栅格拼接。
- 有限样本统计、直方图，以及按轴求和、均值、最小值、最大值。
- 操作级头部、样本数及载荷预算；结构化错误；数据和嵌套元数据采用所有权拷贝。

## 安装与环境

使用官方 MoonBit 工具链；赛事要求 `moonc >= 0.10.16`。本版本固定验证 `moonc v0.10.18+6c83a7f62`、`moon 0.1.20261028`。CI 在 Linux 上验证 wasm-gc、wasm、js、native 四目标。JS 示例需要 Node.js；native 需要 C 编译器。运行时仅依赖官方 MoonBit core，无 Python 或 C 格式库依赖。

在自己的模块目录执行：

```sh
moon add 3smallpig/moonnrrd@0.1.0
```

在使用库的 `moon.pkg` 中导入：

```moonbit
import { "3smallpig/moonnrrd" @nrrd }
options("is-main": true)
```

`main.mbt` 最小样例：

```moonbit
fn main raise {
  let t = @nrrd.Tensor::new([2, 2], @nrrd.F32, [1.0, 2.0, 3.0, 4.0])
  let encoded = @nrrd.write_nrrd(t, encoding=@nrrd.Raw, endian=@nrrd.Big)
  let restored = @nrrd.read_nrrd(encoded.attached())
  assert_eq(restored.get([1, 1]), 4.0)
  assert_eq(restored.reduce(1, @nrrd.Mean).values(), [2.0, 3.0])
  println("NRRD round trip passed")
}
```

执行 `moon run . --target js`。尺寸 `[2,2]` 对应样本索引顺序 `[0,0]、[1,0]、[0,1]、[1,1]`。库中的样本以 Double 保存，整数类型仍受各自精确范围限制，F32 在构造时规范到单精度。

## 三个可运行的完整流程

克隆本仓库后运行：

```sh
git clone https://github.com/3smallpig/moonnrrd.git
cd moonnrrd
moon run examples/simulation --target js
moon run examples/spatial --target js
moon run examples/tensor --target js
```

1. [模拟数据交换](examples/simulation/main.mbt)：标量场加距离/时间轴元数据，经大端 raw 导出与读取，检查六个样本及实验属性。
2. [空间区域处理](examples/spatial/main.mbt)：带非空间通道的栅格依次裁剪、置换、翻转，比较对应样本与世界坐标，输出分离 hex 并读取验证。
3. [张量处理流水线](examples/tensor/main.mbt)：时间分片拼接，按时间轴归约，提取切片，计算直方图并导出 ASCII，断言结果。

示例可把 `js` 换为 `wasm-gc`、`wasm` 或配置了 C 编译器的 `native`。

## API 与数据契约

完整接口见 [pkg.generated.mbti](pkg.generated.mbti)，按功能分组如下。

|任务|入口|语义|
|---|---|---|
|构造与类型|`Tensor::new`、`cast`、`with_metadata`|检查尺寸、预算、类型范围及元数据；返回新的张量|
|布局|`Shape::new`、`offset`、`indices`|轴 0 最快；拒绝负数与越界|
|文件交换|`parse_header`、`read_nrrd`、`write_nrrd`|纯缓冲区 API；不访问文件或网络|
|空间位置|`world`|必须显式提供 origin 和 directions；非空间轴贡献为零|
|轴操作|`permute`、`flip`、`crop`、`slice`|样本与相应轴属性同步；位置有定义时保留坐标|
|组合|`concatenate(left, right, axis)`|非拼接轴形状、类型及元数据匹配；空间原点精确相邻|
|归约|`reduce(axis, operation)`|忽略 NaN/Inf；全非有限组为 NaN；输出 F64|
|统计|`summary`、`histogram`|单列 NaN/Inf；直方图最后一格包含上界|

`permute([2,0,1])` 表示新轴 0 来源于旧轴 2。`crop(starts, sizes)` 第二个参数是输出尺寸。`slice(axis, index)` 删除选定轴；不产生零维张量。归约空间轴时，聚合值没有单一空间位置，因此清除空间定位；归约非空间轴则保留定位。拼接采用精确坐标比较，不隐式引入浮点容差。

分离载荷需要调用者根据 `parse_header(bytes).data_file()` 自行安全读取，再传给 `read_nrrd(header, detached=payload)`。写出时使用 `write_nrrd(t, data_file="payload.raw")`，分别保存 `Encoded.header` 和 `Encoded.payload`；带分离计划的 `attached()` 会报错。库不解引用头部路径。

`Limits::default()`：头部 65,536 字节、1,000,000 样本、编码载荷 64,000,000 字节；可通过 `limits=` 缩小或调大。样本存储统一为 Double，因此载荷字节预算不是总堆内存上限。解码、变换和所有权拷贝会分配额外数组；上层应结合输入长度和并发数限制内存。

错误类型 `NrrdError` 包含 `Invalid`、`Unsupported`、`Limit`、`Truncated`，可通过 MoonBit `try/catch` 或函数的 `raise` 传播。失败不会返回部分张量。

## 检查、构建与测试

```sh
moon version --all
moon info
moon fmt --check
moon check --target all --deny-warn
moon build --target js --deny-warn
moon test --target js --deny-warn
```

按目标分别执行 check/build/test 可复现 [CI](.github/workflows/ci.yml)。测试包含正常与畸形头部、截断、数值边界、大小端、三编码、附带/分离、元数据注入、预算边界、所有权，以及 1–8 维轴操作性质。当前每后端 122 项测试；循环内组合不另算测试数量。

独立互操作测试仅开发时需要 Python 3.12：

```sh
python -m pip install -r scripts/requirements-oracle.txt
python scripts/interop.py --check
```

每个方向 64 组 pynrrd 直接 raw/ASCII 对照，另有 32 组独立 Python hex/raw 转换桥接对照。组合为 8 类型 × 3 编码 × 2 大小端 × 2 存储方式；ASCII 的大小端组合等价。pynrrd 1.1.3 不支持 hex，不能将桥接结果表述为其原生 hex 兼容证明。生成样本和往返导出会逐元素及元数据比较，未使用外部私人数据。`--generate` 后执行 `moon fmt` 可更新固定测试向量；`--check` 检查再生成一致性并运行双向对照。

## 支持边界与已知限制

- 这是 NRRD 标量子集实现。gzip/bzip2、block、int64/uint64、LIST/printf 多文件、非零 byte/line skip 和未实现标准字段会明确拒绝，包括 measurement frame、sample units、axis mins/maxs、centers、thicknesses。
- 头部及元数据文本限制为可打印 ASCII；文件行可使用 LF 或 CRLF。标签中的中文或其他 Unicode 文本不受支持。自定义键禁止冒号、首尾空白和注释前缀。
- 分离文件名仅支持安全 ASCII basename；目录、空白、路径穿越、LIST 保留词不接受。
- spacings 限定为正有限数或 NaN，且不与 directions 同时设置；没有 origin/directions 时不猜测世界坐标。只有 origin 而缺 directions 时，涉及非零平移的操作明确拒绝。
- 固定长度 kind 必须符合对应轴尺寸；截取这类轴导致长度变化时会拒绝，调用者可显式替换 kind 后操作。
- 轴变换不重定向 vector/tensor 分量，不做重采样、插值、坐标系转换、NIfTI/DICOM 或通用图像处理。
- NaN 保留数值含义，不保证 payload 位模式；ASCII 保留负零；浮点运算遵循目标的 IEEE 754 行为，测试不宣称形式化证明或性能优势。

## 结构、来源与许可证

根目录为可导入库，`cmd/interop` 为测试导出器，`examples/` 为完整流程，`scripts/` 为独立互操作工具。详见 [架构](docs/architecture.md)、[安全与资源模型](docs/security.md)、[来源与许可](docs/references.md)、[AI 使用说明](AI_USAGE.md)、[版本记录](CHANGELOG.md) 和 [查重记录](docs/competition/duplicate-check.md)。

本项目为依据 [NRRD 规范](https://teem.sourceforge.net/nrrd/format.html) 独立编写的 MoonBit 实现，不是 pynrrd 的逐行移植。pynrrd（MIT）和 NumPy（BSD-3-Clause）仅用于独立测试；没有复制其实现。项目代码以 [MIT](LICENSE) 发布；AI 参与了设计、实现、测试和文档，具体范围与责任见 AI 使用说明。
