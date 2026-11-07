# owoDE Monet 色彩系统

owoDE 的 Material Expressive 感不能只靠圆角和动效。颜色也需要围绕当前壁纸
形成连续的层级：顶栏、Temporal Capsule、Dock、面板和强调按钮应像同一个
环境中的材质，而不是各自带一套蓝色或紫色。

## 当前实现

`design/Owo/Visuals/MonetPalette.qml` 为每张内置壁纸提供一组离线、可审阅的种子色板。它把
壁纸的主要气质映射为 Material 风格的语义角色：

- `primary` / `onPrimary`
- `primaryContainer`
- `secondary` / `secondaryContainer`
- `tertiary` / `tertiaryContainer`
- `background`
- `surface` / `surfaceContainer` / `surfaceElevated`
- `outline`
- `textPrimary` / `textSecondary`
- `warning` / `success`

`Tokens.qml` 只消费这些角色。切换 `snow`、`abstract`、`quiet` 或 `kemono`
壁纸时，普通胶囊、顶栏分组、System Island、面板表面和强调色会同步改变。
用户手动选择 teal、lilac 或 apricot 时，仍然保留显式强调色控制。

## 借鉴 Hyprland shell 的部分

我们检查了 [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)、
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) 和
[Noctalia](https://github.com/noctalia-dev/noctalia-shell) 的公开色彩工作流。
真正值得借鉴的是它们的时序和筛选原则：壁纸改变时只生成一次颜色；先量化图像；
在大面积天空、墙面等中性区域之外，优先选择“有足够占比且更有色”的稳定主种子；
随后把语义角色一次性写入 shell、GTK/Qt 适配层和应用模板。Noctalia 的文档也把
“壁纸色 → Material You 色板 → 应用模板”作为完整链路说明。

owoDE 只借鉴这个产品级思路，不复制它们的 QML、脚本、模板或着色器，也不引入
Quickshell、Matugen 或其它 shell 运行时依赖。相关来源和许可证边界记录在
`docs/reuse/`；owoDE 自己的角色生成入口是 `MonetPalette.paletteForSeed()`。

## owoDE 的取色入口

`tools/extract-monet-seed.py` 是一个无第三方依赖的离线取色器，支持 PNG、PPM/PNM
和含十六进制颜色的 SVG。它使用确定性的 `quantized-prominent-chroma-v1` 规则：

1. 量化颜色，抹平压缩噪声；
2. 排除大面积低饱和中性色；
3. 按占比、饱和度和可用明度评分；
4. 输出一个稳定的 `#RRGGBB` 种子和可审阅的 JSON 元数据。

例如：

```bash
python3 tools/extract-monet-seed.py ~/Pictures/wallpaper.png --json
```

`MonetPalette.qml` 再把种子映射到 `primary`、`secondary`、`tertiary`、容器、表面、
轮廓、文字和状态角色。内置雪山、抽象、静谧和 Kemono 壁纸仍使用经过视觉审阅的
固定种子，因此当前启动不会因为取色而产生网络请求、持续采样或随机闪烁。真实用户
壁纸接入时应在壁纸切换事件中后台运行取色器，成功后原子替换缓存，失败就回退到
当前壁纸的固定种子。

## 为什么先使用种子色

第一版必须离线、稳定且不会在静态桌面上启动持续取样或重绘循环。当前色板是
根据随项目发布的原创 SVG 壁纸预先审阅的 Monet 风格种子，不会假装自己已经
完成了任意用户壁纸的实时像素分析。这样可以先把视觉层级固定下来，同时保留
未来接入缓存式图像取色后端的接口。

后续真实取色后端应满足：

1. 只在壁纸更换或用户明确请求时运行一次；
2. 在后台生成受限数量的主色、辅助色和明暗色阶；
3. 通过同一组语义角色进入 `Tokens`，不让 QML 组件直接消费原始 RGB；
4. 取色失败时回退到当前壁纸的内置种子色板；
5. 保证文字、焦点环和错误状态的对比度，不为了追求鲜艳而牺牲可读性。

这套方案借鉴 Material Expressive 的角色化色彩和动态层级，但不复制 Google
组件或其默认配色。owoDE 的识别仍来自雪山、柔和蓝绿、少量紫粉和清晰的
胶囊秩序。
