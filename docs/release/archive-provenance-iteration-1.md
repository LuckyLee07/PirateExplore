# iOS 候选产物溯源迭代 1

日期：2026-07-17

本轮结论：**`V2-037 / P1` 已关闭。iOS App 与 archive 现在内嵌候选 ID 和源码 Git 提交；普通开发构建会自动标记 `HEAD-dirty`，冻结候选门禁拒绝脏源码、未知提交、候选不一致以及 App/dSYM UUID 不一致。产品范围与阶段 4 仍保持 FROZEN / HOLD。**

## 1. 发现的问题

此前 `validate_ios_archive.py` 能证明 archive 的版本、build、Bundle ID、arm64、图标、隐私清单、离线资源、存档恢复与遗留符号符合要求，但产物自身没有记录：

- 它由哪个 Git 提交生成；
- 它属于哪个内部/TestFlight/App Store 候选；
- 构建时是否存在未提交的源码改动。

因此两个内容相似的 archive 可能被人工改名后混淆。外测、真机和最终上线虽然各自要求 `build_commit` 或 `candidate_id`，却无法从 App 包内反向核对。这会削弱后续“同一候选”证据链。

## 2. 新的产物身份

iOS `Info.plist` 新增两个由构建设置注入的字段：

| 字段 | 含义 | 示例 |
| --- | --- | --- |
| `NewPirateSourceCommit` | 构建使用的仓库提交 | `2f1b668…` 或 `2f1b668…-dirty` |
| `NewPirateCandidateID` | 当前候选身份 | `development`、`2.0.0-1-internal` |

`xcode.sh` 的默认行为：

- 从仓库 `HEAD` 取得完整 40 位提交；
- tracked 文件存在 staged 或 unstaged 差异时追加 `-dirty`；
- 不把用户自有的未跟踪工作目录误算成候选源码；
- 未显式指定候选时使用 `development`；
- 模拟器、device compile 和 archive 使用同一组注入规则。

调用方可以通过 `NEWPIRATE_SOURCE_COMMIT` 和 `NEWPIRATE_CANDIDATE_ID` 显式锁定值，但 archive 校验仍会检查提交是否真实存在。

## 3. 校验与证据记录

### 3.1 archive 内容校验

`validate_ios_archive.py` 现在始终要求两个字段存在且格式合法，并新增：

- `--expected-source-commit`：精确核对内嵌提交；
- `--expected-candidate-id`：精确核对候选 ID；
- `--require-clean-provenance`：拒绝带 `-dirty` 的 archive。

原有版本、内容、隐私、架构和符号检查保持不变。

### 3.2 冻结候选记录

`archive_provenance.py --require-clean-head` 额外要求：

- archive 内嵌提交等于当前仓库 `HEAD`；
- tracked 工作树没有 staged/unstaged 变化；
- 内嵌提交可解析到 commit 对象；
- App 可执行文件与 dSYM 的 Mach-O UUID 完全一致。

通过 `--record-output` 可生成候选记录，包含候选 ID、源码提交、版本/build、archive 路径、可执行文件与 dSYM 的 SHA-256、字节数、Mach-O UUID，以及 Info.plist SHA-256。该记录用于下一轮从干净提交生成内部冻结候选，不替代最终 Distribution 签名或 TestFlight build ID。

## 4. 专项回归

`test_archive_provenance.py` 已覆盖：

1. 已存在提交与正确候选通过；
2. 普通校验允许 `-dirty` 开发证据；
3. clean 候选门禁拒绝 `-dirty`；
4. 预期提交不一致被拒绝；
5. 预期候选 ID 不一致被拒绝；
6. 非法提交格式、仓库不存在的提交和非法候选格式均被拒绝。

专项测试已接入 `tools/release/validate_ios_release.sh`，静态发行校验同时锁定 Info.plist、`xcode.sh`、archive 内容校验器、溯源工具和回归用例之间的接线。

## 5. 端到端验收结果

- `bash -n xcode.sh` 与 Info.plist lint：通过；
- 专项回归：通过 clean/dirty、提交存在性和两类不一致拒绝；
- 阶段 0–4 与发行级完整回归：通过；
- Release 模拟器：构建通过，App Info 实际写入 `2f1b668d0fc5f9696776ce0997c55aa1535ef8b5-dirty` 和 `development`；
- iPhone SE 3：全新安装默认玩家档启动成功，新增元数据不改变玩家界面与运行流程；进程持续至 2 分 23 秒，状态为 `Rs`；
- Release device compile：通过；
- 无签名 archive：`NewPirate-provenance-iteration-1.xcarchive` 生成成功；
- archive 内容与精确身份：`2.0.0-1-provenance-test`、`2f1b668…-dirty` 均匹配；
- clean 候选门禁：同一 archive 因 `-dirty` 被预期拒绝，证明开发产物不能冒充冻结候选；
- 既有 OpenGLES/旧静态库 platform metadata 警告仍属于 `V2-005`，没有新增编译错误；
- App Store 30 项外部字段与总体产品外部门槛继续保持 pending/HOLD。

## 6. 下一轮

本轮只建立并验收产物身份机制。提交本轮工具后，下一轮将从干净 HEAD 生成 `2.0.0-1-internal` archive，使用 `--require-clean-head` 生成源码提交、二进制 SHA-256 和 dSYM UUID 记录，再独立回归并提交证据。

在 Distribution 签名、真实设备和两轮外测完成前，该内部候选仍不是可上传或可上线版本。
