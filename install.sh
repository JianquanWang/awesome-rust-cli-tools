#!/usr/bin/env bash
# awesome-rust-tools 一键安装脚本
# 用法:
#   ./install.sh                  # 交互式选择
#   ./install.sh --all            # 安装所有 [tool]-rs 映射
#   ./install.sh find grep cat    # 只安装指定工具
#   ./install.sh --list           # 列出所有可用工具
#   ./install.sh --source cargo   # 强制使用 cargo 安装
#   ./install.sh --source apt     # 强制使用 apt 安装
#   ./install.sh --print-map      # 打印 [tool]-rs 映射表
#
# 命名规则: 所有新命令满足 [tool]-rs 格式
# 安装后会在 ~/.local/bin 创建符号链接: [tool]-rs -> [binary]

set -euo pipefail

# ===== 常量 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPINGS_FILE="${SCRIPT_DIR}/mappings.yaml"
SHIM_DIR="${HOME}/.local/bin"

# bindgen 修复：Ubuntu 上 cargo install 编译带 C 依赖的 crate（如 hurl/ouch/nushell）
# 时会找不到 stddef.h 等标准头文件。需要告诉 clang/libclang 去哪里找。
# 此变量对所有 bindgen 调用生效，对没 C 依赖的 crate 无影响。
export BINDGEN_EXTRA_CLANG_ARGS="${BINDGEN_EXTRA_CLANG_ARGS:--I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include/x86_64-linux-gnu}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== 工具函数 =====
log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 检测包管理器
# 默认优先使用 cargo：所有 Rust CLI 工具都可通过 cargo install 编译安装，
# 写入 ~/.cargo/bin/，无需 sudo，最可靠也最通用。
# 除非用户通过 --source 显式指定了其他包管理器。
detect_package_manager() {
    if [[ -n "${FORCE_SOURCE:-}" ]]; then
        echo "${FORCE_SOURCE}"
        return
    fi
    if command -v cargo &>/dev/null; then
        echo "cargo"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "none"
    fi
}

# 检测 shell rc 文件
detect_shell_rc() {
    case "${SHELL:-bash}" in
        bash)  echo "${HOME}/.bashrc" ;;
        zsh)   echo "${HOME}/.zshrc"  ;;
        fish)  echo "${HOME}/.config/fish/config.fish" ;;
        *)     echo "${HOME}/.profile" ;;
    esac
}

# 解析 YAML → 结构化数据 (使用 Python 内置)
# 输出格式: group|name|tool|binary|replaces|desc|apt|cargo|brew|dnf|pacman
parse_mappings() {
    python3 - "$1" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    lines = f.readlines()

def parse_section(start_idx, end_idx, group_name):
    """Parse a YAML section that contains a list of dicts."""
    items = []
    current = None
    field_re = re.compile(r'^    (\w+):\s*(.*)$')
    list_re = re.compile(r'^  - (\w+):\s*(.*)$')

    for line in lines[start_idx:end_idx]:
        line = line.rstrip('\n')
        if line.startswith('#') or not line.strip():
            continue
        list_match = list_re.match(line)
        if list_match:
            if current:
                items.append(current)
            current = {'group': group_name, list_match.group(1): strip_val(list_match.group(2))}
            continue
        field_match = field_re.match(line)
        if field_match and current is not None:
            current[field_match.group(1)] = strip_val(field_match.group(2))
    if current:
        items.append(current)
    return items

def strip_val(v):
    v = v.strip()
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    if v == 'null' or v == '':
        return ''
    return v

# Find section indices
mappings_start = None
secondary_start = None
for i, line in enumerate(lines):
    if line.startswith('mappings:'):
        mappings_start = i
    elif line.startswith('secondary:'):
        secondary_start = i

# Find next top-level after each
def find_section_end(start):
    for i in range(start+1, len(lines)):
        line = lines[i]
        if re.match(r'^[a-zA-Z_]', line) and not line.startswith(' '):
            return i
    return len(lines)

items = []
if mappings_start is not None:
    end = secondary_start if secondary_start else find_section_end(mappings_start)
    items += parse_section(mappings_start, end, 'primary')
if secondary_start is not None:
    items += parse_section(secondary_start, find_section_end(secondary_start), 'secondary')

# Output pipe-separated
for m in items:
    print('|'.join([
        m.get('group', '?'),
        m.get('name', '-'),
        m.get('tool', '-'),
        m.get('binary', '-'),
        m.get('replaces', '-'),
        m.get('desc', '-'),
        m.get('apt', m.get('binary', '-')),
        m.get('cargo', m.get('binary', '-')),
        m.get('brew', m.get('binary', '-')),
        m.get('dnf', m.get('binary', '-')),
        m.get('pacman', m.get('binary', '-')),
    ]))
PYEOF
}

