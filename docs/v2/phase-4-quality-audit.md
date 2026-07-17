# V2 阶段 4：内部质量审计

日期：2026-07-16

范围：第一章 V2 样片、阶段 4 本地测试记录、iOS 模拟器多尺寸矩阵/设备编译

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

阶段 4 的存档 schema 为 4。schema 3 只缺少本地测试记录，因此迁移时保留章节阶段、资源、路线、战斗、奖励与升级，再由控制器创建新的测试会话。恢复前同时校验章节节点、模块、路线、资源、船只、战斗数值、历史与关键计数；结构未知、章节不符、stage 非法或嵌套字段损坏的存档回退为同 profile 的合法新档，并在“最近结果”显示恢复说明，避免静默崩溃和死路。

后续原生审计又发现，旧底层容器在 Lua 校验前直接覆盖正式文件并信任文件头长度，物理截断可能先触发越界或异常分配。`V2-020` 已新增受限 `RecordCodec`、LZSS 输出容量、4/8 字节旧头兼容、16 MiB 原文上限和临时文件 `fsync + rename` 原子替换。ASan/UBSan 覆盖全部截断前缀、1500 组变异和写入失败保留旧档；iOS 26.2 Release 实际把存档截断为 7 字节后仍稳定进入序章并显示恢复说明。完整证据见 [`../release/save-durability-iteration-1.md`](../release/save-durability-iteration-1.md)。

Release 静态分析进一步在引擎核心 `Data` 缓冲类定位到复制自赋值 use-after-free，以及移动赋值/`fastSet` 覆盖旧所有权的问题。`V2-021` 已改为先复制再释放、复制/移动自赋值保护和接管前清理目标缓冲；独立 ASan/UBSan 同时用 poisoning 验证旧分配确实释放。完整证据见 [`../release/native-memory-safety-iteration-1.md`](../release/native-memory-safety-iteration-1.md)。

同一轮可达性筛选还确认，启动、旧档迁移、图片、字体、脚本和用户配置共用的 `FileUtils` 忽略定位/长度/分配失败，空文件会产生未移交缓冲。`V2-022` 已统一为受限、完整读取后才移交所有权的实现；ASan/UBSan 覆盖空文件、文本终止、二进制、大小上限、分配失败和缺失文件，Release 静态分析的 `CCFileUtils.plist` 已为零诊断。完整证据见 [`../release/fileutils-read-safety-iteration-1.md`](../release/fileutils-read-safety-iteration-1.md)。

设置兼容层的 `UserDefault.xml` 迁移同样位于启动和设置可达路径。旧实现只在成功找到并迁移节点时释放 `XMLDocument`，无效 XML、空根、缺失键和无效 base64 会在重复读取时泄漏。`V2-023` 已用 move-only RAII 查询对象统一文档与节点生命周期；ASan/UBSan 覆盖正常迁移及 20,000 次缺键/损坏压力循环，Release 静态分析的两条原始 `CCUserDefault` 泄漏诊断归零。完整证据见 [`../release/userdefault-xml-ownership-iteration-1.md`](../release/userdefault-xml-ownership-iteration-1.md)。

核心标签、精灵批次和图集节点使用的 `TextureAtlas` 还允许以 0 容量初始化后按需扩容；旧实现会把 `malloc(0)` 可能返回的空地址传给 `memset`，而 Release 下负容量、字节乘法和 16 位索引范围只依赖断言或没有保护。`V2-024` 已将 CPU 侧 quad/index 建立统一为受限分配：0 容量无分配成功，拒绝负值、溢出与超过 16,384 个 quad，第二段分配失败会释放第一段。ASan/UBSan 专项与 `CCTextureAtlas.plist` 零诊断复查通过。完整证据见 [`../release/texture-atlas-allocation-iteration-1.md`](../release/texture-atlas-allocation-iteration-1.md)。

iOS 启动必经的 `CCEAGLView` 仍采用手动引用计数；旧实现没有在销毁时释放组合文本和 `markedTextStyle` 复制属性，也没有注销键盘通知观察者，`UITextInput.selectionRectsForRange` 还返回了协议不接受的 `nil`。`V2-025` 已显式绑定复制属性的 ivar，在 `dealloc` 前完成所有权和观察者清理，并用空数组表示“无选区矩形”；源契约回归及 `CCEAGLView.plist` 零诊断复查通过。完整证据见 [`../release/eaglview-ime-contract-iteration-1.md`](../release/eaglview-ime-contract-iteration-1.md)。

