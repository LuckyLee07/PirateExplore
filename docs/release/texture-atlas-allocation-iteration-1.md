# 《海上探险家》V2：纹理图集缓冲边界（迭代 1）

日期：2026-07-17

候选范围：iOS 2.0.0（build 1），Cocos2d-x `TextureAtlas` CPU 侧 quad/index 初始化

本轮结论：**合法 0 容量初始化不再调用 `malloc(0)` 或向空地址执行 `memset`；Release 下同时增加负容量、字节乘法、16 位顶点索引和部分分配失败保护。`V2-024 / P1` 已在仓库内关闭。**

## 1. 发现方式与可达性

iOS Release 静态分析在 `CCTextureAtlas.plist` 中报告两条“向 `memset` 传入空指针”。分析路径不是纯理论分支：

- `TextureAtlas` 文档和 `resizeCapacity` 注释都明确把 0 容量作为受支持状态；
- `SpriteBatchNode::initWithFile` 直接以 0 容量初始化图集，随后再按子节点数量扩容；
- V2 第一章大量使用标签、精灵和批次渲染，`TextureAtlas` 属于候选核心渲染依赖。

旧实现分别执行两个 `malloc(capacity * size)`，只在 `capacity > 0` 且任一结果为空时返回失败，然后无条件对两个结果执行 `memset`。在 0 容量下，C 分配器允许返回空指针，把它继续传入内存函数属于未定义边界；同时 Release 编译中的 `CCASSERT(capacity >= 0)` 不能替代运行时验证。

## 2. 修复后的分配不变量

生产路径与专项测试共用 `CCTextureAtlasAllocation.h`：

- 0 容量直接返回成功，quad/index 均保持 `nullptr`，不调用分配器；
- 负容量在任何强制类型转换和分配前失败；
- 所有 `count × sizeof(Quad)`、`count × 6 × sizeof(Index)` 使用受检乘法；
- `GLushort` 索引每个 quad 需要四个顶点，最多接受 16,384 个 quad，避免索引回绕；
- 第一段或第二段分配失败都返回 false，第二段失败会先释放已成功的第一段；
- 只有两段非空分配都成功后才清零并移交给 `TextureAtlas`；
- 初始化失败仍沿用原行为释放已经 retain 的纹理并返回 false。

本轮不改动 VBO/VAO 上传、quad 排序或绘制批次语义。

## 3. 专项 sanitizer 与静态分析

`tools/release/test_texture_atlas_allocation.sh` 以 `-Wall -Wextra -Werror` 编译生产分配实现，并启用 ASan/UBSan，覆盖：

- 0 容量成功且分配调用次数为零；
- 负容量在分配前拒绝；
- 正常 quad/index 字节全部清零；
- 第一段分配失败；
- 第二段分配失败，ASan poisoning 确认第一段已释放；
- 16,385 个 quad 在分配前被拒绝；
- 空输出参数与空分配器拒绝。

修复后重新执行相同 iOS Release `analyze`，`CCTextureAtlas.plist` 的 `diagnostics` 为 `[]`，两条原始空指针诊断消失。该结论只对应这个编译单元，不表示整个历史引擎零告警。

最新 Release 包在 iOS 26.2 专用模拟器干净安装后正常进入“序章·瓶中召唤”，标题、正文、资源标签、进度节点、背景精灵和按钮均完整；PID `83276` 在采样时已持续运行 35 秒。1170 × 2532 玩家画面见 [`texture-atlas-render-player.png`](texture-atlas-render-player.png)。这证明改动没有破坏当前候选的图集渲染，但不替代真机 GPU、内存压力或持续战斗性能验收。

## 4. 验收命令

```bash
tools/release/test_texture_atlas_allocation.sh

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
ARCHIVE_PATH="$PWD/build/archives/NewPirate-texture-atlas.xcarchive" \
  CONFIGURATION=Release ./xcode.sh ios-archive
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-texture-atlas.xcarchive
```

## 5. 最终回归结果

| 检查项 | 结果 | 证据摘要 |
|---|---|---|
| ASan / UBSan 专项 | 通过 | 0/负容量、正常清零、分配失败释放和 16 位索引上限通过 |
| Release 静态分析 | 通过 | `CCTextureAtlas.plist` 的 `diagnostics` 为 `[]` |
| 完整发行门禁 | 通过 | 阶段 0～4、24 项问题登记、五组原生 sanitizer 与发行/商店准备检查全部通过 |
| Release 模拟器渲染 | 通过 | 干净安装后标签、精灵与按钮完整，PID 运行 35 秒仍存活并进入序章 |
| Release 真机目标构建 | 通过 | 无签名 `iphoneos` 编译成功；不替代真实设备验收 |
| 新 Release 归档 | 通过 | `NewPirate-texture-atlas.xcarchive` 生成成功并通过 `validate_ios_archive.py` |

最终构建只有既有 OpenGLES 弃用和旧预编译依赖缺少 platform load command 的告警；本轮没有增加新的编译或链接错误。

## 6. 边界与遗留项

- 本轮只加固初始化分配，不宣称完成旧 OpenGLES 引擎迁移；
- 16,384 上限来自当前 `GLushort` 索引格式，未来切换 32 位索引时必须同步调整实现与测试；
- 真机矩阵仍需验证持续航行/战斗的帧率、发热和内存压力；
- OpenGLES 弃用、模拟器软件渲染 CPU 和旧预编译库平台元数据继续由 `V2-004 / V2-005` 跟踪；
- 两轮外测、分发签名、公开隐私/支持 URL 和 App Store Connect 仍是上线 HOLD 门槛。
