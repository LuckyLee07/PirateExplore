# 《海上探险家》V2：iOS 主视图输入契约（迭代 1）

日期：2026-07-17

候选范围：iOS 2.0.0（build 1），Cocos2d-x `CCEAGLView` 生命周期与 `UITextInput` 协议实现

本轮结论：**iOS 主 OpenGL 视图销毁时会释放组合文本和复制样式、注销通知观察者；选区矩形接口不再返回 `nil`。`V2-025 / P1` 已在仓库内关闭。**

## 1. 发现方式与可达性

iOS Release 静态分析在 `CCEAGLView.plist` 中定位到 `markedTextStyle` 复制属性在 `dealloc` 前未释放；同一编译单元复核还发现 `markedText_` 只有编辑流程释放、视图销毁没有兜底，且 `selectionRectsForRange:` 返回 `nil`，不满足当前 `UITextInput` 的非空数组契约。

这不是孤立的历史工具类：`AppController` 在每次 iOS 启动时创建 `CCEAGLView` 作为 `GLView`，当前 V2 的场景渲染、触摸和键盘输入都经过该视图。问题主要影响视图销毁、组合输入和系统查询选区的边界，不代表已有首章渲染必然崩溃。

## 2. 修复后的所有权与协议不变量

- `markedTextStyle` 使用显式 ivar，并由手写 setter 执行 `copy`，替换前释放旧值；
- 两条初始化路径都把样式 ivar 初始化为 `nil`；
- `dealloc` 在 `[super dealloc]` 前释放 `markedText_`、`markedTextStyle_` 和键盘通知副本；
- `dealloc` 主动从 `NSNotificationCenter` 注销，避免视图生命周期结束后继续接收通知；
- `selectionRectsForRange:` 在没有可用矩形时返回空 `NSArray`，以“空集合”而非空对象表达结果；
- 不改动 V2 的文本编辑转发、OpenGL surface、framebuffer 或触摸坐标语义。

## 3. 自动验证与静态分析

`tools/release/test_eaglview_contract.py` 直接校验生产头文件和 Objective-C++ 实现，锁定显式 ivar、copy setter、`dealloc` 清理顺序、观察者注销及非空选区数组，防止旧 MRC 引擎后续合并时退回自动合成或 `nil` 返回。

修复后重新执行 iOS Release `analyze`，`CCEAGLView.plist` 的 `diagnostics` 为 `[]`。该结果只说明这个编译单元当前没有静态分析诊断，不等同于整个历史引擎零告警，也不能证明中文输入法候选词交互已在真机完成。

## 4. Release 运行 smoke

最新 Release 模拟器包在 iOS 26.2 专用 iPhone 12 Pro 模拟器完成干净安装后，连续执行三轮启动/终止：PID `94238`、`94492`、`94869` 分别在 7、8、8 秒复核时仍存活，随后由 `simctl terminate` 正常结束。第四轮 PID `95216` 在 20 秒复核时仍存活并完整进入“序章·瓶中召唤”，标题、正文、资源栏、进度节点和按钮均可见。

最终 1170 × 2532 玩家画面记录在 [`eaglview-lifecycle-player.png`](eaglview-lifecycle-player.png)。这项 smoke 只验证主视图可创建、渲染并经历应用终止/重启，不冒充真机输入法、键盘动画或内存图谱验收。

## 5. 验收命令

```bash
python3 tools/release/test_eaglview_contract.py

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
ARCHIVE_PATH="$PWD/build/archives/NewPirate-eaglview-contract.xcarchive" \
  CONFIGURATION=Release ./xcode.sh ios-archive
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-eaglview-contract.xcarchive
```

## 6. 最终回归结果

| 检查项 | 结果 | 证据摘要 |
|---|---|---|
| 源契约专项 | 通过 | MRC 清理、copy setter、观察者注销和非空选区数组全部锁定 |
| Release 静态分析 | 通过 | `CCEAGLView.plist` 的 `diagnostics` 为 `[]` |
| 完整发行门禁 | 通过 | 阶段 0～4、25 项问题登记、六组专项回归和发行/商店准备检查全部通过 |
| Release 模拟器生命周期 | 通过 | 干净安装后三轮启动/终止及第四轮 20 秒存活通过，序章画面完整 |
| Release 真机目标构建 | 通过 | 无签名 `iphoneos` arm64 编译成功；不替代真实设备验收 |
| 新 Release 归档 | 通过 | `NewPirate-eaglview-contract.xcarchive` 生成成功并通过 `validate_ios_archive.py` |

最终构建只有既有 OpenGLES 弃用和旧预编译依赖缺少 platform load command 的告警；本轮没有增加新的编译或链接错误。

## 7. 当前边界

- 本轮修复 MRC 生命周期和 `UITextInput` 返回契约，不重写历史输入法适配层；
- 模拟器多次启动/终止不能替代真机中文输入、候选词、退格和键盘升降动画；
- 旧 OpenGLES、模拟器软件渲染 CPU 和旧预编译库平台元数据继续由 `V2-004 / V2-005` 跟踪；
- 真机矩阵、两轮外测、分发签名、公开隐私/支持 URL 和 App Store Connect 仍是上线 HOLD 门槛。
