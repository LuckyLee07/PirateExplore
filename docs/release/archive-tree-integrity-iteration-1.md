# iOS 候选 archive 全树完整性迭代 1

日期：2026-07-17

本轮结论：**`V2-039 / P1` 已关闭。内部候选记录从 schema 1 升级为 schema 2，新增整个 `.xcarchive` 的规范树摘要；Lua、图片、音频、隐私清单、App、dSYM 或任意其他条目的内容、路径、权限、符号链接目标发生变化，候选反向复验都会失败。mtime 等不影响功能且妨碍复验的文件系统时间不进入摘要。**

## 1. 修正原因

`V2-038` 固定了 App 可执行文件、dSYM DWARF 和 App Info.plist 三个关键产物，但第一章的大量实际逻辑与表现位于 App bundle 的 Lua、PNG、音频和数据资源中。如果只比较三类哈希，替换某个资源文件可能不改变可执行文件与 Info.plist，候选记录仍会表面一致。

因此“候选字节基线”必须覆盖 archive 的完整功能载荷，而不只是 Mach-O 主体。

## 2. 规范树摘要

`archive_tree_fingerprint()` 按 archive 相对路径排序，对每个条目写入 SHA-256 输入：

- 条目类型：普通文件、目录或符号链接；
- UTF-8 相对路径；
- Unix 权限位；
- 规范大小（普通文件为字节数、链接为目标文本字节数、目录为 0）；
- 普通文件的 SHA-256，或符号链接的目标文本。

最终记录：

```json
{
  "archive_tree": {
    "sha256": "2567ec162874654cca62122427176737fe8c51e3d430484c7f1cb6f0c486bc32",
    "entries": 769,
    "file_bytes": 22039977
  }
}
```

目录也进入摘要，所以空目录的新增/删除可见；权限位进入摘要，所以可执行权限变化可见；目录在不同文件系统上可能漂移的实现大小不进入摘要。mtime、ctime、绝对路径和 inode 同样不进入摘要，避免同一内容因复制时间或工作区位置不同而产生无意义漂移。

## 3. schema 2 门禁

候选记录现在强制：

- source commit 必须是完整 40 位、无 `-dirty` 的仓库 commit；
- candidate ID 必须与 marketing version/build 同前缀；
- archive 路径必须是工作区内的相对 `.xcarchive` 路径，拒绝绝对路径和 `..`；
- App/dSYM 哈希、大小与规范 UUID 列表合法且 UUID 一致；
- archive tree 哈希为 64 位小写十六进制，条目数和文件字节数为正整数；
- schema 以外的多余字段被拒绝；
- `--verify-record` 重算所有字段并执行完整对象比较。

## 4. 回归与真实候选复验

专项临时树验证以下任一变化都会改变摘要：

1. Lua 文件内容替换；
2. 文件权限变化；
3. 文件路径重命名；
4. 符号链接目标变化。

记录层另行验证：dirty/短提交、候选与版本不一致、不安全 archive 路径、错误 SHA-256、App/dSYM UUID 不一致、多余字段，以及格式合法但与实际 archive 不同的哈希均失败。

真实 `2.0.0-1-internal` archive 已重新计算并写入 769 个条目、22,039,977 文件字节的树摘要；`--verify-record` 反向复验通过。原有 archive 版本、内容、隐私、架构与遗留符号校验继续通过。

## 5. 边界

该摘要证明本地无签名内部候选的功能载荷没有被静默替换。它不验证 Apple code signature、provisioning profile、App Store receipt 或上传后的 TestFlight build；这些仍由 Distribution 产物、真机和最终总体门禁负责。

第一章继续 FROZEN，阶段 4 和总体上线继续 HOLD；本轮不修改玩家内容、数值、资源或存档 schema。
