# Cutefish / Debian 包路径

owoDE 的 Debian 包目标是 **Debian 13 (trixie)**，对应当前 Cutefish 项目的
开发基础。Ubuntu 26.04 仍是 owoDE 的首要支持平台；这条路径用于验证在
Cutefish/Debian 系统上安装和运行 Qt 6 预览，不声称替换 Cutefish Shell 或
提供完整的 Cutefish 发行版。

## 云端构建

CNB 使用 `debian:trixie-slim` 任务镜像，安装 Debian 13 的 Qt 6、KDE
Frameworks 6、LayerShellQt 和图形运行时依赖，然后重新配置和编译 owoDE，
最后用 CPack 生成 `.deb`。构建结果会同时附带匹配提交的源码压缩包和
`SHA256SUMS`。

这个任务与 Fedora RPM 构建分开，避免把 Fedora 的 CMake 输出或库依赖带进
Debian 包。Ubuntu 的 CircleCI `packaging-check` 和 `deb-runtime` 仍保留，
继续负责 Ubuntu 26.04 的安装、运行和卸载验收。

## 安装范围

```bash
sha256sum -c SHA256SUMS
sudo apt install ./klde-shell-preview_*.deb
```

包提供 `klde-shell` 预览、桌面文件、owoDE 图标、原创资源和许可证文件；
它不会注册 Cutefish 登录会话，也不会覆盖现有桌面。登录会话、KWin/LayerShellQt
原生表面和真实硬件行为仍需在目标主机上单独验证。

Cutefish 的应用和 FishUI 只作为兼容性参考；owoDE 不复制 Cutefish 源码，
也不把 Cutefish 运行时当作硬依赖。
