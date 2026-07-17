# iOS 内部冻结候选 2.0.0-1

日期：2026-07-17

本轮结论：**`V2-038 / P1` 已关闭。已从干净提交 `e6dc27f2d03681d45582c88ad8dd70628f55a650` 生成并验证 `2.0.0-1-internal` 无签名 archive，候选记录固定了源码提交、App/dSYM UUID 与三类 SHA-256。该候选用于内部冻结和后续外测准备，不填写最终产品 `release_commit`，也不冒充分发签名、TestFlight、真机或 App Store 候选。**

## 1. 候选身份

| 字段 | 冻结值 |
| --- | --- |
| Candidate ID | `2.0.0-1-internal` |
| Source commit | `e6dc27f2d03681d45582c88ad8dd70628f55a650` |
| Bundle ID | `com.fancyGame.NewPirate` |
| Marketing version | `2.0.0` |
| Build number | `1` |
| Archive | `build/archives/NewPirate-internal-candidate-2.0.0-1.xcarchive` |
| 签名状态 | 无签名，仅工程/内容候选 |

生成前，tracked 工作树的 staged/unstaged 差异均为零；用户自有的未跟踪 `tools/art_refresh/` 没有进入构建、暂存或提交。App 内嵌 `NewPirateSourceCommit` 为纯 40 位 SHA，没有 `-dirty`，`NewPirateCandidateID` 与上表一致。

## 2. 产物指纹

权威机器记录为 [`internal-candidate-provenance-2.0.0-1.json`](internal-candidate-provenance-2.0.0-1.json)。当前值：

| 产物 | SHA-256 | 字节数 | Mach-O UUID |
| --- | --- | ---: | --- |
| App executable | `1ccf65120976af304204bc0889081ea2259cba364178cc44bb3ba2c6ffc95beb` | 3,793,192 | `609B891E-7C3C-3FA8-97E6-2A697E6BB57E` |
| dSYM DWARF | `6b3bafae2b37d307b9e347c3402330a08dd3734907fa43b8d3be1f2951c8048f` | 5,382,486 | `609B891E-7C3C-3FA8-97E6-2A697E6BB57E` |
| App Info.plist | `b89473342911fa121bae186810b5e5a5569104d395843303b21bb55f44f67e75` | — | — |

App 与 dSYM UUID 完全一致，可用于崩溃符号文件关联。archive 目录属于本地忽略构建产物；JSON 指纹与本文纳入版本控制，使缺少 archive 的环境仍能审查候选身份，但不能伪称已经复验本地字节。

## 3. 生成与复验

生成命令：

```bash
NEWPIRATE_CANDIDATE_ID=2.0.0-1-internal \
ARCHIVE_PATH="$PWD/build/archives/NewPirate-internal-candidate-2.0.0-1.xcarchive" \
./xcode.sh ios-archive

HEAD_SHA="$(git rev-parse HEAD)"
python3 tools/release/validate_ios_archive.py \
  build/archives/NewPirate-internal-candidate-2.0.0-1.xcarchive \
  --expected-source-commit "$HEAD_SHA" \
  --expected-candidate-id 2.0.0-1-internal \
  --require-clean-provenance

python3 tools/release/archive_provenance.py \
  build/archives/NewPirate-internal-candidate-2.0.0-1.xcarchive \
  --expected-source-commit "$HEAD_SHA" \
  --expected-candidate-id 2.0.0-1-internal \
  --require-clean-head \
  --record-output docs/release/internal-candidate-provenance-2.0.0-1.json
```

对仍保留本地 archive 的环境，权威反向复验命令为：

```bash
python3 tools/release/archive_provenance.py \
  --verify-record docs/release/internal-candidate-provenance-2.0.0-1.json
```

它会从 JSON 解析 archive 路径，重新读取 App 内嵌身份，重新计算可执行文件、dSYM 和 Info.plist 哈希，并拒绝任一字节、UUID、候选 ID 或提交不一致。

## 4. 验收结果

- 干净源码门禁：通过；source commit 精确等于 `e6dc27f…`，没有 `-dirty`；
- archive 内容：版本、build、Bundle ID、图标、隐私清单、离线内容、arm64、存档恢复和遗留符号检查通过；
- 候选身份：`2.0.0-1-internal` 与 archive 内嵌值一致；
- App/dSYM：Mach-O UUID 一致；
- 指纹记录：生成后反向复验通过；
- 篡改回归：dirty commit、错误提交、错误候选、非法/未知提交、错误 SHA-256、App/dSYM UUID 不一致和多余字段均被拒绝；
- 阶段 0–4 与发行级完整回归：通过；
- App Store 外部字段仍为 30 项 pending，总体产品门禁仍为 47 项 pending；
- 没有修改第一章冻结内容、数值、资源或存档 schema。

## 5. 使用边界

该记录是“内部候选来自哪里、字节是什么”的证据，不是最终上线身份：

- `docs/release/product-launch-manifest.json` 的 `release_commit` 继续保持 `null`；
- 外测 R1/R2 仍需各自冻结并记录真实 `build_commit`；
- 最终真机门槛只接受同一个 TestFlight build；
- App Store 门槛仍需 Distribution identity、App Store Profile、签名 archive 和上传 build ID；
- 外测、真机、账号与后台证据完成前，阶段 4 和产品总体结论继续 **HOLD**。

下一步可以围绕该内部候选完善“测试包交付清单与外测会话完整性”，但按当前指示不立即执行真实设备或外部参与者测试。
