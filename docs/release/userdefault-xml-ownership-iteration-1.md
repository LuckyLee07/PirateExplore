# 《海上探险家》V2：旧配置 XML 迁移所有权（迭代 1）

日期：2026-07-17

候选范围：iOS 2.0.0（build 1），Cocos2d-x `CCUserDefault` 的旧 `UserDefault.xml` 兼容迁移

本轮结论：**启动与设置可达的旧 XML 迁移已改为统一 RAII 所有权；无效 XML、空根、缺失键、无效 base64 和正常迁移均不会遗留 `XMLDocument`。`V2-023 / P1` 已在仓库内关闭。**

## 1. 发现方式与可达性

在 iOS Release scheme 执行 Xcode 静态分析后，`CCUserDefault` 编译单元报告两条潜在泄漏。它不是已经退役的历史模块：应用启动会读取 `kItWasChangeData`，声音等设置也通过 `UserDefault` 读写；只要沙盒中仍有旧版 `Library/Caches/UserDefault.xml`，兼容路径就会被触发。

旧实现动态创建 `tinyxml2::XMLDocument`，再通过裸指针返回给调用方。只有“找到目标节点并完成迁移”的分支调用 `delete`；以下状态会直接返回而不释放：

- XML 文件无法解析；
- 根元素或第一个子元素缺失；
- 目标键不存在；
- 数据节点存在但 base64 解码失败；
- 写入新 `NSUserDefaults` 时触发的按键清理再次查不到旧节点。

这会让启动或设置访问在异常旧文件上重复累积内存，因此登记为 `V2-023 / P1`。

## 2. 修复后的所有权不变量

新增的 `CCUserDefaultXML.h` 提供 move-only `LegacyXMLLookup`：

- `std::unique_ptr<tinyxml2::XMLDocument>` 是 XML 文档唯一所有者；
- 只有找到目标节点时才保留文档，节点指针的生命周期始终受查询对象约束；
- 无效 XML、空根和缺失键从 `parse` 返回时自动销毁局部文档；
- 成功迁移后由 `removeNodeAndSave` 删除节点并保存剩余 XML，查询对象析构时释放文档；
- base64 输出先初始化为 `nullptr`，无效节点也会被清理，避免每次读取重复进入失败迁移；
- 查询对象禁止复制，只允许移动，避免隐式形成多重所有权。

业务 getter 的返回值和迁移顺序保持不变；改动只收敛旧兼容层的生命周期和失败清理。

## 3. 专项回归与静态分析

`tools/release/test_userdefault_xml.sh` 直接编译生产 `CCUserDefaultXML.h` 与生产 `tinyxml2.cpp`，启用 `-Wall -Wextra -Werror` 和 ASan/UBSan。覆盖：

- 空字符串与损坏 XML；
- 空根元素；
- 目标键缺失；
- 找到节点后值在文档所有权范围内保持有效；
- 迁移删除目标键并保留无关键；
- 20,000 次“缺失键 + 损坏 XML”循环。

当前 Apple clang 的 AddressSanitizer 明确不支持 `detect_leaks=1`，因此脚本使用 ASan/UBSan 检查越界、释放后使用和未定义行为；泄漏结论由生产代码所有权结构、压力回归以及 Xcode 静态分析复查共同支撑，不冒充 LeakSanitizer 结果。

修复前的两个 `CCUserDefault` 静态分析 plist 都包含泄漏诊断；修复后同一 Release `analyze` 命令生成的三个 `CCUserDefault*.plist` 的 `diagnostics` 均为 `[]`。这只代表相关编译单元，不表示整个历史引擎零告警。

## 4. 物理迁移验收

专项 fixture `tools/release/fixtures/userdefault-legacy-migration.xml` 包含启动键 `kItWasChangeData=true` 和无关键 `unrelatedKey=kept`。最终 Release 模拟器验收会在应用未运行时把它放入沙盒 `Library/Caches/UserDefault.xml`，再验证：

- 应用正常进入“序章·瓶中召唤”并持续存活；
- `kItWasChangeData` 迁入 `Library/Preferences/com.fancyGame.NewPirate.plist`；
- 旧 XML 中目标键被删除；
- 无关键仍然保留。

2026-07-17 在 iOS 26.2 专用模拟器上执行后，PID `76053` 在采样时已持续运行 40 秒；Preferences 中 `kItWasChangeData = 1`，迁移后的 XML 只剩 `<unrelatedKey>kept</unrelatedKey>`，画面正常进入“序章·瓶中召唤”。玩家画面证据见 [`userdefault-xml-migration-player.png`](userdefault-xml-migration-player.png)。

该回归证明生产兼容路径实际执行且迁移结果正确；模拟器不能替代真机内存压力或闪存异常验证。

## 5. 验收命令

```bash
tools/release/test_userdefault_xml.sh

xcodebuild \
  -project projects/ios_mac/NewPirate.xcodeproj \
  -scheme "NewPirate iOS" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath build/DerivedData/ios-analyze \
  CODE_SIGNING_ALLOWED=NO \
  analyze

tools/release/validate_ios_release.sh
CONFIGURATION=Release ./xcode.sh ios-sim
CONFIGURATION=Release ./xcode.sh ios-device
ARCHIVE_PATH="$PWD/build/archives/NewPirate-userdefault-xml.xcarchive" \
  CONFIGURATION=Release ./xcode.sh ios-archive
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-userdefault-xml.xcarchive
```

## 6. 最终回归结果

| 检查项 | 结果 | 证据摘要 |
|---|---|---|
| ASan / UBSan 专项 | 通过 | 无效、空根、缺键、成功迁移、保留无关键及 20,000 次压力循环通过 |
| Release 静态分析 | 通过 | 三个 `CCUserDefault*.plist` 的 `diagnostics` 均为 `[]`，两条原始泄漏诊断消失 |
| 完整发行门禁 | 通过 | 阶段 0～4、23 项问题登记、四组原生 sanitizer 与发行/商店准备检查全部通过 |
| Release 模拟器物理迁移 | 通过 | 注入旧 XML 后启动键迁入 Preferences、XML 无关键保留；进程 40 秒仍存活并进入序章 |
| Release 真机目标构建 | 通过 | 无签名 `iphoneos` 编译成功；不替代真实设备验收 |
| 新 Release 归档 | 通过 | `NewPirate-userdefault-xml.xcarchive` 生成成功并通过 `validate_ios_archive.py` |

归档第一次在受限沙盒中执行时，`actool` 因无法访问 CoreSimulator runtime 失败；按同一命令在获准的系统环境重跑后成功。最终构建只有既有 OpenGLES 弃用和旧预编译依赖缺少 platform load command 的告警，本轮未增加新编译或链接错误。

## 7. 边界与遗留项

- 本轮只处理旧 `UserDefault.xml` 兼容迁移，不改变现代 `NSUserDefaults` 的键、默认值或同步策略；
- 旧 XML 保存失败仍沿用原接口行为：新值已经写入 `NSUserDefaults`，失败会留下旧节点供后续审计；
- 真机矩阵、两轮外部用户测试、分发签名、公开隐私/支持 URL 和 App Store Connect 仍是上线 HOLD 门槛；
- OpenGLES 弃用、模拟器软件渲染 CPU 和旧预编译库平台元数据继续由 `V2-004 / V2-005` 跟踪。
