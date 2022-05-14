#!/usr/bin/env bash
set -euo pipefail

declare -g self prog basedir reporoot
self="$(readlink -e "${BASH_SOURCE[0]}")"
prog="$(basename "$self")"
basedir="$(realpath -m "$self/..")"
reporoot="$(realpath -m "$basedir/..")"

declare -gA targets=(
  [readme]="$reporoot/README.md"
  [help]="$reporoot/doc/incline.txt"
)

function get_authors() {
  local authors
  authors="$(git log --max-parents=0 --format=%an)"
  local -i count
  count="$(git log --format=%an | sort -u | wc -l)"
  if [[ $count -gt 1 ]]; then
    authors+=" and contributors"
  fi
  echo "$authors"
}

function get_default_config() {
  nvim --headless -u NORC --noplugin \
    --cmd "set runtimepath+=$PWD" \
    +'lua vim.fn.writefile(
      vim.split(vim.inspect(require"incline.config".schema:raw()), "\n"),
        "/proc/" .. vim.fn.getpid() .. "/fd/1"
      )' \
    +q
}

function get_version() {
  git describe --tags --abbrev=0
}

function get_copyright_years() {
  local copyright_start
  copyright_start="$(git log --max-parents=0 --max-count=1 --date=format:%Y --format=%cd)" # year of first commit
  echo "$copyright_start$( (($(date +%Y) == copyright_start)) || date +-%Y)"
}

function get_copyright() {
  echo "$(get_copyright_years) $(get_authors)"
}

function target_readme() {
  regex_inline -n 1 '!\\[Version' '\\]' " $(get_version)" |
    md_inline COPYRIGHT "$(get_copyright)" |
    md_section DEFAULT_CONFIG -C lua "require('incline').setup $(get_default_config)"
}

function target_help() {
  regex_inline -n 1 '^Version:\\s+' '$' "$(get_version)" |
    regex_inline -n 1 '^  © ' '$' "$(get_copyright)" |
    regex_section '\\*incline-default-config\\*$' '^-{78}$' ">\n$(get_default_config | sed 's/^/  /')\n<"
}

function target_test() {
  regex_inline -n 2 '!\\[Version' '\\]' " $(get_version)" |
    md_inline COPYRIGHT "$(get_copyright)" |
    md_section DEFAULT_CONFIG -C lua "require('incline').setup $(get_default_config)"
}

function md_section() {
  local name="$1"
  shift

  local -i code=0
  local lang
  local opt OPTARG
  local -i OPTIND
  while getopts "cC:" opt "$@"; do
    case "$opt" in
    c) code=1 ;;
    C) code=1 lang="$OPTARG" ;;
    \?) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  local -a content='\n'
  if [[ $code -eq 1 ]]; then
    content+='```'"${lang:-}\n"
  fi
  content+="$(printf '%s\n' "$@")"
  if [[ $code -eq 1 ]]; then
    content+='\n```'
  fi
  content+='\n'

  regex_section '^<!--\\s*'"$name"'\\s*-->$' '^<!--\\s*/'"$name"'\\s*-->$' "$content"
}

function md_inline() {
  local name="$1"
  shift

  local -i code=0
  local lang
  local opt OPTARG
  local -i OPTIND
  while getopts "c" opt "$@"; do
    case "$opt" in
    c) code=1 ;;
    \?) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  local content="$*"
  if [[ $code -eq 1 ]]; then
    content="\`$content\`"
  fi

  regex_inline '<!--\\s*'"$name"'\\s*-->' '<!--\\s*/'"$name"'\\s*-->' "$content"
}

function regex_section() {
  local start="$1"
  shift
  local end="$1"
  shift
  local content
  content="$(printf '%s\n' "$@")"
  awk -v start="$start" -v end="$end" -v "content=$content" '
    BEGIN {
      d = 0
    }
    {
      if (match($0, start)) {
        d = 1
        print $0
        print content
        next
      }
      if (match($0, end)) {
        d = 0
        print $0
        next
      }
    }
    d == 0 {
      print $0
    }
  '
}

# NOTE: Only supports one replacement per line
function regex_inline() {
  local -i count=0
  local opt OPTARG
  local -i OPTIND
  while getopts "n:" opt "$@"; do
    case "$opt" in
    n) count="$OPTARG" ;;
    \?) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  local start="$1"
  shift
  local end="$1"
  shift
  local content="$*"
  awk \
    -v count="$count" \
    -v content="$content" \
    -v start="$start" \
    -v end="$end" \
    '
      BEGIN { n = 0 }
      (count == 0 || n < count) && $0 ~ "(" start ").*(" end ")" {
        match($0, start)
        l = substr($0, 0, RSTART + RLENGTH - 1)
        rest = substr($0, RSTART + RLENGTH)
        match(rest, end)
        r = substr(rest, RSTART)
        print l content r
        n++
        next
      }
      { print $0 }
    '
}

function main() {
  local opt OPTARG
  local -i OPTIND
  while getopts "h" opt "$@"; do
    case "$opt" in
    h)
      echo "usage: $prog [opt].. [target].." >&2
      return 0
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  local -a targets_selected
  if [[ $# -gt 0 ]]; then
    targets_selected=("$@")
  else
    targets_selected=("${!targets[@]}")
  fi

  local tmp
  tmp="$(mktemp -u)"
  # shellcheck disable=2064
  trap "rm \"$tmp\" &>/dev/null || true" EXIT

  local t
  for t in "${targets_selected[@]}"; do
    [[ -v "targets[$t]" ]] || {
      echo "unknown target: $t" >&2
      return 1
    }
    local target="${targets["$t"]}"
    [[ -e "$target" ]] || {
      echo "target file not found: $target" >&2
      return 1
    }

    local target_fn="target_$t"
    if ! [[ $(type -t "$target_fn") == "function" ]]; then
      echo "unknown target: $t"
      return 1
    fi

    local name
    "$target_fn" <"$target" >"$tmp"
    mv "$tmp" "$target"
  done
}

main "$@"
