# 《海上探险家》App Store 元数据草案（简体中文）

日期：2026-07-16

状态：文案、视觉素材、年龄分级事实清单和机器校验已准备；外部 URL、账号字段、签名与后台问卷未完成，不能直接提交

机器可读的权威提交清单见 [`app-store-submission-manifest.json`](app-store-submission-manifest.json)，详细字段、年龄分级、账号/签名审计与后台操作顺序见 [`app-store-connect-compliance-iteration-1.md`](app-store-connect-compliance-iteration-1.md)。以下正文用于人工阅读，实际复制到后台时以 `metadata/` 下通过校验的纯文本文件为准。

## 1. 基础字段

| 字段 | 草案 | 提交前动作 |
| --- | --- | --- |
| App 名称 | 海上探险家 | 在 App Store Connect 验证名称可用性 |
| 副标题 | 航海探索与船队成长 | 校验后台字符限制与检索表现 |
| Bundle ID | `com.fancyGame.NewPirate` | 在正确开发者团队中确认归属；首次上传后不可更改 |
| 版本 | 2.0.0 | 与候选 archive 一致 |
| Build | 1 | 每次重传递增 |
| 主分类 | 游戏（准备值） | 在后台确认主分类与游戏子分类，不能把准备值当作账号侧确认 |
| 价格 | 未决定 | 外测 GO 后做市场验证，不在本阶段虚构价格 |
| 隐私政策 URL | **待提供，`V2-018 / P0` 阻塞** | 页面模板已完成；确认真实主体/邮箱、部署并通过公网检查后填写 |
| 支持 URL | **待提供，`V2-018 / P0` 阻塞** | 支持模板已完成；必须提供受监控的真实邮箱和有效公开页面 |
| Marketing URL | 可选，待定 | 没有正式站点时保持空白 |

## 2. 宣传文本

打开受诅咒的水晶瓶，驶入迷雾海域。选择航线、迎战敌船、完成接舷，带着第一枚符文线索返航升级。

提交源：[`metadata/zh-CN/promotional-text.txt`](metadata/zh-CN/promotional-text.txt)，当前 46 字符，限制 170 字符。

## 3. 描述草案

一只封印着海盗王与掠夺者号的水晶瓶，把你卷入了未知海域。

在《海上探险家》中，你将整备船只与补给，沿羊皮纸海图探索迷雾，面对
会改变航程结果的事件与选择。炮火不会结束战斗：击破敌船甲板后，你还要
带领船员登船接舷，把舰炮阶段创造的优势带入近身交锋。

第一章体验包括：

- 在安全与风险航线之间作出选择；
- 探索迷雾、处理海上事件并管理有限补给；
- 经历舰炮战与接舷战相连的双阶段战斗；
- 寻找散落的封印符文，揭开海盗王诅咒；
- 返港修复和升级船只，为下一次远航做准备。

当前版本聚焦完整的第一章冒险，不包含广告、抽卡、钻石商城或付费复活。
你的航线选择、战斗结果和升级决定共同塑造这次远航。

## 4. 关键词草案

海盗冒险,远洋航海,海上战斗,迷雾探索,船队成长,接舷战斗,符文剧情

提交源：[`metadata/zh-CN/keywords.txt`](metadata/zh-CN/keywords.txt)，当前 90 UTF-8 字节，各词多于 2 个字符。提交前仍需复核本地化检索效果；不要堆砌竞品名称或无法兑现的功能。

## 5. 审核备注草案

可复制的完整审核路径见 [`metadata/review-notes.zh-CN.txt`](metadata/review-notes.zh-CN.txt)，当前 1261 UTF-8 字节，覆盖普通玩家入口、第一章闭环、隐私/支持入口、无账号、无广告、无内购和本地存档边界。若提交版本范围发生变化，必须重写并重新校验，不能沿用旧备注。

## 6. App Privacy 草案

基于当前 V2 候选代码与隐私清单：

- Tracking：No；
- Data Collection：No data collected；
- 本地用途：`NSUserDefaults` 保存本地设置/进度；应用包内音频解码会访问文件
  时间戳；
- 不包含 IDFA、AdSupport、广告 SDK、内购 SDK 或分析/崩溃上报 SDK；
- 当前 iOS 候选已移除旧 curl/OpenSSL、WebSocket、XMLHttpRequest 和 LuaSocket，
  第一章运行只读取应用包与本地存档。

这不是后台问卷的最终提交答案。签名 TestFlight 包需要做网络流量复核，且
隐私政策 URL 必须说明本地存档、联系渠道以及未来版本新增数据能力时的更新机制。
页面模板、生成命令、App 内入口和最终验收矩阵见
[`privacy-support-publication-iteration-1.md`](privacy-support-publication-iteration-1.md)。

## 7. 年龄分级与内容说明

逐项事实和证据见 [`age-rating-content-inventory.json`](age-rating-content-inventory.json)。当前按保守口径准备：

- 卡通/奇幻暴力：Frequent；
- 枪械或其他武器：Frequent；
- 恐怖或恐惧主题：Frequent；
- 写实暴力、性内容、赌博、Loot Boxes、UGC、聊天和广告：None。

按 Apple 当前 iOS 26 定义，预期最低等级为 **13+**。这是防止低报的准备推断，不是后台结果；主观频率仍需内容负责人确认，最终等级只能以 App Store Connect 问卷计算为准。“Made for Kids”保持未选择，不能自动代填。

## 8. 截图与图标交付要求

已交付截图的前三张依次表达：

1. 探索海域：船只、迷雾、岛屿、航线和宝藏目标；
2. 海上战斗：舰炮结果如何影响接舷战；
3. 返港成长：修复、升级和下一航程目标。

第四张补充“符文线索与水晶瓶诅咒”。两个设备组均已交付：

- iPhone 6.9 英寸：4 张 1320 × 2868；
- iPad 13 英寸：4 张 2064 × 2752；
- 全部为简体中文玩家展示、8-bit RGB PNG，无 Alpha；
- 文件清单与构建证据见 [`app-store-screenshots/manifest.json`](app-store-screenshots/manifest.json)。

V2 图标已定稿为“水晶瓶中的黑帆海盗船”，采用深青、墨黑、旧金和单点珊瑚红，
与瓶中世界策划和现有诅咒海域美术一致。1024 图和全部 catalog 槽位均无 Alpha；
完整设计/生成/筛选/截图记录见
[`app-store-assets-iteration-1.md`](app-store-assets-iteration-1.md)。

## 9. 提交前核对

- [ ] 名称和副标题在后台可用；
- [ ] 描述与最终可达功能一致；
- [ ] 隐私政策 URL、支持 URL 可公开访问；
- [ ] 隐私问卷与签名包网络行为一致；
- [ ] 年龄分级和出口合规问卷完成；
- [x] iPhone 6.9 英寸与 iPad 13 英寸截图无 QA 信息并通过内部视觉评审；
- [x] App Icon 视觉定稿且 1024 图无透明通道；
- [ ] Review Notes 与最终构建一致；
- [ ] Bundle ID、版本和 build number 与上传包一致。

## 10. 自动校验

```bash
# 仓库内准备态：验证文本限制、工程一致性、隐私、年龄分级和素材清单
python3 tools/release/validate_app_store_submission.py

# 最终提交态：外部账号、URL、签名、上传、问卷、价格和地区也必须全部完成
python3 tools/release/validate_app_store_submission.py --strict
```

当前第一条通过，第二条按预期失败并列出 30 个外部门槛；这不是工具故障，而是上线 HOLD 的机器证据。
