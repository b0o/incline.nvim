#!/usr/bin/env bash
set -euo pipefail

declare -g base prog basedir rootdir
base="$(realpath -e "${BASH_SOURCE[0]}")"
prog="$(basename "$base")"
basedir="$(dirname "$base")"
rootdir="$(dirname "$basedir")"

function usage() {
  cat <<EOF
Usage: $prog [opt...] SUITE [..]

Run Mulberry tests.

Options:
  -h         Display usage information
EOF
}

function main() {
  local opt OPTARG
  local -i OPTIND
  while getopts "h" opt "$@"; do
    case "$opt" in
    h)
      usage
      return 0
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  nvim --headless -u NORC --noplugin \
    --cmd "
      lua loadfile('$rootdir/scripts/mulberry.lua')().setup({
        rootdir = '$rootdir',
      }).run({ $([[ $# -gt 0 ]] && printf "'%s'," "$@") })" 2>&1 |
    sed 's/\s*$//'

  echo
}

main "$@"
