# V2 阶段 4：内部质量审计

日期：2026-07-16

范围：第一章 V2 样片、阶段 4 本地测试记录、iOS 模拟器/设备编译

结论状态：内部候选基线；真机体验与两轮外测尚未完成

## 1. 审计口径

本报告把“自动验证通过”“编译通过”“模拟器进程稳定”“真机体验通过”和“目标用户门槛通过”分开记录。前四项中的任何一项都不能冒充外部用户结论；device compile 也不能冒充真机触控、音量或帧率体验。

质量门槛的唯一源表是 [`../../design/v2/data/quality_gate.csv`](../../design/v2/data/quality_gate.csv)，实际问题统一记录在 [`phase-4-issue-register.csv`](phase-4-issue-register.csv)。

## 2. 自动回归范围

`tools/v2/validate_phase4.sh` 串行执行阶段 0～4 的全部验证：

- 18 张 CSV 到 Lua 的确定性导出与陈旧检测；
- 章节、海图、事件、船员、模块、敌人、奖励的引用完整性；
- 安全/风险两条首章完整路径；
- 舰炮目标、甲板传递、接舷、失败、重试和返港恢复；
- 8 个事件、18 条以上对白、14 套表现映射和 6 个音效源；
- 17 类本地行为记录、会话摘要、非法操作和 240 条上限；
- 阶段 3 存档到阶段 4 的保留式迁移，以及损坏存档安全回退；
- 外部用户门槛必须保持 `pending_external`，防止内部数据误标通过。

本轮命令结果和记录数见第 8 节。

## 3. 存档与恢复

阶段 4 的存档 schema 为 4。schema 3 只缺少本地测试记录，因此迁移时保留章节阶段、资源、路线、战斗、奖励与升级，再由控制器创建新的测试会话。结构未知、章节不符或 stage 非法的存档回退为同 profile 的合法新档，避免崩溃和死路。

本地行为记录与 V2 scoped save 同步保存；单会话最多 240 条，避免长期 QA 重玩导致存档无限增长。记录不联网，不含个人身份信息。

## 4. 崩溃与音频

阶段 3 已复现旧 `AudioEngine.playEffect` 会导致当前 iOS 环境下进程退出。V2 已改用 AVFoundation 的 ambient 会话和 `AVAudioPlayer`，Lua 只通过受控 bridge 播放六种已映射 cue。旧后端不再出现在 V2 表现层。

候选构建需要重复两项 smoke：正常 QA 战斗档稳定运行；通过环境变量触发 cannon cue 后等待至少 8 秒并确认进程仍存活。真机还需人工检查静音键、系统音频混合和主观响度。

## 5. 性能

同一模拟器旧 60 FPS 基线曾在稳定画面采样到约 214,368 KB RSS、98.8% CPU。该样片以选择、阅读和轻量动效为主，因此候选构建将目标调整为 30 FPS。第一次 30 FPS 复测仍为 354,272 KB RSS、98.6% CPU；3 秒采样证明主要热点是 `DisplayLinkDirector::mainLoop` 下的 GLEngine 软件 `glDrawElements`，而不是 Lua 业务循环。

为减少 3x 设备上旧 OpenGL framebuffer 的无效像素开销，iOS 在不改变 640-point 设计画布的前提下封顶 2x。优化后完整 QA 战斗画面仍全屏、文字清晰、按钮位置正常；`sample` 的 physical footprint 为 102.7 MB、峰值 103.7 MB，低于 256 MB 门槛。作为补充，同机 `ps` 在运行 62 秒时为 318,688 KB RSS、88.7% CPU。RSS 包含模拟器共享/映射页，因此内部门槛以 `sample` 的 physical footprint 为准，`ps` 仅做同机趋势比较。

30 FPS 目标的最终门槛仍是真机持续航行与战斗无明显掉帧。模拟器的 OpenGL 软件渲染 CPU 不作为真机功耗结论；当前真机结果保持待测。

## 6. 资源与表现

表现和音频全部从 CSV 源表映射；验证器逐项确认背景、前景、头像和声音文件存在，并拒绝路径中包含 `generated` 或 `placeholder` 的临时资源。四个英雄画面已完成全屏模拟器截图检查。

iOS 使用 `UILaunchScreen`；应用 target 不再启用弃用的 LaunchImage 名称。旧任务提示受 `legacy.missions` gate 控制，不覆盖 V2。原项目 `tools/art_refresh/` 是用户既有未跟踪目录，不属于本阶段交付或资源审计。

## 7. 构建与遗留技术债

应用与 tracked Lua bindings 工程的最低 iOS 版本已统一为 12.0；构建脚本同时向被忽略的历史引擎生成工程传入 iOS 12 override，因此干净检出也不依赖修改本地生成文件，弃用部署版本警告消失。旧预编译静态库仍产生缺少 platform load command 的链接警告，OpenGLES API 也已被系统弃用；在编译、安装和运行通过时记为 P2 技术债，不把本阶段扩成引擎迁移。

`getFileMD5` 曾返回临时字符串的悬空指针，现改为静态 `std::string` 保持返回值生命周期；XMLHttpRequest 响应头查找也不再持有临时 map 的迭代器，renderer 日志不再把 64 位指针截为 32 位。这些修改属于确定性安全修复，不改变存档或玩法行为。

## 8. 本轮验证记录

- 阶段 0～4 静态/Lua 回归：通过；18 张源表，17 类行为事件，10 个质量门槛，阶段 0～4 全链通过；
- arm64 iOS 模拟器构建：通过；构建脚本默认使用主机架构，产物确认为 arm64 并成功安装；
- iOS 26.2 模拟器运行：通过；`qa_combat` 全屏画面和操作布局复核正常；
- 30 FPS / 2x framebuffer 内存：通过；physical footprint 102.7 MB，峰值 103.7 MB；
- 模拟器 CPU：改善但仍高；同机 88.7%，采样定位为旧 OpenGL/GLEngine 软件渲染，保留真机门槛；
- AVFoundation cannon cue 生存 smoke：通过；最终候选 PID 37720 在 cue 启动约 26 秒后仍存活；
- iOS device arm64 免签名编译：通过；
- 旧 iOS 8 部署版本警告：已清理；旧静态库 platform metadata 与 OpenGLES 弃用警告保留为 P2；
- 真实设备触控、安全区、帧率、静音键和响度：待设备体验执行；
- 两轮目标用户测试：待执行，所有外测 gate 仍为 `pending_external`。

阶段 4 内部候选基线可以提交；真实设备和外测项补齐前不得把 V2 总体目标标记完成或把 HOLD 改成 GO。
