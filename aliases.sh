# awesome-rust-tools - 非冲突快捷别名（可选）
#
# 重要约定：
#   原 Linux 命令保持原名（如 find、cat、grep、ls）
#   Rust 重写版本用 [tool]-rs 别名访问（如 find-rs、cat-rs、grep-rs、ls-rs）
#   两者并存，互不影响
#
# 用法：
#   echo 'source /path/to/awesome-rust-tools/examples/aliases.sh' >> ~/.bashrc
#   重新打开终端即可
#
# 如果你不想用任何别名，仅需确保 ~/.local/bin 在 PATH 中，
# 然后直接用 find-rs / cat-rs / grep-rs / ls-rs 即可。

# ===== 防御：检查 [tool]-rs 已安装 =====
# 如果 shim 缺失则提示用户（不强制）
_require_rs() {
    local name="$1"
    if ! command -v "${name}-rs" &>/dev/null; then
        echo "[awesome-rust-tools] 警告: ${name}-rs 未安装，请先运行 ./install.sh" >&2
        return 1
    fi
}

# ===== 用户可用的快捷函数（非 alias，避免与原命令冲突）=====

# 用 rust 版 ls 临时查看（不影响原 ls）
rls() { _require_rs ls && ls-rs "$@"; }
# 用 rust 版 cat 临时查看
rcat() { _require_rs cat && cat-rs "$@"; }
# 用 rust 版 find 临时搜索
rfind() { _require_rs find && find-rs "$@"; }
# 用 rust 版 grep 临时搜索
rgrep() { _require_rs grep && grep-rs "$@"; }
# 用 rust 版 ps 临时列出
rps() { _require_rs ps && ps-rs "$@"; }
# 用 rust 版 du 临时分析
rdu() { _require_rs du && du-rs "$@"; }
# 用 rust 版 diff 临时对比
rdiff() { _require_rs diff && diff-rs "$@"; }
# 用 rust 版 sed 临时替换
rsed() { _require_rs sed && sed-rs "$@"; }
# 用 rust 版 jq 临时处理 JSON
rjq() { _require_rs jq && jq-rs "$@"; }
# 用 rust 版 time 临时测时
rtime() { _require_rs time && time-rs "$@"; }
# 用 rust 版 top 临时监控
rtop() { _require_rs top && top-rs "$@"; }
# 用 rust 版 kill 临时杀进程
rkill() { _require_rs kill && kill-rs "$@"; }
# 用 rust 版 cut 临时切列
rcut() { _require_rs cut && cut-rs "$@"; }
# 用 rust 版 uniq 临时去重
runiq() { _require_rs uniq && uniq-rs "$@"; }
# 用 rust 版 hexdump 临时看二进制
rhex() { _require_rs hexdump && hexdump-rs "$@"; }
# 用 rust 版 traceroute 临时追踪
rtrace() { _require_rs traceroute && traceroute-rs "$@"; }
# 用 rust 版 tldr 临时查手册
rtldr() { _require_rs tldr && tldr-rs "$@"; }
# 用 rust 版 xdg-open 临时打开文件
ropen() { _require_rs xdg-open && xdg-open-rs "$@"; }

# ===== 显式调用原命令（覆盖同名 alias 时用）=====
# 假设你之前 source 了别人的 alias 把 find 指到 fd，可以这样取回原版：
#   command find /            # 跳过 alias 和 function
#   \find /                   # 跳过 alias
#   /usr/bin/find /           # 绝对路径
#
# 我们这个文件不创建任何与原命令同名的 alias，\
#   所以你输入 find 时永远是 GNU find，输入 find-rs 时永远是 rust fd。

# ===== 验证 =====
# 安装并 source 此文件后：
#   type find          # 应指向 /usr/bin/find (原版)
#   type find-rs       # 应指向 ~/.local/bin/find-rs (rust 版)
#   rfind foo          # 用 rust 版搜索
#   find foo           # 用原版搜索
#   find -h            # GNU find 的帮助
#   find-rs --help     # fd 的帮助

# ===== 一些有用的 [tool]-rs 专用 flags（与原工具不同）=====
# fd (find-rs):    -e ext   -- glob by extension; -i  -- case insensitive; -H  -- include hidden
# rg (grep-rs):    -t type  -- type filter (rust, py); --hidden; -C 3  -- 3 lines context
# bat (cat-rs):    -n       -- show line numbers; -A 5  -- after 5 lines; --paging=never
# sd (sed-rs):     sd a b file.txt   -- 替换 (无需 -i)
# delta (diff-rs): git diff | delta  -- pipe from git
# eza (ls-rs):     -l       -- long; -T  -- tree; --git
# procs (ps-rs):   --tree   -- tree view
# btm (top-rs):    类似 htop 的 keybindings
# zoxide (cd-rs):  z foo    -- jump to dir matching foo
