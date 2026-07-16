# 《海上探险家》V2：隐私政策与玩家支持发布准备（迭代 1）

日期：2026-07-16

版本范围：iOS 2.0.0（build 1）

本轮结论：**仓库内准备与 App 内本地入口已完成；真实主体、联系邮箱、公开 HTTPS 域名和线上可用性尚未提供，`V2-018 / P0` 保持开启，总体上线继续 HOLD。**

## 1. 本文解决什么问题

此前工程已经具备隐私清单和“无跟踪、无收集”的二进制基线，但只有 App Store 元数据草案，没有可托管的隐私政策/支持页面，也没有 V2 玩家可达的隐私与支持入口。旧版设置页还保留了 2015 年前后的公司、QQ群和 QQ 邮箱文字；这些历史信息没有当前权属与可用性证据，不能直接复制到 2.0.0 的公开页面。

本轮把可由仓库完成的工作落地为：

- 与当前候选二进制一致的简体中文隐私政策模板；
- 含真实联系入口占位要求、常见问题和反馈要素的支持页面模板；
- 由真实发行参数生成静态站点的工具；
- 对模板、渲染产物、App 内 URL 和线上页面逐层加严的校验工具；
- V2 首章界面中的“隐私与支持”入口和本地说明；
- 只允许打开经过配置的 HTTPS 页面、拒绝 HTTP/示例域名/空值的保护；
- 可审计的发布步骤、责任人输入和最终关闭条件。

本轮没有编造运营主体、客服邮箱、域名、法律意见或线上部署结果。

## 2. Apple 要求与项目映射

| 官方要求 | 当前项目解释 | 本轮状态 | 最终证据 |
| --- | --- | --- | --- |
| iOS App 需要 Privacy Policy URL | App Store Connect 中必须填写公开可访问页面 | 模板完成，URL 未提供 | 后台字段截图/导出 + 公网 200 响应 |
| App 内应有易于访问的隐私政策入口 | 首章顶栏始终显示“隐私与支持”；本地内容不依赖网络 | 本地入口完成；网页按钮等待真实 URL | 真机点击入口并成功打开同一隐私页 |
| 隐私政策需解释收集、使用、共享、保留/删除与联系渠道 | 当前版本“不收集上传”，但仍说明本地存档、卸载删除、第三方、未来变更和联系方法 | 模板完成，主体/邮箱待核 | 法务/运营确认的最终 HTML |
| Support URL 应通向可联系的支持信息 | 支持页包含受监控邮箱、问题复现要素、隐私页回链 | 模板完成，邮箱/URL 待核 | 实际邮件收发测试 + 公网页面 |
| App Privacy 必须覆盖 App 与第三方实践 | 当前候选无账号、广告、分析、跟踪、内购和第三方数据 SDK | 代码/清单静态基线通过 | 签名 TestFlight 包网络复核 + 后台问卷 |

官方依据：