# 获取指定工具的字段
get_field() {
    local name="$1"
    local field="$2"  # 1=group 2=name 3=tool 4=binary 5=replaces 6=desc 7=apt 8=cargo 9=brew 10=dnf 11=pacman
    parse_mappings "$MAPPINGS_FILE" | awk -F'|' -v n="$name" -v col="$field" '$2==n {print $col}'
}

# 列出所有主映射
list_tools() {
    local data
    data=$(parse_mappings "$MAPPINGS_FILE")
    echo -e "${GREEN}=== 主映射 ([tool]-rs 命名) ===${NC}"
    echo "$data" | awk -F'|' '$1=="primary" {printf "  %-20s → %-15s (替代 %s) - %s\n", $2, $4, $5, $6}'
    echo
    echo -e "${YELLOW}=== 次选工具（保留原 binary 名）==${NC}"
    echo "$data" | awk -F'|' '$1=="secondary" {printf "  %-20s binary=%-12s (替代 %s) - %s\n", $3, $4, $5, $6}'
}

# 创建 shim (符号链接)
create_shim() {
    local name="$1"   # e.g. find-rs
    local target="$2" # e.g. fd
    mkdir -p "$SHIM_DIR"
    local shim_path="${SHIM_DIR}/${name}"

    if [[ -L "$shim_path" ]]; then
        local existing_target
        existing_target=$(readlink "$shim_path")
        local real_target
        real_target=$(command -v "$target" 2>/dev/null || true)
        if [[ "$existing_target" == "$real_target" ]]; then
            log_info "shim 已存在: ${name} → ${target}"
            return 0
        fi
    fi

    if command -v "$target" &>/dev/null; then
        ln -sf "$(command -v "$target")" "$shim_path"
        log_success "shim: ${name} → $(command -v "$target")"
    else
        log_warn "${target} 未安装，跳过 shim ${name}"
        return 1
    fi
}

# 包管理器安装函数
install_via_apt() {
    local pkg="$1"
    if dpkg -s "${pkg}" &>/dev/null 2>&1; then
        log_info "apt: ${pkg} 已安装"
        return 0
    fi
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[dry-run] sudo apt-get install -y ${pkg}"
        return 0
    fi
    log_info "apt install ${pkg}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}" 2>&1 | tail -2 || log_warn "apt ${pkg} 失败"
}

install_via_dnf() {
    local pkg="$1"
    if rpm -q "${pkg%%-*}" &>/dev/null 2>&1; then
        log_info "dnf: ${pkg} 已安装"
        return 0
    fi
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[dry-run] sudo dnf install -y ${pkg}"
        return 0
    fi
    log_info "dnf install ${pkg}"
    sudo dnf install -y "${pkg}" 2>&1 | tail -2 || log_warn "dnf ${pkg} 失败"
}

