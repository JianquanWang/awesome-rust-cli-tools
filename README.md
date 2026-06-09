# awesome-rust-cli-tools

**[🇨🇳 跳转到中文说明](#chinese-start)**

## English Version

This repository collects and curates **Rust tools that genuinely replace common Linux/Unix commands** from the awesome-rust-tools list. We expose them under a unified `[tool]-rs` namespace, while **keeping the original Linux commands unchanged**.

Data Source: [unpluggedcoder/awesome-rust-tools](https://github.com/unpluggedcoder/awesome-rust-tools) (155 tools. This project filters 76 of them as Linux command alternatives).

---

## Core Conventions

```
┌────────────────────────────────────────────────────────────────────┐
│  Original Linux commands remain unchanged: find, cat, grep, ls, ps, top are always GNU originals. │
│  Rust rewritten versions use the -rs suffix: find-rs, cat-rs, grep-rs, ls-rs point to the rust implementations. │
│                                                                    │
│  Both coexist and do not interfere.                                 │
│  Use find/grep/cat/ls for the originals; use find-rs/grep-rs/cat-rs/ls-rs for the Rust versions. │
└────────────────────────────────────────────────────────────────────┘
```

Examples:
```bash
find / -name "*.rs"     # Calls GNU find (Original, Unchanged)
find-rs "*.rs"          # Calls rust fd (Faster, default regex, intelligent case sensitivity)

cat README.md           # GNU cat
cat-rs README.md        # bat (Syntax highlighting + git diff)

ls                      # GNU ls
ls-rs                   # eza (Icons + git status)

ps aux                  # GNU ps
ps-rs                   # procs (Color + tree view)
```

**Memory Rule**: Original Command + `-rs` suffix = Its Rust replacement.

---

## Why This Project?

Rust-rewritten CLI tools generally outperform GNU tools in speed, memory efficiency, and safety. However, **the naming convention is fragmented**:
- `fd` (find replacement), `rg` (grep replacement), `bat` (cat replacement) — you must remember 3 new names.
- `dust` / `diskus` / `duat` are all du alternatives — you don't know which one to choose.
- 26 tools replace 19 core Linux commands — the namespace is chaotic.

This project unifies them under the **`[Original Linux Command Name]-rs`** naming scheme, totaling **50** main mappings. **It does not overwrite any of your original commands** — you can use whichever you prefer, and old scripts will not suddenly call the Rust version just because you installed `fd`.

---

## Quick Start

```bash
# 1. Clone or download this repository
git clone https://github.com/<your-user>/awesome-rust-tools.git
cd awesome-rust-tools

# 2. List all mappings
./install.sh --list

# 3. Install one
./install.sh find         # Installs find-rs (which is fd)

# 4. Install all 50 mappings at once
./install.sh --all
```

**No need to `source ~/.bashrc` or restart the terminal**. The shims created by `install.sh` are in `~/.local/bin/`. For Ubuntu 24.04, `~/.local/bin` is already before `/usr/bin` in the default `PATH`. Any new shell opened (new terminal, new SSH, running `bash -c '...'`) will directly use `find-rs`, `grep-rs`, `cat-rs`, etc.

*The only exception*: If your `~/.bashrc`/`~/.zshrc` redefines PATH using `export PATH=...` without placing `~/.local/bin` at the very beginning—then you must `source ~/.bashrc` or restart the terminal.

Verification (No source needed):
```bash
type find-rs     # Should display a path
find-rs --version
```

---

## Installation Script Features

| Feature | Description |
|--------|------------|
| Intelligent Package Manager | Automatically detects apt / dnf / pacman / brew / cargo, selecting by priority. |
| Forced Source | `--source cargo` forces use of `cargo install`. |
| List Only | `--list` lists all tools; `--print-map` prints the mapping table. |
| Dry Run | `--dry-run` only prints commands without execution. |
| Multi-Manager Support | Each tool lists package names for apt/cargo/brew/dnf/pacman. |
| Uninstallation | `./uninstall.sh` removes all `~/.local/bin/[tool]-rs` links. |
| Auto PATH | Automatically writes `~/.local/bin` to the shell rc file. |

```bash
./install.sh --help
```

---

## Naming Rules

**All new commands follow the `<original linux command name>-rs` format, provided they do not conflict with the original command:**

| User Input | Calls | Notes |
|------------|-------|------|
| `find` | **GNU find** | Original command, **always the original version**. |
| `find-rs` | **rust fd** | Project shim, points to `~/.local/bin/find-rs → /usr/bin/fd`. |
| `cat` | **GNU cat** | Original command, **always the original version**. |
| `cat-rs` | **rust bat** | Project shim. |
| `ls` | **GNU ls** | Original command, **always the original version**. |
| `ls-rs` | **rust eza** | Project shim. |

**Implementation Mechanism**: `install.sh` creates symbolic links in `~/.local/bin/`:
```bash
~/.local/bin/find-rs  →  /usr/bin/fd      (or cargo install path)
~/.local/bin/cat-rs   →  /usr/bin/bat
~/.local/bin/ls-rs    →  /usr/bin/eza
...
```
As long as `~/.local/bin` is placed **before** `/usr/bin` in `PATH` (which `install.sh` ensures), when you enter `find-rs`, you run the rust version.

**When multiple Rust tools replace one Linux command**: Only one is chosen as the primary mapping, and the others are recorded in the second half of the README under "Secondary Tools," retaining their original binary names (without forcing the -rs suffix to avoid breaking community habits).

**Special Case — zoxide (cd-rs)**: Unlike other Rust tools, zoxide does not replace `cd` as an independent binary; it works by hooking the `cd` command (frecency-based jump). The project's `cd-rs` shim points to zoxide itself (i.e., `cd-rs query` triggers zoxide jump search), but **it will not take over your `cd` command**. To make `cd` trigger zoxide, please refer to the zoxide documentation:
```bash
# After installing zoxide
echo 'eval "$(zoxide init bash)"' >> ~/.bashrc   # bash
echo 'eval "$(zoxide init zsh)"'  >> ~/.zshrc    # zsh
```
After that, entering `cd some/dir` will be intercepted by zoxide's hook to trigger its jump logic; entering `cd-rs some/dir` directly calls the zoxide binary.

---

## Secondary Tools (Retaining Original Binary Names)

When a Linux command is replaced by multiple Rust tools, only the most widely used one is chosen as the primary mapping. The others are retained under their original binary names (without forcing the -rs suffix to avoid breaking community habits).

Install them via `./install.sh --source cargo <tool>` or directly using package managers.

| Binary | Replaces | Description | Speed Advantage | Size | GitHub |
|--------|----------|-------------|-----------------|------|--------|
| `eva` | `bc` | Calculator REPL | similar to bc | ~2MB | [nerdypepper/eva](https://github.com/nerdypepper/eva) |
| `xsv` | `csvkit` | Fast CSV toolkit | 10-50x faster than csvkit | ~5MB | [BurntSushi/xsv](https://github.com/BurntSushi/xsv) |
| `difftastic`| `diff` | Structural diff (syntax-aware) | similar to diff | ~10MB | [Wilfred/difftastic](https://github.com/Wilfred/difftastic) |
| `diskus` | `du` | Minimal du -sh alternative | 12x faster than du -sh | ~1MB | [sharkdp/diskus](https://github.com/sharkdp/diskus) |
| `dua` | `du` | Disk usage analyzer | parallel walk | ~3MB | [Byron/dua-cli](https://github.com/Byron/dua-cli) |
| `dutree` | `du` | du + tree combined | parallel walk | ~2MB | [nachoparker/dutree](https://github.com/nachoparker/dutree) |
| `fselect` | `find` | Find files with SQL-like queries | similar to find | ~3MB | [jhspetersson/fselect](https://github.com/jhspetersson/fselect) |
| `scout` | `fzf` | Friendly fuzzy finder | similar to fzf | ~2MB | [jhbabon/scout](https://github.com/jhbabon/scout) |
| `sweep` | `fzf` | Interactive search (fzf-inspired) | similar to fzf | ~3MB | [aslpavel/sweep-rs](https://github.com/aslpavel/sweep-rs) |
| `tv` | `fzf` | General purpose fuzzy finder TUI | similar to fzf | ~5MB | [alexpasmantier/television](https://github.com/alexpasmantier/television) |
| `jj` | `git` | Git-compatible VCS (jj-vcs) | 2-10x faster than git | ~10MB | [martinvonz/jj](https://github.com/martinvonz/jj) |
| `igrep` | `grep` | Interactive Grep (rg frontend) | similar to rg | ~3MB | [konradsz/igrep](https://github.com/konradsz/igrep) |
| `repgrep` | `grep` | Interactive ripgrep find-and-replace | similar to rg | ~3MB | [acheronfail/repgrep](https://github.com/acheronfail/repgrep) |
| `hex` | `hexdump` | Futuristic take on hexdump | ~5ms startup | ~2MB | [sitkevij/hex](https://github.com/sitkevij/hex) |
| `jless` | `jq` | JSON viewer (jq+less alt) | similar to jq | ~3MB | [PaulJuliusMartinez/jless](https://github.com/PaulJuliusMartinez/jless) |
| `lsd` | `ls` | Next gen ls command | similar to ls | ~3MB | [Peltoche/lsd](https://github.com/Peltoche/lsd) |
| `mask` | `make` | CLI task runner (markdown) | faster than make on simple tasks | ~2MB | [jacobdeichert/mask](https://github.com/jacobdeichert/mask) |
| `rsftch` | `neofetch` | Lightning fast hardware fetch | ~5-10ms startup | ~2MB | [charklie/rsftch](https://github.com/charklie/rsftch) |
| `rip` | `rm` | Safe rm alternative (no trash) | similar to rm | ~2MB | [nivekuil/rip](https://github.com/nivekuil/rip) |
| `ruplacer` | `sed` | Find and replace in source files | similar to sed | ~2MB | [your-tools/ruplacer](https://github.com/your-tools/ruplacer) |
| `tlrc` | `tldr` | tldr client in Rust | ~10-20ms | ~2MB | [tldr-pages/tlrc](https://github.com/tldr-pages/tlrc) |
| `mprocs` | `tmux` | Run multiple commands in parallel | similar to tmux | ~5MB | [pvolok/mprocs](https://github.com/pvolok/mprocs) |
| `wezterm` | `tmux` | GPU terminal + multiplexer | 50-100ms startup | ~20MB | [wez/wezterm](https://github.com/wez/wezterm) |
| `ytop` | `top` | TUI system monitor (archived) | similar to top | ~5MB | [cjbassi/ytop](https://github.com/cjbassi/ytop) |
| `zenith` | `top` | top/htop with zoom-able charts | similar to top | ~5MB | [bvaisvil/zenith](https://github.com/bvaisvil/zenith) |
| `rio` | `xterm` | GPU terminal emulator | 30-50ms startup | ~5MB | [raphamorim/rio](https://github.com/raphamorim/rio) |

---

## Quantifiable Speedup Overview (speedup vs. original tools)

| Speedup | Tool | Source |
|---------|------------|---------------------------------|
| **18-20x**| flamegraph.pl-rs (inferno) | jonhoo/inferno README |
| **10-20x**| cloc-rs (tokei) | XAMPPRocky/tokei README |
| **5-20x**| brew-rs (zerobrew) | lucasgelfond/zerobrew |
| **4-20x**| grep-rs (rg) | BurntSushi/ripgrep README |
| **5-10x**| find-rs (fd) | sharkdp/fd README |
| **3x** | nmap-rs (rustscan) | RustScan/RustScan README |
| **1.5-3x**| jq-rs (jaq) | 01mf02/jaq README |
| **2-10x**| git-rs (gix) | Byron/gitoxide README |
| **2-5x** | du-rs (dust) | bootandy/dust |

---

## Directory

```
awesome-rust-tools/
├── README.md           # This file (Core Conventions + Full Mapping Table + Speedup Overview)
├── install.sh          # One-click installation script (Package manager detection + shim creation)
├── uninstall.sh        # One-click uninstallation script
├── mappings.yaml       # Tool mapping definition (Data source; apt/cargo/brew/dnf/pacman package names)
├── aliases.sh          # Optional: shorthand functions like rls/rcat/rfind/rgrep
└── .gitignore
```

---

## How to Add New Tools

1.  Edit `mappings.yaml` and add the following structure to the `mappings:` section:
    ```yaml
    - name: foo-rs
      tool: github-user/foo
      binary: foo
      replaces: foo
      desc: Short description
      speed: 5x faster than foo
      mem: 1/2 of foo
      size: ~3MB
      src: github.com/.../README
      apt: foo
      cargo: foo
      brew: foo
      dnf: foo
      pacman: foo
    ```
2.  Submit a Pull Request.

---

## Data Sources

All tools are filtered from [unpluggedcoder/awesome-rust-tools](https://github.com/unpluggedcoder/awesome-rust-tools) (155 tools). This project specifically filters **76** tools that **truly replace one or more Linux/Unix commands** (50 primary + 26 secondary).

**Out of Scope**:
- Standalone TUI tools (e.g., yazi, xplr, btop, broot in explorer mode)
- Editors (e.g., helix, zed, lapce)
- Package and language tools (e.g., cargo, mise features)
- Specialized tools (e.g., ytop, rustdesk, vaultwarden, gittype)
- Libraries, not CLIs (e.g., ratatui, lscolors, fossil)
- AI/dev tools (e.g., forge, octomind, omnigraph)

---

## License

MIT

<a id="chinese-start"></a>
---

# awesome-rust-cli-tools (中文版)

## 中文说明

本项目旨在整理和汇集来自 `awesome-rust-tools` 列表的 **真正替代 Linux/Unix 命令的 Rust 工具**。我们统一将它们暴露在 `[tool]-rs` 命名空间下，但**原 Linux 命令保持原名不变**。

数据源：[unpluggedcoder/awesome-rust-tools](https://github.com/unpluggedcoder/awesome-rust-tools) (共 155 个工具，本项目筛选了其中的 **76 个**作为 Linux 命令的替代品)。

---

## 核心约定

```
┌────────────────────────────────────────────────────────────────────┐
│  原 Linux 命令保持原名：find、cat、grep、ls、ps、top 永远是 GNU 原版。 │
│  Rust 重写版本使用 -rs 后缀：find-rs、cat-rs、grep-rs、ls-rs 指向 rust 实现。 │
│                                                                    │
│  两者并存、互不干扰。                                               │
│  想用原版就用 find/grep/cat/ls；想用 rust 版就用 find-rs/grep-rs/cat-rs/ls-rs。 │
└────────────────────────────────────────────────────────────────────┘
```

举例：
```bash
find / -name "*.rs"     # 调用 GNU find（原版，不变）
find-rs "*.rs"          # 调用 rust fd（更快、默认 regex、智能大小写）

cat README.md           # GNU cat
cat-rs README.md        # bat（语法高亮 + git diff）

ls                      # GNU ls
ls-rs                   # eza（图标 + git 状态）

ps aux                  # GNU ps
ps-rs                   # procs（彩色 + 树状）
```

**记忆规则**：原命令 + `-rs` 后缀 = 它的 Rust 替代品。

---

## 为什么要做这个项目？

Rust 重写的 CLI 工具在速度、内存、安全性方面普遍优于 GNU 工具，但 **命名方式分散**：
- `fd` (find 替代)、`rg` (grep 替代)、`bat` (cat 替代) — 你得记住 3 个新名字。
- `dust` / `diskus` / `duat` 都是 du 替代 — 不知道选哪个。
- 26 个工具替代了 19 个核心 Linux 命令 — 命名空间已经杂乱无章。

本项目统一为 **`[原 linux 命令名]-rs`** 命名，总共有 **50 个**主要映射。**它不会覆盖你任何原始命令** — 你想用哪个就用哪个，老脚本也不会因为安装了 fd 就突然调用 rust 版的 find。

---

## 快速开始

```bash
# 1. 克隆或下载本仓库
git clone https://github.com/<your-user>/awesome-rust-tools.git
cd awesome-rust-tools

# 2. 列出所有映射
./install.sh --list

# 3. 试装一个
./install.sh find         # 安装 find-rs (即 fd)

# 4. 一键安装全部 50 个映射
./install.sh --all
```

**不需要 `source ~/.bashrc` 也不需要重启终端**。`install.sh` 创建的 shim 位于 `~/.local/bin/`。对于 Ubuntu 24.04，`~/.local/bin` 默认在 `/usr/bin` **之前**。任何新打开的 shell（新开 terminal、新 SSH、运行 `bash -c '...'`）都能直接使用 `find-rs`、`grep-rs`、`cat-rs` 等。

*唯一例外*：如果你的 `~/.bashrc`/`~/.zshrc` 使用 `export PATH=...` 重写了 PATH，并且没有将 `~/.local/bin` 放在最前面——那么你需要 `source ~/.bashrc` 或重启终端。

验证（无需 source）：
```bash
type find-rs     # 应显示 path
find-rs --version
```

---

## 安装脚本特性

| 特性 | 说明 |
|--------|------------|
| 智能包管理器 | 自动检测 apt / dnf / pacman / brew / cargo，按优先级选择。 |
| 强制源 | `--source cargo` 强制使用 `cargo install`。 |
| 仅查看 | `--list` 列出所有工具；`--print-map` 打印映射表。 |
| 试运行 | `--dry-run` 只打印命令而不实际执行。 |
| 多包管理器支持 | 每个工具都列出了 apt/cargo/brew/dnf/pacman 五个包的包名。 |
| 反安装 | `./uninstall.sh` 移除所有 `~/.local/bin/[tool]-rs` 链接。 |
| 自动 PATH | 自动将 `~/.local/bin` 写入 shell rc 文件。 |

```bash
./install.sh --help
```

---

## 命名规则

**所有新命令遵循 `<原 linux 命令名>-rs` 格式，且不与原命令冲突：**

| 用户输入 | 调用的是 | 备注 |
|------------|---------|------|
| `find` | **GNU find** | 原命令，**始终是原版**。 |
| `find-rs` | **rust fd** | 项目提供的 shim，指向 `~/.local/bin/find-rs → /usr/bin/fd`。 |
| `cat` | **GNU cat** | 原命令，**始终是原版**。 |
| `cat-rs` | **rust bat** | 项目提供的 shim。 |
| `ls` | **GNU ls** | 原命令，**始终是原版**。 |
| `ls-rs` | **rust eza** | 项目提供的 shim。 |

**实现机制**：`install.sh` 在 `~/.local/bin/` 下创建符号链接：
```bash
~/.local/bin/find-rs  →  /usr/bin/fd      (或 cargo 安装的路径)
~/.local/bin/cat-rs   →  /usr/bin/bat
~/.local/bin/ls-rs    →  /usr/bin/eza
...
```
只要 `~/.local/bin` 在 `PATH` 中比 `/usr/bin` **靠前**（`install.sh` 会保证），你输入 `find-rs` 就会走 rust 版。

**当一个 Linux 命令被多个 Rust 工具替代时，只选其一作为主映射**，其他次选工具保留其原始二进制名（不强制加 -rs 后缀，避免破坏社区习惯）。

**特殊情况 — zoxide (cd-rs)**：与其他 Rust 工具不同，zoxide 不是一个独立二进制替代 `cd`，而是通过 hook `cd` 命令（基于频率的跳转）来实现的。本项目的 `cd-rs` shim 指向 zoxide 本身（即 `cd-rs query` 会触发 zoxide 的跳转查询），但**它不会接管你的 `cd` 命令**。想要让 `cd` 触发 zoxide，请参考 zoxide 文档：
```bash
# 安装 zoxide 后
echo 'eval "$(zoxide init bash)"' >> ~/.bashrc   # bash
echo 'eval "$(zoxide init zsh)"'  >> ~/.zshrc    # zsh
```
之后输入 `cd some/dir` 会被 zoxide hook 拦截，触发其跳转逻辑；输入 `cd-rs some/dir` 直接调用 zoxide 二进制文件。

---

## 次选工具（保留原二进制名）

当一个 Linux 命令被多个 Rust 工具替代时，**主映射**只选择社区使用最广泛的一个，其余则保留原始二进制名。
可以通过 `./install.sh --source cargo <tool>` 或各包管理器直接安装。

| Binary | 替代 | 作用 | 速度优势 | 大小 | GitHub |
|--------|----------|------|----------|------|--------|
| `eva` | `bc` | 计算器 REPL | 类似 bc | ~2MB | [nerdypepper/eva](https://github.com/nerdypepper/eva) |
| `xsv` | `csvkit` | 快速 CSV 工具包 | 比 csvkit 快 10-50 倍 | ~5MB | [BurntSushi/xsv](https://github.com/BurntSushi/xsv) |
| `difftastic`| `diff` | 结构化 diff（语法感知） | 类似 diff | ~10MB | [Wilfred/difftastic](https://github.com/Wilfred/difftastic) |
| `diskus` | `du` | 最小化 du -sh 替代方案 | 比 du -sh 快 12 倍 | ~1MB | [sharkdp/diskus](https://github.com/sharkdp/diskus) |
| `dua` | `du` | 磁盘使用分析器 | 并行遍历 | ~3MB | [Byron/dua-cli](https://github.com/Byron/dua-cli) |
| `dutree` | `du` | du + tree 组合 | 并行遍历 | ~2MB | [nachoparker/dutree](https://github.com/nachoparker/dutree) |
| `fselect` | `find` | 使用 SQL 风格查询查找文件 | 类似 find | ~3MB | [jhspetersson/fselect](https://github.com/jhspetersson/fselect) |
| `scout` | `fzf` | 友好模糊查找器 | 类似 fzf | ~2MB | [jhbabon/scout](https://github.com/jhbabon/scout) |
| `sweep` | `fzf` | 交互式搜索 (fzf 启发) | 类似 fzf | ~3MB | [aslpavel/sweep-rs](https://github.com/aslpavel/sweep-rs) |
| `tv` | `fzf` | 通用模糊查找器 TUI | 类似 fzf | ~5MB | [alexpasmantier/television](https://github.com/alexpasmantier/television) |
| `jj` | `git` | Git 兼容 VCS (jj-vcs) | 比 git 快 2-10 倍 | ~10MB | [martinvonz/jj](https://github.com/martinvonz/jj) |
| `igrep` | `grep` | 交互式 Grep (rg 前端) | 类似 rg | ~3MB | [konradsz/igrep](https://github.com/konradsz/igrep) |
| `repgrep` | `grep` | 交互式 ripgrep 查找和替换 | 类似 rg | ~3MB | [acheronfail/repgrep](https://github.com/acheronfail/repgrep) |
| `hex` | `hexdump` | hexdump 的未来主义版本 | ~5ms 启动 | ~2MB | [sitkevij/hex](https://github.com/sitkevij/hex) |
| `jless` | `jq` | JSON 查看器 (jq+less 替代) | 类似 jq | ~3MB | [PaulJuliusMartinez/jless](https://github.com/PaulJuliusMartinez/jless) |
| `lsd` | `ls` | 下一代 ls 命令 | 类似 ls | ~3MB | [Peltoche/lsd](https://github.com/Peltoche/lsd) |
| `mask` | `make` | CLI 任务运行器 (Markdown) | 对简单任务比 make 快 | ~2MB | [jacobdeichert/mask](https://github.com/jacobdeichert/mask) |
| `rsftch` | `neofetch` | 闪电快速硬件获取 | ~5-10ms 启动 | ~2MB | [charklie/rsftch](https://github.com/charklie/rsftch) |
| `rip` | `rm` | 安全的 rm 替代品（无回收站） | 类似 rm | ~2MB | [nivekuil/rip](https://github.com/nivekuil/rip) |
| `ruplacer` | `sed` | 源文件查找和替换 | 类似 sed | ~2MB | [your-tools/ruplacer](https://github.com/your-tools/ruplacer) |
| `tlrc` | `tldr` | Rust 中的 tldr 客户端 | ~10-20ms | ~2MB | [tldr-pages/tlrc](https://github.com/tldr-pages/tlrc) |
| `mprocs` | `tmux` | 并行运行多个命令 | 类似 tmux | ~5MB | [pvolok/mprocs](https://github.com/pvolok/mprocs) |
| `wezterm` | `tmux` | GPU 终端 + 多路复用器 | 50-100ms 启动 | ~20MB | [wez/wezterm](https://github.com/wez/wezterm) |
| `ytop` | `top` | TUI 系统监视器（已归档） | 类似 top | ~5MB | [cjbassi/ytop](https://github.com/cjbassi/ytop) |
| `zenith` | `top` | 支持缩放图表的 top/htop | 类似 top | ~5MB | [bvaisvil/zenith](https://github.com/bvaisvil/zenith) |
| `rio` | `xterm` | GPU 终端模拟器 | 30-50ms 启动 | ~5MB | [raphamorim/rio](https://github.com/raphamorim/rio) |

---

## 量化优势速览（speedup vs. 原工具）

| 速度提升 | 工具 | 来源 |
|---------|------------|---------------------------------|
| **18-20x**| flamegraph.pl-rs (inferno) | jonhoo/inferno README |
| **10-20x**| cloc-rs (tokei) | XAMPPRocky/tokei README |
| **5-20x**| brew-rs (zerobrew) | lucasgelfond/zerobrew |
| **4-20x**| grep-rs (rg) | BurntSushi/ripgrep README |
| **5-10x**| find-rs (fd) | sharkdp/fd README |
| **3x** | nmap-rs (rustscan) | RustScan/RustScan README |
| **1.5-3x**| jq-rs (jaq) | 01mf02/jaq README |
| **2-10x**| git-rs (gix) | Byron/gitoxide README |
| **2-5x** | du-rs (dust) | bootandy/dust |

---

## 目录

```
awesome-rust-tools/
├── README.md           # 本文件（核心约定 + 完整映射表 + 优势速览）
├── install.sh          # 一键安装脚本（检测包管理器 + 创建 shim）
├── uninstall.sh        # 一键反安装脚本
├── mappings.yaml       # 工具映射定义（数据源；apt/cargo/brew/dnf/pacman 包名）
├── aliases.sh          # 可选：rls/rcat/rfind/rgrep 等不冲突快捷函数
└── .gitignore
```

---

## 如何添加新工具

1.  编辑 `mappings.yaml`，在 `mappings:` 段加入：
    ```yaml
    - name: foo-rs
      tool: github-user/foo
      binary: foo
      replaces: foo
      desc: Short description
      speed: 5x faster than foo
      mem: 1/2 of foo
      size: ~3MB
      src: github.com/.../README
      apt: foo
      cargo: foo
      brew: foo
      dnf: foo
      pacman: foo
    ```
2.  提交 PR。

---

## 数据来源

所有工具均从 [unpluggedcoder/awesome-rust-tools](https://github.com/unpluggedcoder/awesome-rust-tools) (155 个工具) 中筛选。本项目筛选了其中**真正替代一个或多个 Linux/Unix 命令**的 **76 个**（50 主映射 + 26 次选映射）。

**不在本项目范畴内**：
- 独立的 TUI 工具（如 yazi, xplr, btop, broot 的独立 explorer 模式）
- 编辑器（如 helix, zed, lapce）
- 包管理器和语言工具（如 cargo, mise 的部分功能）
- 专用工具（如 ytop, rustdesk, vaultwarden, gittype）
- 库而非 CLI（如 ratatui, lscolors, fossil）
- AI/开发工具（如 forge, octomind, omnigraph）

---

## License

MIT