- [App Review Guidelines 1.5 与 5.1](https://developer.apple.com/app-store/review/guidelines/)
- [App information：Privacy Policy URL](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Platform version information：Support URL](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [App Privacy reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/)
- [Manage App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)

说明：App 内本地说明提升了离线可达性，但在公开 URL 未配置且点击未验证前，不能把 Apple 的外链门槛标记为完成。

## 3. 当前候选的事实基线

本轮页面文字只使用当前代码、资源和隐私清单能够支持的事实：

| 主题 | 2.0.0 当前行为 | 证据位置 |
| --- | --- | --- |
| 账号 | 无注册、登录或云端账号 | V2 首章可达流程与审核备注 |
| 数据收集 | 当前声明为不收集、不上传个人数据 | `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes = []` |
| 跟踪 | 关闭跟踪，无跟踪域名 | `NSPrivacyTracking = false`、空跟踪域名 |
| 本地数据 | 章节进度、资源、船只状态、设置和本地游玩记录保存在本机 | scoped save、`NSUserDefaults` 与本地存档实现 |
| 删除 | 删除并重装应用会删除本地数据；无服务器账号数据删除流程 | 当前无账号/网络服务的发行范围 |
| 商业化 | 不含广告、内购、钻石商城或付费复活 | V2 feature gate 与 iOS target/archive 审计 |
| 第三方数据处理 | 不含广告、分析或崩溃上报 SDK | iOS 工程、framework 和二进制符号审计 |
| 权限 | V2 候选不请求定位、通讯录、相机、麦克风或照片权限 | `Info.plist` 与可达流程 |
| 网络 | iOS 候选移除旧 curl/OpenSSL、WebSocket、XMLHttpRequest、LuaSocket；外链只用于未来隐私/支持页 | 发行静态检查与 archive 审计 |

边界条件：以上结论只适用于当前 2.0.0 候选。若接入账号、联网存档、统计、崩溃上报、广告、内购或新的 SDK，必须先重新做数据盘点，再同步修改代码、隐私清单、网页、App 内文案和 App Store Connect 问卷。

## 4. 历史发行信息审计

`bin/res/scripts/LuaClass/Setting.lua` 中存在“探险科技有限公司”、QQ群 `106134362` 和邮箱 `1976428305@qq.com`。当前仓库没有证据证明：

- 该主体仍是 2.0.0 的合法运营/发行主体；
- 群与邮箱仍由发行团队控制并持续处理支持请求；
- 这些信息可以公开发布并满足当前法务与 App Store 要求。

因此本轮采取的处理是：

1. 不把这些值复制到新模板、V2 玩家文案或元数据；
2. 发行负责人必须从合同、开发者账号或公司登记材料确认真实主体；
3. 支持邮箱必须实际收发测试，并明确维护人；
4. 若确认继续使用历史值，也要把“确认人、确认日期、证据位置”写入发行记录后再生成页面。

旧设置页不在当前 V2 第一章可达流程中，本轮没有为了改文案而扩大旧功能的变更面；发行静态检查会防止未核信息泄露到新的页面和 V2 本地说明。

## 5. 本轮交付物

| 交付物 | 用途 | 是否可直接上线 |
| --- | --- | --- |
| `docs/release/public-pages/templates/privacy-policy.zh-CN.html` | 隐私政策页面源模板 | 否，必须渲染真实参数 |
| `docs/release/public-pages/templates/support.zh-CN.html` | 支持与常见问题页面源模板 | 否，必须渲染真实参数 |
| `docs/release/public-pages/templates/release.css` | 响应式、键盘焦点、减少动态效果的共用样式 | 随渲染结果部署 |
| `tools/release/render_public_release_pages.py` | 校验发行参数并生成 `privacy/`、`support/` 静态站点 | 输入真实值后可生成 |
| `tools/release/validate_public_release_pages.py` | 校验模板、渲染结果、App URL 和线上内容 | 分阶段使用 |
| `bin/res/scripts/LuaClass/V2ReleaseInfo.lua` | App 内本地隐私/支持说明与真实 URL 配置点 | 本地说明已启用，URL 仍为空 |
| `bin/res/scripts/LuaClass/V2ChapterLayer.lua` | 顶栏入口、说明弹层、条件式网页按钮 | 已进入候选代码 |
| `src/NewPirate/client/OpenUrl.mm` | 通过系统浏览器打开页面，仅接受 HTTPS | 已进入候选代码 |

模板中的 `{{...}}` 是构建期变量，不会被允许出现在渲染产物中。App 源码中的两个 URL 当前保持 `nil`，目的是让缺失状态可见并阻止误用示例域名。

## 6. 公开页面内容结构

### 6.1 隐私政策

页面依次覆盖：适用版本与运营主体、是否收集数据、本地数据、删除方式、设备权限、第三方、保留与安全、未来变更和联系方法。它没有把“无收集”误写成“没有任何数据”：本地存档仍被明确说明。

### 6.2 支持页面

页面提供启动、进度/重装、声音和隐私四组常见问题，以及邮件反馈应包含的设备型号、iOS 版本、应用版本、复现步骤和非敏感截图。没有虚构回复时效、客服电话、办公地址或 7×24 服务承诺。

### 6.3 可访问性与移动端

模板包含移动 viewport、语义标题、跳过导航、可见键盘焦点、足够大的正文、单列移动布局和 `prefers-reduced-motion` 处理。最终部署后仍需在 iPhone Safari、iPad Safari和桌面浏览器做视觉与链接检查。

## 7. 发行负责人必须提供的四项真实输入

| 输入 | 接受标准 | 不接受 |
| --- | --- | --- |
| 运营/法律主体 | 与开发者账号和发行权属一致的公开名称 | 昵称、未确认历史公司名、`待定` |
| 支持邮箱 | 可公开、有人维护、完成发送与回复测试 | 示例邮箱、私人邮箱未经授权、无人值守邮箱 |
| HTTPS 基础 URL | 正式控制的公开域名或路径，证书有效 | HTTP、localhost、`.test`、`.invalid`、示例域名 |
| 生效日期 | 最终政策获确认的 `YYYY-MM-DD` 日期 | 生成脚本运行日的无依据代填 |

如所在地法律或 App Store 后台要求地址、电话或其他联系信息，应由法务/运营加入最终页；当前模板没有擅自判断法域。

## 8. 生成、预览与部署

拿到四项真实值后，在仓库根目录运行：

```bash
python3 tools/release/render_public_release_pages.py \
  --legal-name '已确认的运营主体全称' \
  --support-email '已验证的支持邮箱' \
  --base-url '已控制的 HTTPS 站点根地址' \
  --effective-date 'YYYY-MM-DD' \
  --output-dir build/public-release-pages
```

脚本会：

1. 拒绝空主体、非法邮箱、HTTP、localhost 和保留示例域名；
2. HTML 转义所有发行参数；
3. 生成 `privacy/index.html`、`support/index.html` 和 `assets/release.css`；
4. 确认没有未替换变量，两个页面互链且包含邮件入口；
5. 打印应配置到 App 和 App Store Connect 的两个最终 URL。

在部署前可以直接打开 HTML 或用本地静态服务器做布局检查。部署方式不在仓库内强行指定；GitHub Pages、自有静态站点或其他 HTTPS 托管都可以，但必须由有权限的人确认域名、发布权限和持续维护责任。

## 9. App 内 URL 配置

部署并完成公网检查后，把生成工具打印的两个地址写入：

```lua
-- bin/res/scripts/LuaClass/V2ReleaseInfo.lua
PRIVACY_POLICY_URL = "https://已验证站点/.../privacy/",
SUPPORT_URL = "https://已验证站点/.../support/",
```

不要在网页上线前先写 URL；不要用临时跳转、短链或会要求登录的页面。配置后运行：

```bash
# 要求 App 中两个 URL 均为真实 HTTPS 地址
python3 tools/release/validate_public_release_pages.py --require-app-links

# 从当前网络实际请求两个页面，验证 200、HTML 与关键内容
python3 tools/release/validate_public_release_pages.py \
  --require-app-links --check-live-urls
```

当前常规回归只执行模板层校验，因此会通过并明确输出“public URLs remain an external release gate”；最终提交前必须额外执行上面的严格命令。

## 10. 最终验收矩阵

| 序号 | 验收项 | 方法 | 通过条件 |
| --- | --- | --- | --- |
| P-01 | 主体权属 | 账号/合同/法务复核 | 名称一致，有确认记录 |
| P-02 | 支持邮箱 | 外部邮箱发信并由维护人回复 | 收发成功，不退信 |
| P-03 | 页面生成 | 渲染工具 + `--site-dir` 校验 | 无占位符，HTML/CSS 完整 |
| P-04 | 公网可用 | 严格线上检查 | 两个 URL 均 HTTPS、200、无需登录 |
| P-05 | 移动视觉 | iPhone/iPad Safari | 无溢出、遮挡、不可读文本或失效链接 |
| P-06 | App 本地入口 | 真机点击“隐私与支持” | 弹层可读、可关闭、不会误触下层 |
| P-07 | App 外链 | 真机点两个网页按钮 | 系统安全打开正确页面，无 HTTP/错误跳转 |
| P-08 | 文案一致 | 对照最终二进制与隐私清单 | 页面、App、问卷无矛盾 |
| P-09 | App Store 字段 | App Store Connect | Privacy Policy URL 与 Support URL 填写正确 |
| P-10 | TestFlight 网络复核 | 签名候选抓包/系统报告 | 行为与“No Data Collected”答案一致 |
| P-11 | 回归与归档 | 全量脚本、Release 构建、archive 验证 | 全绿且证据归档 |

任一项失败，`V2-018` 不得关闭。尤其不能以“模板已存在”替代公网页面，以“模拟器能显示入口”替代真机系统浏览器验证。

## 11. 本轮自动化门禁

常规发行回归现在包含：

```bash
tools/release/validate_ios_release.sh
```

新增检查包括：

- V2 本地说明覆盖无收集、本地保存、卸载删除和第三方边界；
- V2 本地说明不含未确认旧公司、QQ群、邮箱或示例域名；
- 公开模板变量集合完整且没有偷偷写入旧联系信息；
- 页面包含移动端、键盘焦点和减少动态效果样式；
- App 只接受可发布的 HTTPS 地址；
- 原生外链层拒绝非 HTTPS URL。

## 12. 下一步与责任边界

1. **产品/账号负责人**：确认 2.0.0 的发行主体、Bundle ID 与 App Store Connect App 记录；
2. **运营**：建立并实际维护支持邮箱，确认是否需要地址或电话；
3. **法务/负责人**：审核隐私政策文本、生效日期和适用法域要求；
4. **有托管权限的人**：发布页面并保证 URL 长期稳定；
5. **程序**：写入两个真实 URL、重建 Release 包、执行严格页面校验；
6. **测试**：在真机验证本地弹层、两个外链、重装数据语义和 TestFlight 网络行为；
7. **账号负责人**：填写 Privacy Policy URL、Support URL 和 App Privacy 问卷；
8. **发行负责人**：汇总 P-01～P-11 证据后关闭 `V2-018`。

本轮可提交的只是“发行准备能力”，不是公开页面已经上线的证明。

## 13. 本轮实际回归与视觉验收

### 13.1 公共页面

模板、转义渲染和产物校验全部通过。随后在本地浏览器做响应式复核：

- 375 CSS px 移动视口：正文宽 335 px，支持卡片为单列，无横向溢出；
- 1009 CSS px 桌面视口：正文宽 880 px，支持卡片为两列，无横向溢出；
- 隐私/支持互链、`mailto:`、7 个隐私章节和 4 个支持卡片均存在；
- 首次预览发现 `.shell` 的 `min()` 写法缺少 `calc()`，页面被压成窄条；修正后加入静态回归标记，防止再次退化。

本地预览只证明模板布局，不等同于公网页面已部署。

### 13.2 App 内入口

使用 Release 模拟器产物在 iPhone 17 Pro Max 与 iPad Pro 13-inch 上运行。首次画面复核发现，旧引擎 `LabelTTF` 把两段长文合成一张自动高度纹理时会截掉最后一段；改为“隐私说明 / 支持说明”分页，并为正文设置固定可用高度后复验通过：

- iPhone 6.9 英寸画布 1320 × 2868：隐私说明最后一句完整，按钮不进入正文；
- iPad 13 英寸画布 2064 × 2752：支持说明的联系渠道与敏感信息提醒完整；
- 弹层覆盖全屏并吞掉下层触摸；普通玩家顶栏入口仍可见；
- 未配置真实 URL 时不显示网页按钮，避免玩家打开空值或示例页面；配置后才出现对应的网页按钮。

最终运行证据：

- [`privacy-support-player-iphone.png`](privacy-support-player-iphone.png)
- [`privacy-support-player-ipad.png`](privacy-support-player-ipad.png)

### 13.3 自动化与严格门禁

- `tools/release/validate_ios_release.sh`：阶段 0～4、18 项问题登记、发行静态、商店素材和公共页面模板全部通过；
- `CONFIGURATION=Release ./xcode.sh ios-sim`：arm64 Release 模拟器构建通过；
- `NewPirate-privacy-support-final.xcarchive`：Release arm64 无签名归档已生成，版本、build、隐私清单、动态库、网络/广告/内购遗留符号检查通过；
- `python3 tools/release/validate_public_release_pages.py --require-app-links`：当前按预期失败于两个 URL 尚未配置，证明外部 P0 没有被误关闭；
- 严格公网检查本轮未执行，因为没有真实 URL，不能用本地或虚构页面代替。