发布签名状态原先依靠证书名称和 Profile 文件人工摘录，同名旧证书会造成误判，也没有验证 Profile 内嵌证书是否对应本机私钥身份。`V2-026` 已增加只读关联审计，以指纹、有效期、团队、Bundle ID、工程 `DEVELOPMENT_TEAM` 和 CoreDevice 状态共同判定；实测确认当前开发身份/Profile 链有效，同时准确保留工程团队、设备稳定性和 NewPirate 分发链缺口。完整证据见 [`../release/apple-signing-readiness-iteration-2.md`](../release/apple-signing-readiness-iteration-2.md)。

同一审计中，配对设备曾在连续命令间出现 0→1→0 台 available，暴露单次终端表格采样不适合作为开发安装门槛。`V2-027` 已改用 devicectl 官方 JSON，开发严格模式强制同一物理设备连续三次满足配对、隧道、开发者模式和 DDI 条件；输出只保留哈希设备键和标准机型。完整证据见 [`../release/apple-device-stability-iteration-1.md`](../release/apple-device-stability-iteration-1.md)。

签名前材料就绪仍不能证明签名后 App 的真实 Team、证书、Profile 和 entitlements。`V2-028` 已增加产物级联合验证：strict codesign、Info/signature/application-identifier、embedded Profile、leaf 证书指纹、有效期和 arm64 必须一致，并严格区分 Development 与 App Store 模式。真实开发 App 通过，同一产物冒充分发时四项失败。完整证据见 [`../release/signed-app-integrity-iteration-1.md`](../release/signed-app-integrity-iteration-1.md)。

最终提交原先还依赖人工分别执行元数据 strict、公网页面、archive 内容和 Distribution 产物检查，且旧 strict 仅验证 codesign 结构。`V2-029` 已建立唯一最终 App Store 门禁，30 个外部字段零 pending 后才运行四项完整证据；空、skipped 或 failed 均 HOLD，独立 strict 也会拒绝 Development archive。完整证据见 [`../release/final-app-store-gate-iteration-1.md`](../release/final-app-store-gate-iteration-1.md)。

外测入口原先只聚合轮次和四个布尔指标，无法拒绝混用构建、样本分层不足或缺少访谈原始回答的形式化记录。`V2-030` 已将冻结 Git SHA、R2 新构建、匿名编号、经验/设备分层、观察时序、访谈摘要和技术失败互斥规则纳入分析器；真实模板仍为空，外测状态没有被内部回归改成通过。完整证据见 [`external-test-evidence-integrity-iteration-1.md`](external-test-evidence-integrity-iteration-1.md)。

真机体验原先只有人工检查表，稳定连接预检、模拟器运行或 device compile 都可能被误当作体验证据。`V2-031` 已建立零记录模板和严格验证器：低端 iPhone、现代 iPhone、iPad 必须使用同一候选，完成 14 项体验检查与最低持续时长；最终发布只接受同一 TestFlight build。当前缺三类真实记录并以退出码 2 保持 HOLD。完整证据见 [`../release/device-acceptance-evidence-iteration-1.md`](../release/device-acceptance-evidence-iteration-1.md)。

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

补充的 [`phase-4-simulator-matrix.md`](phase-4-simulator-matrix.md) 覆盖 iPhone SE 3、iPhone 12 Pro 和 iPad A16：短屏战斗的五个操作与平板探索的三个操作均完整可见，候选进程分别持续存活至少 8 分 58 秒和 5 分 59 秒。

iPhone 13 mini / iOS 26.2 出现红色 `rdar:45025538` 条、错误的 360×780 屏幕模型和 360×640 兼容画布。该现象与 Apple 已记录的 Xcode 26.2 mini 模拟器缺陷一致，不计为产品回归；当前可靠小屏基线改用 iPhone SE 3，mini 刘海组合留给更新后的模拟器或真机复核。

iOS 使用 `UILaunchScreen`；应用 target 不再启用弃用的 LaunchImage 名称。旧任务提示受 `legacy.missions` gate 控制，不覆盖 V2。原项目 `tools/art_refresh/` 是用户既有未跟踪目录，不属于本阶段交付或资源审计。

## 7. 构建与遗留技术债

应用与 tracked Lua bindings 工程的最低 iOS 版本已统一为 12.0；构建脚本同时向被忽略的历史引擎生成工程传入 iOS 12 override，因此干净检出也不依赖修改本地生成文件，弃用部署版本警告消失。旧预编译静态库仍产生缺少 platform load command 的链接警告，OpenGLES API 也已被系统弃用；在编译、安装和运行通过时记为 P2 技术债，不把本阶段扩成引擎迁移。