install_via_pacman() {
    local pkg="$1"
    if pacman -Q "${pkg%%-*}" &>/dev/null 2>&1; then
        log_info "pacman: ${pkg} 已安装"
        return 0
    fi
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[dry-run] sudo pacman -S --noconfirm ${pkg}"
        return 0
    fi
    log_info "pacman -S ${pkg}"
    sudo pacman -S --noconfirm "${pkg}" 2>&1 | tail -2 || log_warn "pacman ${pkg} 失败"
}

install_via_brew() {
    local pkg="$1"
    if brew list "${pkg}" &>/dev/null 2>&1; then
        log_info "brew: ${pkg} 已安装"
        return 0
    fi
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[dry-run] brew install ${pkg}"
        return 0
    fi
    log_info "brew install ${pkg}"
    brew install "${pkg}" 2>&1 | tail -3 || log_warn "brew ${pkg} 失败"
}

install_via_cargo() {
    local crate="$1"
    local bin_name="$2"
    local tool_repo="$3"  # GitHub user/repo 形式

    # 如果 bin_name 已是 installed，跳过
    if [[ -n "$bin_name" ]] && command -v "$bin_name" &>/dev/null; then
        log_info "cargo: ${bin_name} 已安装"
        return 0
    fi

    # 决定安装方式：先尝试 crates.io，失败则从 GitHub 编译
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[dry-run] cargo install --locked ${crate}"
        return 0
    fi

    if ! command -v cargo &>/dev/null; then
        log_error "cargo 不可用"
        return 1
    fi

    # 尝试 1: 直接从 crates.io 安装
    log_info "cargo install ${crate} (from crates.io)"
    if cargo install --locked "${crate}" 2>&1 | tail -3; then
        return 0
    fi

    # 尝试 2: 如果有 GitHub 仓库，从 GitHub 安装
    if [[ -n "$tool_repo" && "$tool_repo" != "-" ]]; then
        log_info "crates.io 失败，从 GitHub 安装: ${tool_repo}"
        if cargo install --locked --git "https://github.com/${tool_repo}.git" 2>&1 | tail -3; then
            return 0
        fi
    fi

    log_warn "cargo ${crate} 安装失败"
    return 1
}

# 安装单个 [tool]-rs 映射
install_mapping() {
    local name="$1"  # find-rs
    local binary
    binary=$(get_field "$name" 4)
    local tool_repo
    tool_repo=$(get_field "$name" 3)
    local apt_pkg
    apt_pkg=$(get_field "$name" 7)
    local cargo_pkg
    cargo_pkg=$(get_field "$name" 8)
    local brew_pkg
    brew_pkg=$(get_field "$name" 9)
    local dnf_pkg
    dnf_pkg=$(get_field "$name" 10)
    local pacman_pkg
    pacman_pkg=$(get_field "$name" 11)

    if [[ -z "$binary" || "$binary" == "-" ]]; then
        log_warn "未找到映射: ${name}"
        return 1
    fi

    case "$PKG_MGR" in
        apt)    install_via_apt "$apt_pkg" ;;
        dnf)    install_via_dnf "$dnf_pkg" ;;
        pacman) install_via_pacman "$pacman_pkg" ;;
        brew)   install_via_brew "$brew_pkg" ;;
        cargo)  install_via_cargo "$cargo_pkg" "$binary" "$tool_repo" ;;
        none)
            log_error "无包管理器；请手动安装 ${name}（binary=${binary}）"
            return 1
            ;;
    esac

    # 创建 shim
    create_shim "$name" "$binary"
}

