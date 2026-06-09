#!/usr/bin/env bash
# awesome-rust-tools 反安装脚本
# 移除所有 [tool]-rs 符号链接（不卸载底层 Rust 工具）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPINGS_FILE="${SCRIPT_DIR}/mappings.yaml"
SHIM_DIR="${HOME}/.local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 解析 YAML 主映射的 name 字段
parse_mapping_names() {
    python3 - "$1" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    lines = f.readlines()

def strip_val(v):
    v = v.strip()
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    if v == 'null' or v == '':
        return ''
    return v

# Find mappings section
mappings_start = None
secondary_start = None
for i, line in enumerate(lines):
    if line.startswith('mappings:'):
        mappings_start = i
    elif line.startswith('secondary:'):
        secondary_start = i

# Parse
list_re = re.compile(r'^  - (\w+):\s*(.*)$')
field_re = re.compile(r'^    (\w+):\s*(.*)$')

current = None
group = 'primary'
for i in range(mappings_start, len(lines)):
    line = lines[i].rstrip('\n')
    if i == mappings_start:
        continue
    if secondary_start is not None and i >= secondary_start:
        if current is not None:
            if current.get('name'):
                print(current['name'])
            current = None
        break
    list_match = list_re.match(line)
    if list_match:
        if current is not None and current.get('name'):
            print(current['name'])
        current = {list_match.group(1): strip_val(list_match.group(2))}
        continue
    field_match = field_re.match(line)
    if field_match and current is not None:
        current[field_match.group(1)] = strip_val(field_match.group(2))

if current and current.get('name'):
    print(current['name'])
PYEOF
}

remove_shim() {
    local name="$1"
    local shim_path="${SHIM_DIR}/${name}"
    if [[ -L "$shim_path" ]]; then
        rm -f "$shim_path"
        log_success "已移除: ${shim_path}"
    elif [[ -e "$shim_path" ]]; then
        log_info "非符号链接，跳过: ${shim_path}"
    fi
}

remove_path_line() {
    local rc
    case "${SHELL:-bash}" in
        bash)  rc="${HOME}/.bashrc" ;;
        zsh)   rc="${HOME}/.zshrc"  ;;
        fish)  rc="${HOME}/.config/fish/config.fish" ;;
        *)     rc="${HOME}/.profile" ;;
    esac

    if [[ -f "$rc" ]] && grep -q "awesome-rust-tools PATH" "$rc"; then
        python3 - "$rc" <<'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f:
    content = f.read()
pattern = re.compile(
    r'\n# awesome-rust-tools PATH\n.*?PATH="\$\{HOME\}/\.local/bin:\$\{PATH\}"\n',
    re.DOTALL
)
new_content = pattern.sub('\n', content)
if new_content != content:
    with open(path, 'w') as f:
        f.write(new_content)
    print(f"已清理 {path} 中的 PATH 段")
PYEOF
    fi
}

main() {
    echo "=========================================="
    echo "  awesome-rust-tools 反安装"
    echo "=========================================="
    echo

    if [[ ! -f "$MAPPINGS_FILE" ]]; then
        log_error "未找到 mappings.yaml: ${MAPPINGS_FILE}"
        exit 1
    fi

    if [[ ! -d "$SHIM_DIR" ]]; then
        log_info "${SHIM_DIR} 不存在，无需清理"
        exit 0
    fi

    log_info "从 ${SHIM_DIR} 移除所有 [tool]-rs 符号链接..."

    local count=0
    local names
    names=$(parse_mapping_names "$MAPPINGS_FILE")
    while IFS= read -r name; do
        if [[ -n "$name" ]]; then
            local shim_path="${SHIM_DIR}/${name}"
            if [[ -L "$shim_path" ]]; then
                remove_shim "$name"
                count=$((count + 1))
            fi
        fi
    done <<< "$names"

    remove_path_line

    echo
    log_success "完成！移除了 ${count} 个 shim"
    echo
    echo "注意：底层 Rust 工具（如 fd、rg、bat 等）仍保留在系统中。"
    echo "如需彻底卸载："
    echo "  cargo uninstall <crate>  # 单独卸载"
    echo "  或: apt remove <pkg>"
}

main "$@"