`getFileMD5` 曾返回临时字符串的悬空指针，现改为静态 `std::string` 保持返回值生命周期；XMLHttpRequest 响应头查找也不再持有临时 map 的迭代器，renderer 日志不再把 64 位指针截为 32 位。这些修改属于确定性安全修复，不改变存档或玩法行为。

## 8. 本轮验证记录

- 阶段 0～4 静态/Lua 回归：通过；18 张源表，17 类行为事件，10 个质量门槛，阶段 0～4 全链通过；
- 原生存档耐久性：通过；ASan/UBSan、32 位旧头、全部截断前缀、1500 组变异、解压越界和原子失败保留旧档全部通过；
- Cocos 核心缓冲所有权：通过；复制/移动自赋值、公开别名复制、`fastSet` 与移动替换的 ASan/UBSan 回归通过；
- 本地文件安全读取：通过；空/文本/二进制、上限、分配失败和缺失文件的 ASan/UBSan 回归通过，`CCFileUtils` Release 静态分析零诊断；
- 旧配置 XML 迁移：通过；无效、空根、缺键、成功迁移及 20,000 次压力循环通过 ASan/UBSan，两条 `CCUserDefault` Release 静态分析泄漏诊断归零；
- 纹理图集缓冲：通过；0/负容量、正常清零、16 位索引上限和两段分配失败通过 ASan/UBSan，两条 `CCTextureAtlas` Release 静态分析空指针诊断归零；
- iOS 主视图输入契约：通过；组合文本/复制属性释放、通知观察者清理、copy setter 和非空选区数组均由源契约测试锁定，`CCEAGLView` Release 静态分析诊断归零；
- arm64 iOS 模拟器构建：通过；构建脚本默认使用主机架构，产物确认为 arm64 并成功安装；
- 模拟器多尺寸运行：通过；iPhone SE 3 / iOS 17.2 的 `qa_combat`、iPhone 12 Pro / iOS 26.2 基线和 iPad A16 / iOS 26.2 的 `qa_explore` 均全屏且操作完整；
- iPhone 13 mini / Xcode 26.2：测试环境缺陷，显示 `rdar:45025538` 与错误逻辑尺寸，已从产品验收样本中剔除并以 SE 3 替代；
- 30 FPS / 2x framebuffer 内存：通过；physical footprint 102.7 MB，峰值 103.7 MB；
- 模拟器 CPU：改善但仍高；同机 88.7%，采样定位为旧 OpenGL/GLEngine 软件渲染，保留真机门槛；
- AVFoundation cannon cue 生存 smoke：通过；最终候选 PID 37720 在 cue 启动约 26 秒后仍存活；
- iOS device arm64 免签名编译：通过；
- 旧 iOS 8 部署版本警告：已清理；旧静态库 platform metadata 与 OpenGLES 弃用警告保留为 P2；
- Apple 签名只读预检：通过；当前开发私钥身份与通配开发 Profile 指纹匹配且未过期，旧“2023 年过期”结论已纠正；工程团队未确认，且没有 NewPirate 可用的 Distribution/App Store Profile 组合；
- Apple 设备稳定性预检：通过；使用官方 JSON，同一设备三连就绪才允许开发严格门禁通过；本机 iPhone/iPad 三连采样均未就绪且退出码 2，未泄露设备标识；
- iOS 签名产物完整性：通过；本地 Development App 的 strict codesign、Team/Bundle ID、leaf/Profile 指纹、entitlements 与 arm64 一致，冒充 App Store 模式严格失败；
- App Store 最终聚合门禁：通过；当前 30 个外部字段保持 pending，四项最终证据均 skipped 且总体退出码 2，没有误报 GO；
- 外测证据完整性：通过；混合构建、R2 复用提交、错轮 ID、空访谈、技术失败混填、时序倒退和样本分层不足均不能得到 PASS；模板保持零参与者行；
- 真机体验证据门禁：通过；当前模板零记录、缺少低端 iPhone/现代 iPhone/iPad 并严格 HOLD；development 结果不能冒充最终 TestFlight 矩阵；
- 真实设备触控、安全区、帧率、静音键和响度：待设备体验执行；iPhone 12 Pro 与 iPad mini 状态连续波动并在最终复核时 unavailable，不能作为实际真机证据；
- 两轮目标用户测试：待执行，所有外测 gate 仍为 `pending_external`。

阶段 4 内部候选基线可以提交；真实设备和外测项补齐前不得把 V2 总体目标标记完成或把 HOLD 改成 GO。