# 添加 ~/.local/bin 到 PATH
# 注意: 必须放在 PATH 最前，这样 find-rs 才能被解析为 ~/.local/bin/find-rs (shim -> rust fd)
#       而不是 /usr/bin/find (GNU find)
#       Ubuntu 24.04 默认 PATH 中 ~/.local/bin 已经在 /usr/bin 之前，所以这个 export 通常是无害的。
ensure_path() {
    if [[ ":$PATH:" != *":${SHIM_DIR}:"* ]]; then
        log_info "将 ${SHIM_DIR} 添加到 PATH（最前）"
        local rc
        rc=$(detect_shell_rc)
        if [[ ! -f "$rc" ]] || ! grep -q "awesome-rust-tools PATH" "$rc" 2>/dev/null; then
            cat >> "$rc" <<EOF

# awesome-rust-tools PATH
# 把 ~/.local/bin 放在 PATH 最前，让 [tool]-rs shim 优先于同名原命令
export PATH="\${HOME}/.local/bin:\${PATH}"
EOF
            log_success "已写入 ${rc}（新开终端生效）"
        fi
    else
        # 检查位置：如果 ~/.local/bin 不在 PATH 第一个，警告
        if [[ "$PATH" != "${SHIM_DIR}:"* ]] && [[ "$PATH" != *"${SHIM_DIR}:"* ]]; then
            log_info "PATH 已包含 ${SHIM_DIR}（位置 OK）"
        fi
    fi
}

# 解析映射名（输入 find → 查找 find-rs）
resolve_name() {
    local input="$1"
    if [[ "$input" == *-rs ]]; then
        echo "$input"
    else
        # 尝试 [input]-rs
        local resolved="${input}-rs"
        local check
        check=$(get_field "$resolved" 4)
        if [[ -n "$check" && "$check" != "-" ]]; then
            echo "$resolved"
        else
            # 回退到原始（次选工具名）
            echo "$input"
        fi
    fi
}

# 验证当前已安装的 shim（不安装任何东西）
verify_install() {
    local data
    data=$(parse_mappings "$MAPPINGS_FILE")

    echo "=========================================="
    echo "  awesome-rust-tools 安装验证"
    echo "=========================================="
    echo
    echo "PATH 顺序（确认 ~/.local/bin 在前）:"
    echo "  ${PATH}" | tr ':' '\n' | head -5 | awk '{print "    "NR". "$0}'
    echo

    local total=0
    local ok=0
    local missing_shim=0
    local missing_bin=0
    local broken=0

    while IFS='|' read -r group name tool binary replaces desc _; do
        [[ "$group" != "primary" ]] && continue
        total=$((total+1))
        local shim="${SHIM_DIR}/${name}"
        local target_bin="${binary}"
        if [[ -L "$shim" ]]; then
            local link_target
            link_target=$(readlink "$shim")
            if command -v "$target_bin" &>/dev/null; then
                local real_path
                real_path=$(command -v "$target_bin")
                if [[ "$link_target" == "$real_path" ]]; then
                    local ver
                    ver=$("$target_bin" --version 2>/dev/null | head -1 | tr -d '\n')
                    echo "  [OK]   ${name}  →  ${target_bin}  (${ver:0:60})"
                    ok=$((ok+1))
                else
                    echo "  [BROKEN] ${name}  shim 指向 ${link_target}，但 ${target_bin} 现在是 ${real_path}"
                    broken=$((broken+1))
                fi
            else
                echo "  [MISSING-BIN] ${name}  shim 在但 ${target_bin} 未安装"
                missing_bin=$((missing_bin+1))
            fi
        else
            echo "  [NO-SHIM]  ${name}  (${target_bin} 未装或未创建 shim)"
            missing_shim=$((missing_shim+1))
        fi
    done <<< "$data"

    echo
    echo "=========================================="
    echo "  ${ok}/${total} OK  |  ${missing_shim} no-shim  |  ${missing_bin} missing-bin  |  ${broken} broken"
    echo "=========================================="
    if [[ "$ok" -eq "$total" ]]; then
        log_success "全部 51 个 [tool]-rs 都已就绪！"
    elif [[ "$ok" -gt 0 ]]; then
        log_warn "部分工具未安装；运行 ./install.sh --all 补齐"
    else
        log_warn "没有 shim；运行 ./install.sh --all 开始安装"
    fi
}

