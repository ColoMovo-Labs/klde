# Fedora 登录会话：开发快照

目标是生产使用，当前交付仍是开发快照。注册一个登录项并不证明桌面已经达到
生产标准；请按[生产验收表](production-readiness.md)判断进度。

## 安装与进入

下载 **同一成功 CircleCI 提交** 的 `artifacts/fedora-package/`：

- `klde-shell-preview-*.x86_64.rpm`：共享的 shell、Visual Lab 与原生客户端。
- `owode-session-*.noarch.rpm`：独立登录项，依赖精确匹配的 shell 版本。
- `SHA256SUMS` 和 `owode-source-*.tar.gz`：校验与对应源码。

```sh
sha256sum -c SHA256SUMS
sudo dnf install ./klde-shell-preview-*.rpm ./owode-session-*.rpm
start-owode --check
```

保存工作，正常退出当前桌面，在现有 GDM/SDDM 的会话选择器中选择
**owoDE (Wayland, experimental)**。包仅增加
`/usr/share/wayland-sessions/owode.desktop`，不会修改显示管理器、自动登录、
默认会话、niri 配置或现有桌面文件。不要在运行中的桌面终端执行 `start-owode`；
入口会拒绝这种调用。嵌套验证继续使用 `tools/run-owode-session.sh`。

登录入口设置 owoDE 自己的桌面标识，启动发行版 KWin 的 DRM 后端及 Xwayland。
KWin 通过 `--exit-with-session` 在自己的 Wayland/X11 环境中启动
`/usr/libexec/owode-session-client`。客户端使用 LayerShellQt 背景、Ribbon、Dock
与真实 XDG 应用目录，不需要 Plasma Shell。没有修改、复制或派生 KWin 代码。

顶栏电源按钮或快捷设置的会话按钮打开退出确认。确认后只退出当前 owoDE shell，
KWin 按其子会话生命周期退出；没有调用 `loginctl terminate-user`、关机或杀死其他
合成器。取消和 Escape 保留会话。此轮不提供未经验证的真实关机/挂起按钮。

## 回退与日志

退出 owoDE 后在登录管理器重新选择原来的 niri/GNOME/KDE 会话。移除注册项：

```sh
sudo dnf remove owode-session
```

这会删除新增入口和两个脚本，保留预览包及用户配置。若显卡启动失败，可从另一
TTY 登录后移除该包；**不需要**更换显示管理器或改默认会话。
记录 `journalctl --user -b`、显示管理器会话日志、`rpm -q kwin layer-shell-qt`
和对应源码提交。提交公开日志前移除用户名、应用私密内容及设备标识。

## 证据边界

云端验证安装后的注册文件、入口依赖、拒绝替换现有图形会话、真实 KWin 的
`exit-with-session` 路径、安装后的 shell 原生缓冲、Qt Wayland/Xwayland 客户端、
会话 D-Bus 退出以及 socket 清理。普通预览不能调用真实退出。

容器使用私有 D-Bus/运行目录及 Xvfb 嵌套输出；Xvfb 只承载 KWin 视口，X11
测试客户端必须连接 **KWin 内部 Xwayland**。这不能证明 GDM/SDDM 登录、DRM、
多显卡、休眠、锁屏或真实硬件稳定性已经通过。它们仍需 Fedora 目标机/VM 验收。

接口依据：[KWin 6.7 启动实现](https://invent.kde.org/plasma/kwin/-/blob/Plasma/6.7/src/main_wayland.cpp)、
[桌面标识规范](https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html)。
