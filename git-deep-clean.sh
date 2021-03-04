#!/bin/bash

# region CLI Params
remote_to_prune=${1:-origin}
# endregion

# region Color Codes
BLUE=${BLUE-'\033[0;34m'}
NC=${NC-'\033[0m'}
PURPLE=${PURPLE-'\033[0;35m'}
RED=${RED-'\033[0;31m'}
# endregion

# region Script Info & Convenience Functions
alias_name="dc"
install_location="$HOME/.local/bin"
installed_version="0.0.1"
git_repo="marier-nico/git-deep-clean"

get_latest_tag() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'
}

semver_le() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

semver_lt() {
    [ "$1" = "$2" ] && return 1 || semver_le $1 $2
}

info() {
    printf "${BLUE}info${NC} $1\n"
}

error() {
    printf "${RED}error${NC} $1\n"
}
# endregion

# region Auto Update
run_update() {
    info "Downloading install script for release ${PURPLE}$latest_tag${NC}"

    export ALIAS_NAME="$alias_name"
    export INSTALL_LOCATION="$install_location"
    export GIT_REPO="$git_repo"
    export INSTALL_VERSION="$1"
    curl --silent "https://raw.githubusercontent.com/$git_repo/$1/install.sh" | sh
    unset ALIAS_NAME INSTALL_LOCATION GIT_REPO INSTALL_VERSION
}

run_update_if_needed() {
    latest_tag=$(get_latest_tag "$git_repo")
    if semver_lt "$installed_version" "$latest_tag"; then
        run_update "$latest_tag"
    fi
}
# endregion

# region Clean Script
run_clean() {
    info "Running ${PURPLE}git gc${NC}"
    gc_err=$(git gc 2>&1 > /dev/null)
    if [ ! "$?" -eq "0" ]; then
        error "Running ${PURPLE}git gc${NC} failed: $gc_err"
        exit $?
    fi

    info "Running ${PURPLE}git remote prune $remote_to_prune${NC}"
    unset t_std t_err t_ret
    eval "$( (git remote prune $remote_to_prune) \
            2> >(t_err=$(cat | head -n 1); typeset -p t_err) \
            > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"

    if [ ! "$t_ret" -eq "0" ]; then
        error "Running ${PURPLE}git remote prune $remote_to_prune${NC} failed: $t_err"
        exit $t_ret
    fi

    pruned_branches=$(grep -Po '(?<=\* \[pruned\] ).+' <<< "$t_std" | tr "[:space:]" " ")

    if [ ! -z "$pruned_branches" ]; then
        IFS=' ' read -r -a pruned_branches <<< "$pruned_branches"

        for pruned_branch in "${pruned_branches[@]}"; do
            info "Pruned the branch ${PURPLE}$pruned_branch${NC}"
            branch_to_delete=$(git branch -vv | grep -P "\[$pruned_branch[:\]]" | awk '{$1=$1};1' | cut -d ' ' -f 1)
            info "Running ${PURPLE}git branch -d $branch_to_delete${NC}"

            delete_output=$(git branch -d "$branch_to_delete" 2>&1)
            if [ ! "$?" -eq "0" ]; then
                error "Running ${PURPLE}git branch -d $branch_to_delete${NC}: $delete_output"
            fi
        done

    else
        info "No branches to prune were found"
    fi
}
# endregion


if [[ "$@" == *"--update"* ]]; then
    BLUE="" NC="" PURPLE="" RED="" run_update_if_needed
else
    run_clean
    nohup bash -c "$0 --update" > /dev/null 2>&1 &
fi