# ===== 横幅 =====
print_banner() {
    cat <<'EOF'
   ____                                ____            __   __
  / __/_ _____  ___  _______  ___ ____/ _ \___ ____  / /__/ /
 / _// // / _ \/ _ \/ __/ _ \/ -_) __/ // / -_) _ \/ / -_/ _ \
/_/  \_,_/ .__/ .__/_/  \___/\__/_/  \___/\__/_//_/_/\__/_//_/
        /_/  /_/
         One-line installer for Rust CLI replacements

EOF
}

show_usage() {
    cat <<EOF
用法: $0 [选项] [工具名...]

选项:
  --all                安装所有 [tool]-rs 映射（51 个）
  --list               列出所有可用工具
  --source MANAGER     强制包管理器: cargo | apt | dnf | pacman | brew
  --no-shim            只安装，不创建 [tool]-rs 符号链接
  --print-map          打印 [tool]-rs 映射表后退出
  --dry-run            只打印将要执行的命令
  --verify             仅验证当前已安装的 shim（不安装新工具）
  -h, --help           显示此帮助

工具名示例:
  find                  # 安装 find-rs (即 fd)
  find grep cat         # 安装多个
  ls                    # 安装 ls-rs (即 eza)

EOF
}

# ===== 主流程 =====
main() {
    print_banner

    if [[ ! -f "$MAPPINGS_FILE" ]]; then
        log_error "未找到 mappings.yaml: ${MAPPINGS_FILE}"
        exit 1
    fi

    local install_all=0
    local no_shim=0
    local dry_run=0
    local verify_only=0
    local tools_to_install=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                install_all=1
                shift
                ;;
            --list)
                list_tools
                exit 0
                ;;
            --print-map)
                printf "%-20s | %-15s | %-12s | %s\n" "映射名" "Binary" "替代" "描述"
                printf "%-20s-+-%-15s-+-%-12s-+-%s\n" "--------------------" "---------------" "------------" "----"
                parse_mappings "$MAPPINGS_FILE" | awk -F'|' '$1=="primary" {printf "%-20s | %-15s | %-12s | %s\n", $2, $4, $5, $6}'
                exit 0
                ;;
            --source)
                FORCE_SOURCE="$2"
                shift 2
                ;;
            --no-shim)
                no_shim=1
                shift
                ;;
            --dry-run)
                dry_run=1
                DRY_RUN=1
                shift
                ;;
            --verify)
                verify_only=1
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "未知选项: $1"
                show_usage
                exit 1
                ;;
            *)
                tools_to_install+=("$(resolve_name "$1")")
                shift
                ;;
        esac
    done

    PKG_MGR=$(detect_package_manager)
    log_info "包管理器: ${PKG_MGR}"

    ensure_path

    if [[ "$install_all" -eq 1 ]]; then
        local data
        data=$(parse_mappings "$MAPPINGS_FILE")
        local all_tools
        all_tools=$(echo "$data" | awk -F'|' '$1=="primary" {print $2}')
        while IFS= read -r t; do
            [[ -n "$t" ]] && tools_to_install+=("$t")
        done <<< "$all_tools"
    fi

    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        log_warn "未指定工具；使用 --all 安装全部，或 --list 查看"
        exit 1
    fi

    log_info "将安装 ${#tools_to_install[@]} 个工具"

    local failed=()
    for t in "${tools_to_install[@]}"; do
        if ! install_mapping "$t"; then
            failed+=("$t")
        fi
    done

    echo
    log_success "完成！"
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "以下工具安装失败: ${failed[*]}"
    fi

    echo
    echo "验证（无需 source，新 shell 直接生效）："
    echo "  ls -la ${SHIM_DIR} | grep -rs   # 看 shim 列表"
    echo "  type find-rs                   # 应显示 ~/.local/bin/find-rs"
    echo "  find-rs --version              # 实际跑一下"
}

main "$@"
