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

info() {
    printf "${BLUE}info${NC} $1\n"
}

error() {
    printf "${RED}error${NC} $1\n"
}
# endregion

# region Auto Update
run_update() {
    latest_tag=$(get_latest_tag $1)
    info "Latest tag: $latest_tag"
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

    pruned_branches=$(echo "$t_std" | grep -Po '(?<=\* \[pruned\] ).+')
    verbose_git_branches=$(git branch -vv)

    if [ ! -z "$pruned_branches" ]; then
        for pruned_branch in "$pruned_branches"; do
            branch_to_delete=$(echo "$verbose_git_branches" | grep "$pruned_branch" | awk '{$1=$1};1' | cut -d ' ' -f 1)
            info "Running ${PURPLE}git branch -d $branch_to_delete${NC}"
            delete_output=$(git branch -d "$branch_to_delete")
            if [ ! "$?" -eq "0" ]; then
                error "Running ${PURPLE}git branch -d $branch_to_delete${NC}"
            fi
        done
    else
        info "No branches to prune were found"
    fi
}
# endregion


if [[ "$@" == *"--update"* ]]; then
    BLUE="" NC="" PURPLE="" RED="" run_update "$git_repo"
else
    run_clean
    nohup bash -c "$0 --update" > /dev/null 2>&1 &
fi
