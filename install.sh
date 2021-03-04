#!/bin/sh

# region Color Codes
BLUE=${BLUE-'\033[0;34m'}
GREEN=${GREEN-'\033[0;32m'}
NC=${NC-'\033[0m'}
ORANGE=${ORANGE-'\033[0;33m'}
PURPLE=${PURPLE-'\033[0;35m'}
RED=${RED-'\033[0;31m'}
YELLOW=${YELLOW-'\033[1;33m'}
# endregion

# region Convenience Functions
get_latest_tag() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'
}

info() {
    printf "${BLUE}info${NC} $1\n"
}

yes_no_question() {
    printf "${ORANGE}question${NC} $1 [y/N]: "
    old_stty=$(stty -g)
    stty raw -echo; answer=$(head -c 1); stty $old_stty
    printf "\n"
    if echo "$answer" | grep -iq "^y"; then
        return 0
    else
        return 1
    fi
}

question() {
    # $1: The question to ask
    # $2: The default value
    printf "${ORANGE}question${NC} $1 [$2]: " >&2
    read -r answer
    if [ -z "$answer" ]; then
        echo "$2"
    else
        echo "$answer"
    fi
}

warning() {
    printf "${ORANGE}warn${NC} $1\n"
}

error() {
    printf "${RED}error${NC} $1\n"
}
# endregion

alias_name="$ALIAS_NAME"
install_location="$INSTALL_LOCATION"
git_repo=${GIT_REPO-'marier-nico/git-deep-clean'}
install_version=${INSTALL_VERSION-'latest'}
user_input_required=1

if [ -z "$alias_name" ] || [ -z "$install_location" ] || [ -z "$git_repo" ] || [ -z "$install_version" ]; then
    info "Thanks for installing ${GREEN}git deep clean${NC}!"
    info "Let's customise your install, you can cancel at any time without saving modifications."

    if ! yes_no_question "Shall we proceed?"; then
        exit 0
    fi

    info "Great! Here we go :)\n"
    user_input_required=0
fi

if [ -z "$alias_name" ]; then
    existing_aliases=$(git config --get-regexp ^alias\. | cut -d' ' -f1 | cut -d'.' -f2)
    current_alias="dc"

    while true; do
        current_alias=$(question "Choose a git alias for the deep clean command" "$current_alias")

        already_exists=1
        for existing_alias in $existing_aliases; do
            if [ "$existing_alias" = "$current_alias" ]; then
                already_exists=0
                break
            fi
        done

        if [ "$already_exists" -eq "0" ]; then
            if ! yes_no_question "This alias is already in use, would you like to overwrite it?"; then
                continue
            fi
        fi

        break
    done

    alias_name="$current_alias"
fi

if [ -z "$install_location" ]; then
    current_location="$HOME/.local/bin"

    while true; do
        current_location=$(question "Choose a folder where you want the script installed" "$current_location")
        if ls "$current_location/git-deep-clean.sh" >/dev/null 2>&1; then
            if ! yes_no_question "A file named ${ORANGE}git-deep-clean.sh${NC} already exists at that location, overwrite?"; then
                continue
            fi
        fi
        break
    done

    install_location="$current_location"
fi

if [ "$install_version" = "latest" ]; then
    info "Checking for the latest version of the script..."
    install_version=$(get_latest_tag "$git_repo")
    info "Found version $install_version."
fi

if [ "$user_input_required" -eq "0" ]; then
    printf "\n"
    info "Please review the following information carefully!
    git alias name: ${GREEN}$alias_name${NC}
    install location: ${GREEN}$install_location${NC}
    install version: ${GREEN}$install_version${NC}"
    if ! yes_no_question "Do you want to install with these settings?"; then
        exit 0
    fi
fi

temp_file=$(mktemp)
if curl -o "$temp_file" --silent "https://raw.githubusercontent.com/$git_repo/$install_version/git-deep-clean.sh"; then
    sed -i "s/^alias_name=\".*\"$/alias_name=\"$alias_name\"/" "$temp_file"
    sed -i "s|^install_location=\".*\"$|install_location=\"$install_location\"|" "$temp_file"
    sed -i "s/^installed_version=\".*\"$/installed_version=\"$install_version\"/" "$temp_file"
    sed -i "s|^git_repo=\".*\"$|git_repo=\"$git_repo\"|" "$temp_file"

    script_path="$install_location/git-deep-clean.sh"
    mkdir -p "$install_location"
    mv "$temp_file" "$script_path"
    chmod +x "$script_path"
    git config --global "alias.$current_alias" "\!$script_path"
fi
