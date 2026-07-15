# V2 阶段 0 验证报告

> 日期：2026-07-16
>
> 结论：通过

## 1. 自动校验

执行：

```bash
tools/v2/validate_phase0.sh
```

结果：

- 全部生产 Lua 文件通过 `luac -p`；
- `V2Config` 功能开关、默认档位、QA 档位和幂等存档命名通过；
- 11 张 V2 源表、46 条记录通过字段、唯一 ID 和外键检查；
- 首章节点数、目标时长、五种资源、四类船员和战斗传递规则通过；
- 9 个运行时旧系统门禁接入点通过检查。

## 2. iOS 模拟器

执行：

```bash
ARCHS=arm64 ./xcode.sh ios-sim
xcrun simctl install <device> "NewPirate iOS.app"
xcrun simctl launch --terminate-running-process <device> com.fancyGame.NewPirate
```

设备：`NewPirate Fresh QA`，iOS 26.2。

结果：

- arm64 模拟器构建成功；
- 安装与启动成功；
- V2 独立存档触发全新水晶瓶开场，没有沿用旧档跳过剧情；
- 应用稳定停留在剧情界面；
- 近期应用日志中未出现 Lua 启动错误或崩溃。

![阶段 0 水晶瓶开场](phase-0-launch.png)

## 3. iOS 设备编译

执行：

```bash
./xcode.sh ios-device
```

结果：arm64、关闭签名的设备编译成功。

## 4. 已知非阻断警告

构建仍报告旧工程技术债：

- iOS 8.0 deployment target 低于当前 Xcode 支持范围；
- LaunchImage 已弃用，应迁移到 launch storyboard；
- 旧静态库缺少 platform load command；
- `OpenUrl.mm` 和部分引擎代码存在悬空指针编译警告；
- UIScene 生命周期后续将成为强制要求。

这些警告没有阻断阶段 0，但必须在正式发行准备前处理。与首章运行稳定性
直接相关的 C++ 警告应在阶段 2 工程治理中优先审计。

## 5. 阶段结论

阶段 0 的设计、数据、功能隔离、存档、自动校验、模拟器启动和设备编译
门槛均已满足，可以提交并进入阶段 1 灰盒首章纵切。
