# 《海上探险家》V2：原生核心缓冲所有权（迭代 1）

日期：2026-07-17

候选范围：iOS 2.0.0（build 1），Cocos2d-x `Data` 字节缓冲

本轮结论：**Release 静态分析定位的 `Data::copy` use-after-free 已修复，同时收敛移动赋值和 `fastSet` 覆盖旧所有权导致的泄漏路径；`V2-021 / P1` 已在仓库内关闭。独立 ASan/UBSan 回归覆盖自赋值、公开别名复制、所有权替换和移动语义。**

## 1. 发现方式与范围筛选

在存档耐久性迭代提交后，对 Release iOS scheme 执行 Xcode 静态分析：

```bash
xcodebuild \
  -project projects/ios_mac/NewPirate.xcodeproj \
  -scheme "NewPirate iOS" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath build/DerivedData/ios-analyze \
  CODE_SIGNING_ALLOWED=NO \
  analyze
```

分析命令成功结束。候选自身的 `RecordCodec`、`Record`、`LZSS`、`AppDelegate`、`AppController`、`OpenUrl`、`GameBaseUtil` 与 `CppOCBridge` 报告没有诊断。生成式 tolua 绑定报告的 8 条空 `self` 路径均经过 `tolua_error`；该函数最终调用 Lua 的非返回错误跳转，但旧声明没有 `noreturn` 标注，属于分析器无法证明控制流终止的既有误报。

依赖工程仍报告大量旧引擎、自动生成绑定和未进入最终二进制的退役网络模块问题。`AssetsManager`、LuaSocket 与 XMLHttpRequest 等已由 archive 符号门禁证明不进入候选包；其余引擎诊断按可达性和当前 V2 使用面逐项筛选，不把“分析命令 exit 0”误写成“整个旧引擎零告警”。

其中 `src/engine/cocos2d-x/cocos/base/CCData.cpp` 的 `Use of memory after it is freed` 对应当前资源与文件读取会使用的核心缓冲类型，且无需异常外部输入即可由合法 C++ 自赋值触发，因此登记 `V2-021 / P1` 并修复。

## 2. 根因

旧实现有三类所有权错误：

1. `Data::copy(bytes, size)` 先调用 `clear()`，再从 `bytes` 执行 `memcpy`；当 `bytes == getBytes()` 时，源已经释放；
2. 复制赋值没有 `this != &other` 保护，`data = data` 会把内部指针传入上述别名路径；
3. 移动赋值与 `fastSet` 直接覆盖 `_bytes`，目标此前持有的 malloc 缓冲不会释放；移动自赋值还会把对象自身清空并失去原指针。

这是底层所有权不变量问题，不能依赖当前 Lua 流程“通常不会这样调用”来接受。

## 3. 修复后的不变量

- 复制赋值和移动赋值都显式处理自赋值；
- `copy` 先分配并复制到新缓冲，成功后才释放旧缓冲，公开 API 的自身指针别名也安全；
- 分配失败时保留原对象，不把已有有效数据清空；
- 移动赋值接管源缓冲前先释放目标旧缓冲；
- `fastSet` 替换前释放目标旧缓冲；若传入的就是当前指针，只更新长度而不释放后继续持有悬空地址；
- 移动完成后源对象保持 `nullptr / 0` 的合法空状态。

## 4. 独立 sanitizer 回归

`tools/release/test_ccdata_ownership.sh` 直接编译生产 `CCData.cpp`，同时启用 AddressSanitizer 与 UndefinedBehaviorSanitizer，覆盖：

- 正常复制与复制构造；
- `data = data` 复制自赋值；
- `data.copy(data.getBytes(), data.getSize())` 公开别名复制；
- `fastSet` 替换已有缓冲和自身指针别名；
- 已持有数据的目标执行移动赋值；
- 移动自赋值；
- 源对象清理后，独立复制仍保持有效。

测试通过 `__asan_address_is_poisoned` 额外确认：别名复制、`fastSet` 替换和移动赋值三条路径中的旧分配都已经释放，不只是最终字节内容碰巧正确。

该测试已接入 `tools/release/validate_ios_release.sh`，提交前每次发行回归都会执行。

## 5. 验收命令

```bash
tools/release/test_ccdata_ownership.sh
tools/release/validate_ios_release.sh
CONFIGURATION=Release ./xcode.sh ios-sim
CONFIGURATION=Release ./xcode.sh ios-device
ARCHIVE_PATH="$PWD/build/archives/NewPirate-native-memory.xcarchive" \
  CONFIGURATION=Release ./xcode.sh ios-archive
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-native-memory.xcarchive
```

2026-07-17 的最终回归结果：

| 检查项 | 结果 | 证据摘要 |
|---|---|---|
| ASan / UBSan 所有权回归 | 通过 | 复制别名、自赋值、`fastSet` 与移动替换均通过，旧分配释放检查通过 |
| Xcode Release 静态分析复查 | 通过 | 修复后 `CCData.plist` 的 `diagnostics` 为空；未把旧引擎其他告警描述为零告警 |
| 完整发行门禁 | 通过 | `tools/release/validate_ios_release.sh` 完整通过，登记问题数为 21 |
| Release 模拟器构建与运行 | 通过 | arm64 模拟器包安装成功，`com.fancyGame.NewPirate` 启动后持续运行超过 30 秒 |
| Release 真机目标构建 | 通过 | 无签名 `iphoneos` 构建成功；不替代真实设备体验、性能与音频验收 |
| 新 Release 归档 | 通过 | `NewPirate-native-memory.xcarchive` 生成成功并通过 `validate_ios_archive.py` |

构建日志仍包含 OpenGLES 弃用和部分旧预编译依赖缺少 platform load command 的既知告警，与本轮 `Data` 所有权修复无新增关联；这些告警继续按既有问题跟踪。

## 6. 边界与遗留债务

- 本轮只关闭已确认可达且根因明确的 `Data` 所有权问题，不声称升级或修复整个历史 Cocos2d-x；
- 旧引擎静态分析仍有第三方、自动生成绑定、未使用模块和分析器误报，需要结合可达路径逐项判断；
- OpenGLES 弃用、旧预编译库 platform metadata 和真机性能继续由既有 `V2-004 / V2-005` 跟踪；
- 真机矩阵、外部用户测试、分发签名、公开 URL 与 App Store Connect 仍是上线 HOLD 门槛。
