# 《海上探险家》V2：本地文件读取安全（迭代 1）

日期：2026-07-17

候选范围：iOS 2.0.0（build 1），Cocos2d-x `FileUtils` 普通文件读取路径

本轮结论：**启动、旧档迁移、图片、字体、脚本和用户配置都会经过的 `FileUtils` 读取路径已改为检查定位、长度、上限、分配与完整读取；空文件不再形成 `malloc(0)` 所有权歧义或泄漏。`V2-022 / P1` 已在仓库内关闭。**

## 1. 发现方式与可达性

在 `V2-021` 提交后继续筛选 Release 静态分析结果。旧引擎、已裁剪模块和自动生成绑定共有大量历史诊断；本轮没有按告警数量盲目修改，而是优先核对当前候选实际调用面。

`CCFileUtils.plist` 原有三条诊断：零大小分配后访问，以及两条可能泄漏。该代码不是退役模块：

- `AppDelegate` 启动时用 `getStringFromFile` 检查 `gameRole` 和 16 个 `gameMap` 旧档；
- `UserDefault`、Lua 脚本、图片、字体和 shader 文件均使用同一读取入口；
- `GameBaseUtil` 和 `Record` 也会读取本地资源或存档。

因此异常本地文件状态可能影响干净启动、迁移或资源加载，登记为 `V2-022 / P1`。

## 2. 根因

旧 `getData` 和弃用但仍公开的 `getFileData` 存在同类边界缺口：

1. 不检查 `fseek` 和 `ftell`；`ftell` 返回负值时会参与大小计算，字符串路径可对错误位置写入终止符；
2. 不检查 `malloc`，分配失败后仍会写终止符或调用 `fread`；
3. 空文件会执行 `malloc(0)` 或分配一个终止字节，但因读取长度为零而没有把所有权交给 `Data`，也没有释放；
4. 没有把短读作为失败处理，调用方可能收到部分初始化的数据；
5. 公共返回类型是 `ssize_t`，旧实现没有在分配前证明文件长度可表示。

## 3. 修复后的读取契约

生产路径与专项测试共用 `CCFileUtilsRead.h` 中的依赖无关实现：

- 打开失败、定位失败或 `ftell < 0` 时关闭文件并返回失败；
- 在分配前同时检查调用方上限、`size_t` 加终止字节溢出和 `ssize_t` 可表示范围；
- 空文件是合法空结果，不调用 `malloc(0)`，输出固定为 `nullptr / 0`；
- 分配失败保持输出为 `nullptr / 0`；
- 必须完整读到预先测量的字节数，短读时释放临时缓冲并失败；
- 字符串仅在成功完整读取后写入末尾 `\0`；
- 每条路径都关闭 `FILE*`，失败路径统一释放尚未转移的缓冲；
- `getData` 只把非空成功结果交给 `Data::fastSet`，`getFileData` 仅在成功后更新输出长度。

## 4. 独立 sanitizer 回归

`tools/release/test_fileutils_read.sh` 以 `-Wall -Wextra -Werror` 直接编译生产读取实现，并启用 ASan/UBSan（AddressSanitizer 与 UndefinedBehaviorSanitizer）。覆盖：

- 零字节普通文件；
- 需要终止字节的文本文件；
- 含 `0x00` 和 `0xff` 的二进制文件；
- 超过显式大小上限时在分配前拒绝；
- 注入确定性分配失败；
- 文件不存在导致的打开失败；
- 目录路径不得被误当成零字节普通文件；
- 所有失败路径重置输出指针和长度。

专项结果：

```text
FileUtils read safety OK: empty, text, binary, bounds, allocation, missing and non-file input
```

## 5. Release 静态分析复查

修复后重新执行完整 iOS Release `analyze`。`CCFileUtils.plist` 的 `diagnostics` 为 `[]`，原有零大小访问和泄漏诊断消失；第一次实现中分析器指出的循环补读流状态问题也已通过收紧为“可定位普通文件必须一次完整读到测量长度”消除。

这个结论仅对应 `CCFileUtils` 当前编译单元，不被描述为整个历史引擎零告警。旧引擎其他诊断仍按候选可达性继续筛选。

## 6. 验收命令

```bash
tools/release/test_fileutils_read.sh
tools/release/validate_ios_release.sh

xcodebuild \
  -project projects/ios_mac/NewPirate.xcodeproj \
  -scheme "NewPirate iOS" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath build/DerivedData/ios-analyze \
  CODE_SIGNING_ALLOWED=NO \
  analyze

CONFIGURATION=Release ./xcode.sh ios-sim
CONFIGURATION=Release ./xcode.sh ios-device
ARCHIVE_PATH="$PWD/build/archives/NewPirate-fileutils-safety.xcarchive" \
  CONFIGURATION=Release ./xcode.sh ios-archive
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-fileutils-safety.xcarchive
```

## 7. 最终回归结果

| 检查项 | 结果 | 证据摘要 |
|---|---|---|
| ASan / UBSan 专项 | 通过 | 空、文本、二进制、上限、分配失败、缺失文件和目录输入全部通过 |
| Release 静态分析 | 通过 | `CCFileUtils.plist` 的 `diagnostics` 为 `[]` |
| 完整发行门禁 | 通过 | 阶段 0～4、22 项问题登记、三组原生 sanitizer 与发行/商店准备检查全部通过 |
| Release 模拟器物理空档 | 通过 | 干净安装后向 Documents 注入 `gameRole` 与 `gameMap0…15` 共 17 个零字节文件；进程持续存活超过 32 秒并进入“序章·瓶中召唤” |
| Release 真机目标构建 | 通过 | 无签名 `iphoneos` 构建成功；不替代真实设备低内存、触控、音频和性能验收 |
| 新 Release 归档 | 通过 | `NewPirate-fileutils-safety.xcarchive` 生成成功并通过 `validate_ios_archive.py` |

构建仍只有既有 OpenGLES 弃用和旧预编译依赖 platform metadata 警告，本轮未增加新的编译或链接错误。

## 8. 边界

- 本轮修复普通、可定位文件读取，不扩展为 zip、网络流或实时增长文件的流式读取；
- 空文件按现有上层语义返回空字符串或空 `Data`，不会被误当成有效存档内容；
- 模拟器运行可以验证候选启动和本地资源路径，但不能替代真机闪存错误、低内存压力或设备性能验收；
- 真机矩阵、外部用户测试、签名、公开 URL 和 App Store Connect 仍是上线 HOLD 门槛。
