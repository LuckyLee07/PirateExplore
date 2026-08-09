# UI 3.2 图标源文件

本目录是第一章 UI 3.2 航海仪表图标的唯一设计源。运行时 PNG 位于：

`bin/res/assets/Images/V2/Icons/`

## 绘制规范

- 画布：`64 × 64`；
- 图形：白色单色描边，透明背景；
- 主描边：`4 px`，圆角端点与圆角连接；
- 细节只通过降低透明度区分，不在源文件中固化语义色；
- 运行时由 `V2UITheme` 按资源、阶段或阵营着色；
- 在 16～20 point 显示尺寸下仍应能靠轮廓区分；
- 不混用旧版写实装备图标、彩色方框或另一套描边粗细。

## 语义映射

| 文件 | 用途 |
| --- | --- |
| `resource-gold.svg` | 金币 |
| `resource-timber.svg` | 木材 |
| `resource-iron.svg` | 铁料 |
| `resource-provisions.svg` | 补给 |
| `resource-rune.svg` | 符文尘 |
| `battle-hull.svg` | 我方/敌方船体 |
| `battle-deck.svg` | 敌方甲板破坏 |
| `battle-cannon.svg` | 敌方火炮压制 |
| `battle-crew.svg` | 我方/敌方接舷队 |

## 导出

需要 ImageMagick 6 或等价 SVG 渲染器。修改 SVG 后，从项目根目录执行：

```bash
for source in design/v2/assets/icons/*.svg; do
  name=${source##*/}
  convert -background none -density 192 "$source" -resize 64x64 \
    "bin/res/assets/Images/V2/Icons/${name%.svg}.png"
done
```

导出后运行 `python3 tools/v2/validate_ui3_style.py`，校验 9 组 SVG/PNG 配对与 PNG 尺寸。
