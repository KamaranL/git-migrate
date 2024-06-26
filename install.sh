#!/usr/bin/env bash

## install.sh: Installs Git config, hooks, and commands

cry()
{
    [ "${1,,}" == error ] &&
        echo "${1^}: ${@:2}" 1>&2 ||
        echo "${1^}: ${@:2}"
    logger -p local0."$1" -t git-migrate "${@:2}"

    return 0
}

try()
{
    if "$@"; then
        cry debug "$@"
        return 0
    else
        cry error Failed to execute "'$@'"
    fi
}

die()
{
    cry error "$@"
    exit 1
}

# check dependencies
deps=(
    awk
    bc
    cp
    env
    git
    realpath
    rm
)

for dep in "${deps[@]}"; do
    ! which "$dep" >/dev/null 2>&1 &&
        die Missing dependency "'$dep'".
done

# check git version
min_ver=2.32
[[ $(git --version) =~ [0-9]+\.[0-9]+ ]] &&
    git_ver=$BASH_REMATCH
cry info Identified git version as "'$git_ver'".

((!$(bc <<<"$git_ver > $min_ver"))) &&
    die Minimum version of "'$min_ver'" required.

# move current directory if not already moved
dst_dir="$HOME/.config/git"
src_dir="$(realpath .)"
[ "$src_dir" != "$dst_dir" ] && {
    [ ! -d "$dst_dir" ] && try mkdir -p "$dst_dir"

    try cp -Rfp "$src_dir"/ "$dst_dir"
}
dst_dir="${dst_dir/"$HOME"/\~}"

# backup existing global config
old_gcfg="$HOME/.gitconfig"
[ -f "$old_gcfg" ] &&
    try cp -fp "$old_gcfg" "$old_gcfg.bak" &&
    rm -rf "$old_gcfg"

# new global config
gcfg="$dst_dir/conf/main.conf"

# set env vars
[ "$(env | awk -F= '/^GIT_CONFIG_GLOBAL=.*$/ {print $2}')" != "$gcfg" ] &&
    echo export GIT_CONFIG_GLOBAL="$gcfg" >>"$HOME/.bash_profile"
((!$?)) &&
    cry info Set environment variable "'GIT_CONFIG_GLOBAL=$gcfg'". ||
    cry error Failed to set GIT_CONFIG_GLOBAL.
[ "$(env | awk -F= '/^GIT_CONFIG_NOSYSTEM=.*$/ {print $2}')" != "true" ] &&
    echo export GIT_CONFIG_NOSYSTEM=true >>"$HOME/.bash_profile"
((!$?)) &&
    cry info Set environment variable "'GIT_CONFIG_NOSYSTEM=$gcfg'". ||
    cry error Failed to set GIT_CONFIG_NOSYSTEM.

# add commands to PATH
cmd_dir="$dst_dir/commands"
[[ ! $PATH =~ $cmd_dir ]] &&
    echo export PATH="$cmd_dir:\"\$PATH\"" >>"$HOME/.bash_profile"
((!$?)) &&
    cry info Added commands to \$PATH. ||
    cry error Failed to add commands to \$PATH.

cd "${dst_dir/\~/"$HOME"}"

echo "'$src_dir'" can now be removed.

exit 0
