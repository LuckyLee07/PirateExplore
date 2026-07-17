# iOS 最终候选身份闭环迭代 1

日期：2026-07-17

本轮结论：**`V2-040 / P1` 已在仓库内关闭。最终 App Store 门禁不再只检查“某个合法签名 archive”，而是从总体产品 manifest 取得唯一 `release_commit`，从提交 manifest 取得唯一 `marketing_version-build_number`，同时要求 archive 内容与其内部 Distribution App 精确匹配这两个值并拒绝 dirty provenance。当前外部字段仍有 30 项 pending、总体仍有 47 项 pending，因此没有运行签名、上传、真机或账号操作，也没有把工具闭环冒充真实 Distribution 产物通过。**

## 1. 修正原因

此前的最终门禁能证明 archive 版本、架构、隐私清单和签名 App 的 Team/Profile/entitlements 合法，但 `archive_content` 没有传入期望源码提交或候选 ID，`signed_app_distribution` 也没有这组能力。

因此，只要包内提交仍是仓库中某个合法 commit、候选 ID 格式合法，一个旧 archive 理论上可以与手工填写的新 `release_commit`、外测和真机记录拼接。版本/build 相同并不能证明二进制来自同一源码候选。

## 2. 唯一身份来源

最终门禁现在只接受两类权威输入：

- `docs/release/product-launch-manifest.json` 的 `candidate.release_commit`：必须是存在于当前仓库的完整 40 位 clean Git SHA；
- `docs/release/app-store-submission-manifest.json` 的 `candidate.marketing_version` 与 `build_number`：组合成最终候选 ID，例如 `2.0.0-1`。

产品 manifest 自己的 `candidate_id` 必须与该版本/build 完全一致。这样不会再增加一个可以互相矛盾的“源码提交”字段。

## 3. 双层产物校验

零 external pending 后，`final_app_store_gate.py` 对同一个 archive 产品 App 执行：

```text
validate_ios_archive.py <archive>
  --expected-source-commit <release_commit>
  --expected-candidate-id <version-build>
  --require-clean-provenance

validate_ios_signed_app.py <archive app>
  --team-id <confirmed team>
  --mode distribution
  --expected-source-commit <release_commit>
  --expected-candidate-id <version-build>
  --require-clean-provenance
```

archive 的 `ApplicationProperties.ApplicationPath` 还必须精确指向 `Products/Applications` 下唯一的 `.app`。因此内容检查和签名检查不能各自验证两个不同的 App。

签名 App 报告新增 `source_commit` 与 `candidate_id`；包内字段缺失、提交不一致、候选不一致、未知提交或 `-dirty` 都会进入失败列表。签名合法不能覆盖 provenance 失败。

## 4. 自动回归

专项回归覆盖：

1. 合法 Distribution fixture + 正确提交/候选通过；
2. 错误源码提交失败；
3. 错误候选 ID 失败；
4. dirty 提交在 clean 门禁下失败；
5. 产品 manifest 候选与提交版本/build 不一致失败；
6. `release_commit` 缺失或不是完整 clean SHA 失败；
7. archive 内容与签名 App 两条实际命令都携带相同的提交、候选和 clean 参数；
8. 当前 30 个外部字段未完成时仍安全短路为 HOLD，不读取或伪造 Distribution 产物。

完整发行回归继续联合阶段 0～4、原生安全、候选 archive、签名工具、App Store 与总体产品门禁。

## 5. 当前边界

本轮证明的是最终门禁具备“从产品决策到包内身份”的不可省略链路。它没有证明：

- Apple Distribution identity 或 App Store Profile 已存在；
- 已生成真实签名 archive；
- archive 已上传并取得 App Store build ID；
- 同一 build 已完成 TestFlight 真机和两轮外测；
- `release_commit` 已可填写。

这些外部事实继续保持 null/pending。第一章内部样片继续 FROZEN，产品扩建与发行继续 HOLD，不扩建第二海域。
