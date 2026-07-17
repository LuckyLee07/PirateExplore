# App Store 最终发布门禁迭代 1

日期：2026-07-17

本轮结论：**`V2-029 / P1` 已在仓库内关闭。项目现在只有一个最终 App Store GO 入口，它会先要求 30 个外部 manifest 门槛全部有真实值，再连续执行元数据严格校验、隐私/支持公网内容、archive 内容与 Distribution 签名产物校验；任何 pending、skipped 或 failed 都保持 HOLD。当前实测 `pending_gate_count: 30`、`ready_for_submission: false`、退出码 2，没有联网、没有读取不存在的分发包，也没有伪填外部证据。**

## 1. 原有流程的漏项风险

此前发行文档要求人工依次运行多条命令：

- `validate_app_store_submission.py --strict`；
- `validate_public_release_pages.py --check-live-urls`；
- `validate_ios_archive.py`；
- `validate_ios_signed_app.py --mode distribution`。

这些工具各自有效，但没有一个权威入口保证四项全部执行。更重要的是，旧 `--strict` 对 archive 只运行 codesign 结构验证；一个签名完整的 Development App 仍可能通过那一步，却不具备 Apple Distribution Authority、App Store Profile 或正确的 `get-task-allow`。

`V2-029` 同时完成两项收口：

1. 新增 `tools/release/final_app_store_gate.py`，作为唯一最终 GO 命令；
2. 加固独立的 `validate_app_store_submission.py --strict`，即使绕过统一入口直接运行，也必须调用 Distribution 产物验证器。

## 2. 唯一最终命令

```bash
python3 -B tools/release/final_app_store_gate.py --json
```

只有输出同时满足以下条件才允许提交：

```text
pending_gate_count: 0
audit_errors: []
all checks.status: passed
ready_for_submission: true
exit: 0
```

空检查列表、任一 skipped、任一 failed 或任一 audit error 都不能得到 GO。

## 3. 两层执行顺序

### 3.1 外部 manifest 层

先复用 `pending_release_gates()` 对 App Store Connect、法律/运营、公开 URL、签名、上传与发行范围进行完整盘点。如果任何字段未完成：

- 输出精确字段路径和分组数量；
- 四个最终检查全部标为 `skipped`；
- 不发起公网请求；
- 不尝试打开不存在的 signed archive；
- 返回退出码 2，权威结论为 HOLD。

跳过在这里是安全前置条件未满足，不是通过。

### 3.2 最终证据层

只有 manifest 零 pending 后，才按同一候选连续执行：

| 检查名 | 权威工具 | 必须证明 |
| --- | --- | --- |
| `submission_manifest_strict` | `validate_app_store_submission.py --strict` | 账号/产品页/审核/问卷/价格/地区/上传字段一致；archive 存在且其 App 为 Distribution 模式 |
| `public_pages_live` | `validate_public_release_pages.py --require-app-links --check-live-urls` | App 内两条 HTTPS URL 与 manifest 一致，公网返回 200 HTML 且含预期中文内容 |
| `archive_content` | `validate_ios_archive.py` | 版本、build、arm64、隐私清单、图标、离线代码、动态库和遗留符号符合候选 |
| `signed_app_distribution` | `validate_ios_signed_app.py --mode distribution` | strict codesign、Distribution Authority、Team/Bundle ID、leaf/Profile、有效期、entitlements 与 App Store Profile 模式一致 |

每项都在独立进程运行并记录退出码；最终报告不会因为前一项通过而隐藏后一项失败。

## 4. 当前 30 个外部门槛

本机实测分组如下：

| 分组 | 数量 | 当前缺口 |
| --- | ---: | --- |
| `app_record` | 4 | Apple ID、SKU、Bundle ID 团队归属、商店名称可用性 |
| `product_page` | 6 | 隐私/支持 URL、版权、分类确认、游戏子类、价格 |
| `review` | 4 | 联系人姓名、邮箱、电话、版本选择 build |
| `privacy` | 2 | 后台问卷提交、TestFlight 网络复核 |
| `age_rating` | 4 | 后台问卷、计算结果、内容负责人确认、儿童选项 |
| `export_compliance` | 1 | 后台出口合规问卷 |
| `distribution` | 6 | Team、Distribution identity、App Store Profile、签名 archive、上传 build ID、上传校验 |
| `availability` | 3 | 地区、地区确认、发布方式 |
| **合计** | **30** | 任一项未完成都保持 HOLD |

当前报告摘要：

```text
pending_gate_count: 30
ready_for_submission: false
submission_manifest_strict: skipped
public_pages_live: skipped
archive_content: skipped
signed_app_distribution: skipped
audit_errors: []
exit: 2
```

这次运行没有网络访问，因为真实 URL 与其他前置字段尚未完成。

## 5. 防绕过规则

- `checks=[]` 不得通过；
- “元数据通过、二进制失败”不得通过；
- “三项通过、一项 skipped”不得通过；
- signed archive 必须位于仓库工作区、后缀为 `.xcarchive`、Info 中存在有效 ApplicationPath；
- 最终 App 必须位于该 archive 内，不能通过 manifest 指向另一个独立 App；
- `--strict` 自身调用 `validate_ios_signed_app.py --mode distribution`，Development archive 无法仅凭 codesign 有效蒙混通过；
- 统一门禁没有 `--skip-live`、`--allow-development` 或“忽略 pending”选项。

## 6. 外部负责人交接顺序

1. 先补齐真实主体、联系信息、公开 URL、产品页与问卷，不写示例或占位值；
2. 在正确 Apple Team 下完成 App 记录与 Distribution/App Store 签名链；
3. 生成签名 archive，把其工作区相对路径写入 manifest；
4. 上传并保存 App Store Connect build ID 与上传校验结果；
5. 用该 TestFlight build 完成网络和真机复核，再填写相应状态；
6. 确认价格、地区、发布方式和地区合规；
7. 运行唯一最终命令；只有退出 0 和 `ready_for_submission: true` 才进入提交。

工具不会登录 App Store Connect、不会申请证书、不会创建 App 记录，也不会把人工确认字段自动改为 true。

## 7. 自动回归

`test_final_app_store_gate.py` 覆盖：

- pending 字段按业务域稳定分组；
- 空最终检查列表不能 GO；
- 任一 failed 不能 GO；
- 任一 skipped 不能 GO；
- 全部 passed 才能 GO。

发行静态门禁还锁定四个最终检查名称，以及独立 `--strict` 必须调用 Distribution 产物验证器。

## 8. 本轮回归验收

| 验收项 | 结果 |
| --- | --- |
| 统一门禁纯本地专项 | 通过；分组、空检查、failed、skipped 与全通过聚合规则均覆盖 |
| 当前真实最终门禁 | 按预期 HOLD；30 pending、4 skipped、0 audit error、退出码 2 |
| 完整发行门禁 | 通过；Stage 0–4 全部完成，29 项登记问题审计一致，包含统一最终门禁专项、静态/商店/公网/提交准备检查 |
| Release 模拟器运行 | 通过；专用模拟器安装并启动，PID `46348` 在启动 21 秒后仍存活 |
| Release device compile | 通过；`CONFIGURATION=Release ./xcode.sh ios-device` 完成 |
| 无签名 archive 内容检查 | 通过；`build/archives/NewPirate-final-gate.xcarchive` 生成并通过 `validate_ios_archive.py` |
