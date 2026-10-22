# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-10-22

### 新增

- `ScreenOff.exe`：双击关闭全部显示器（DPMS 关屏），主机不睡眠、后台任务继续；任意鼠标移动或按键即恢复。
- 命令行参数：`-delay N`（0-60 秒，默认 2）、`-method both|broadcast|post`、`-quiet`、`-version`、`-help`；另支持 `<N>` 作为 `-delay N` 的简写。
- 倒计时开始的提示音（默认开启）：2 秒窗口本来是不可见的，没有声音使用者会以为是「点了没反应」而继续动鼠标，把屏幕又点亮点。
- `build.ps1`：用 Windows 自带的 `csc.exe` 编译，`/target:winexe`（无控制台黑框）、`/langversion:5`，同时产出 `ScreenOff.exe` 与 `ScreenOff-v<版本>-win-x64.zip` 两个发版产物并记录 sha256。
- `scripts/diagnose.ps1`：只读体检脚本（睡眠状态、谁在保持显示器唤醒、关屏与睡眠超时、屏幕列表）。
- `scripts/monitor-off.ps1` + `scripts/monitor-off.vbs`：不用 exe 的纯脚本等价实现，附 `-Diagnose`。
- `docs/LESSONS.md`：从需求判定到驱动层坑位的实测记录。

### 变更

无（首个版本）。

### 修复

无（首个版本）。
