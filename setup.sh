#! /bin/zsh
#############################################################################
# Configure an awesome development environment using zsh
#############################################################################

#############################################################################
# set up variables
#############################################################################
PRG=$0
DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
dotfiles="$DIR/dotfiles"
DEST="$HOME"

unset HELP YES_TO_ALL INSTALL
DRYRUN=false
YES_TO_ALL=false
TEST_INSTALLED=true


txtbyel="\033[1;33m"
txtbred="\033[1;31m"
txtbgrn="\033[1;32m"
txtyel="\033[33m"
txtblu="\033[34m"
txtmag="\033[35m"
txtcya="\033[36m"
txtnorm="\033[0m"
txtibyel="\033[1;7;33m"

#############################################################################
# User interaction functions
#############################################################################

usage() {
    echo "${txtbyel}USAGE:${txtnorm}" >&2
    echo "    $PRG ${txtcya}-h${txtnorm}                   - show help and exit" >&2
    echo "    $PRG ${txtcya}-i [-n] [-y] [-f]${txtnorm}    - install everything" >&2
}

help() {
    echo "$(
        cat <<__EOF__

${txtbyel}NAME${txtnorm}
    $PRG - Install an amazing development and terminal environment for zsh

${txtbyel}SYNOPSYS${txtnorm}
    $PRG ${txtcya}-h${txtnorm}
    $PRG ${txtcya}-i [-n] [-y] [-f]${txtnorm}

${txtbyel}DESCRIPTION${txtnorm}
    This script installs a great user experience for zsh and will install
    a range of useful development tools

${txtbyel}OPTIONS${txtnorm}
    The following options are available:

    ${txtcya}-h${txtnorm}  show this help and exit.

    ${txtcya}-i${txtnorm}  Run the installation process.

    ${txtcya}-n${txtnorm}  dry run: Show what would be installed but don't do anything.

    ${txtcya}-y${txtnorm}  Answer yes to all questions. This makes the script non-interactive.

    ${txtcya}-f${txtnorm}  Force installation — don't check if tools are already installed.

${txtbyel}EXAMPLES${txtnorm}
    $PRG -infy  Run through everything, show what would be installed without installing anything.
__EOF__
)"
}

message() {
    echo "${txtyel}   $@${txtnorm}"
}

message_info() {
    echo "ℹ️  $@"
}

message_ok() {
    echo "${txtbgrn}✅ $@${txtnorm}"
}

message_err() {
    echo "${txtbred}❌ $@${txtnorm}"
}

# Prompt for multi-choice user input
# Usage: ask promtp option1 option2 ...
# Return value is the index of the selected option
# First option result code is 0.
ask() {
    echo "${txtcya}❓ $1${txtnorm}"
    shift
    unset DONE ABORT
    cur=1
    count=$#
    while [ -z "$DONE" ]; do
        # print the options, highlight the current one
        echo -n "\r"
        for ((i = 1; i <= $count; i++)); do
            opt=$@[i]
            if [ $i -eq $cur ]; then
                echo -n "${txtibyel}  $opt  ${txtnorm}"
            else
                echo -n "${txtblu}  $opt  ${txtnorm}"
            fi
            if [ $i -lt $count ]; then
                echo -n " / "
            fi
        done
        # read arrow and enter keys
        IFS= read -srk 1 KEY
        case "$KEY" in
            "D") ((cur--)) ;;
            "C") ((cur++)) ;;
            $'\n') DONE=1 ;;
            #$'\e') DONE=1; ABORT=1 ;;
        esac
        # move current option based on arrow keys
        if [ $cur -lt 1 ]; then
            cur=$count
        elif [ $cur -gt $count ]; then
            cur=1
        fi
    done
    echo ""
    if [ -z "$ABORT" ]; then
        return $((cur - 1))
    else
        message "Exiting script"
        exit 0
    fi
}

# Ask a question with yes / no / abort options
# users select via arrow keys and enter.
# If YES_TO_ALL is set, doesn't ask for input; just returns 0
ask_yna() {
    if $YES_TO_ALL; then
        echo "${txtcya}❓ $@${txtnorm}"
        message "'-y' option is set; answering 'Yes' to this question"
        return 0
    else
        ask "$@" "Yes" "No" "Abort"
        choice=$?
        if [ $choice -eq 2 ]; then
            message "Exiting script"
            exit 0
        else
            return $choice
        fi
    fi
}

# eval whatever is piped to this function, unless DRYRUN is true
installcmd() {
    echo ""
    message "Installing:"
    if [ $# -eq 0 ]; then
        while read -r line; do
            echo "     ${txtmag}$line${txtnorm}"
        done
    else
        echo "     ${txtmag}$@${txtnorm}"
    fi

    if $DRYRUN; then
        message "(dry-run: not actually running these commands)"
    else
        echo ""
        if [ $# -eq 0 ]; then
            while read -r line; do
                eval $line
            done
        else
        eval $@
        fi
    fi
    echo ""
}

#############################################################################
# Handle command line options
#############################################################################
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

while getopts ':hniyf' c; do
    case $c in
        h)  HELP=1 ;;
        n)  DRYRUN=true ;;
        i)  INSTALL=1 ;;
        y)  YES_TO_ALL=true ;;
        f)  TEST_INSTALLED=false ;;
        \?) message_err "$PRG: Unknown option -$OPTARG" >&2
            echo ""
            usage
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))

if [ -n "$HELP" ]; then
    help
    exit 0
fi


if $YES_TO_ALL; then
    message_info "Running in non-interactive mode. No questions will be asked."
fi
if ! $TEST_INSTALLED; then
    message_info "Running in force mode. Tools will be installed even if they are already installed."
fi
if $DRYRUN; then
    message_info "Running in dry-run mode. No changes will be made."
fi

#############################################################################
# Install all the magic
#############################################################################

echo ""
message "Configuring basic tools and zsh magic"

# First things first. We need the XCode command line tools installed.
if $TEST_INSTALLED && command -v xcode-select &> /dev/null && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}" ; then
    message_ok "XCode command line tools are installed"
else
    echo ""
    if ask_yna "XCode command line tools are not installed. Install them now? "; then
        installcmd xcode-select --install
        message_ok "XCode command line tools installed"
    else
        message_err "XCode command line tools are required, so most things will break"
    fi
fi

# We also really need homebrew. Just in case it's not on the PATH,
# set it to where it might be
if command -v brew &> /dev/null; then
    brew="brew"
elif [ -x /opt/homebrew/bin/brew ]; then
    brew=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
    brew=/usr/local/bin/brew
else
    brew=""
fi
if $TEST_INSTALLED && [ -n "$brew" ]; then
    message_ok "Homebrew is installed"
else
    echo ""
    message "Homebrew is not installed. This is the most widely used package manager for macOS"
    message "Most of the tools that will be installed require homebrew."
    if ask_yna "Install Homebrew? "; then
        installcmd '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        message_ok "Homebrew installed"
    else
        message_err "homebrew is required, so most things will break"
        brew=":"
    fi
fi

# PowerLevel10k for awesome prompts
if $TEST_INSTALLED && [ -r $($brew --prefix)/opt/powerlevel10k ]; then
    message_ok "PowerLevel10K is installed"
else
    echo ""
    message "PowerLevel10K is not installed. This is an amazing prompt for zsh"
    if ask_yna "Install PowerLevel10K? "; then
        installcmd $brew install powerlevel10k
        message_ok "PowerLevel10K installed"
    else
        message "Skipping installation of PowerLevel10K"
    fi
fi
if $TEST_INSTALLED && [ -r $HOME/.p10k.zsh ]; then
    if $TEST_INSTALLED && [ "$(readlink $HOME/.p10k.zsh)" = "$DIR/dotfiles/p10k.zsh" ]; then
        message_ok "PowerLevel10K prompt is configured and using this project's configuration"
        message_info "You can reconfigure PowerLevel10K by running 'p10k configure', or edit $DIR/dotfiles/p10k.zsh"
    else
        echo ""
        message "PowerLevel10K prompt is configured, but it's not using this project's configuration."
        message "I can rename your original $HOME/.p10k.zsh configuration and create a symlink to this project's configuration."
        if ask "Do you want to use this project's configuration?" "Yes" "No" "Abort"; then
            installcmd <<'__EOF__'
                backup="$HOME/.p10k.zsh.$(date +"%Y.%m.%d.%H.%M")"
                mv "$HOME/.p10k.zsh" "$backup"
                ln -s "$DIR/dotfiles/p10k.zsh"  "$HOME/.p10k.zsh"
__EOF__
            message_ok "Created symlink from $DIR/dotfiles/p10k.zsh to $HOME/.p10k.zsh"
        else
            message "Not using this project's PowerLevel10K prompt."
            message_info "You can configure PowerLevel10K by running 'p10k configure',"
            message-info "Or if you change your mind, you can do 'ln -s $DIR/dotfiles/p10k.zsh to $HOME/.p10k.zsh'"
        fi
    fi
else
    echo ""
    message "PowerLevel10K is not configured. Do you want to use this project's configuration?"
    if ask_yna "Configure PowerLevel10K? "; then
        installcmd 'ln -s "$DIR/dotfiles/p10k.zsh" "$HOME/.p10k.zsh"'
        message_ok "Created symlink from $DIR/dotfiles/p10k.zsh to $HOME/.p10k.zsh"
    else
        message "Skipping configuration of PowerLevel10K"
        message_info "You can configure PowerLevel10K by running 'p10k configure'"
    fi
fi

# zsh syntax highlighting
if $TEST_INSTALLED && [ -r $($brew --prefix)/opt/zsh-syntax-highlighting ]; then
    message_ok "zsh-syntax-highlighting is installed"
else
    echo ""
    message "zsh-syntax-highlighting is not installed. This provides fish-like syntax highlighting for zsh"
    if ask_yna "Install zsh-syntax-highlighting? "; then
        installcmd $brew install zsh-syntax-highlighting
        message_ok "zsh-syntax-highlighting installed"
    else
        message "Skipping installation of zsh-syntax-highlighting"
    fi
fi

# NerdFonts
if $TEST_INSTALLED && $brew list --full-name | grep -q 'homebrew/cask-fonts/font-.*-nerd-font'; then
    message_ok "one or more NerdFonts appear to be installed (make sure to set your terminal font to one of these)"
    message_info "for a list of available fonts, run 'brew tap homebrew/cask-fonts' followed by 'brew search nerd-font'"
else
    echo ""
    message "You don't appear to have any NerdFonts installed. These are highly recommended for PowerLevel10K and colorls."
    message_info "NerdFonts are patched fonts that include a wide range of icons and symbols, ideal for a great terminal experience."
    message_info "You can find out about NerdFonts at https://www.nerdfonts.com"
    echo ""
    message "Some popular NerdFonts are Meslo (variation of Apple's Menlo), FiraCode, and Hack."
    if $YES_TO_ALL; then
        message "'-y' option set; installing Meslo Nerd Font"
        font="meslo-lg"
    else
        ask "Do you want me to install one of these for you?" "Meslo" "FiraCode" "Hack" "No" "Abort"
        case $? in
            0)  font="meslo-lg" ;;
            1)  font="fira-code" ;;
            2)  font="hack" ;;
            3)  font="" ;;
            4)  message "Exiting script"
                exit 0
                ;;
        esac
    fi
    if [ -n "$font" ]; then
        installcmd <<__EOF__
            $brew tap homebrew/cask-fonts
            $brew install --cask font-$font-nerd-font
__EOF__
        message_ok "$font Nerd Font installed. You can change your terminal font to $font in your Terminal settings."
        message_info "You can install more fonts with 'brew install --cask font-<fontname>-nerd-font'"
        message_info "for a list of available fonts, run 'brew search nerd-font'"
    else
        message "Skipping installation of the Meslo Nerd Font"
        message_info "You can install fonts with 'brew tap homebrew/cask-fonts' followed by 'brew install --cask font-<fontname>-nerd-font'"
        message_info "for a list of available fonts, run 'brew tap homebrew/cask-fonts' followed by 'brew search nerd-font'"
    fi
    echo ""
fi

# colorls
if $TEST_INSTALLED && command -v colorls &> /dev/null; then
    message_ok "colorls is installed"
else
    message "You don't have colorls installed. This is a replacement for ls that looks real nice."
    if ask_yna "Install colorls? "; then
        installcmd gem install --user-install colorls
        message_ok "colorls installed. You can run it with 'colorls'"
    else
        message "Skipping installation of colorls"
    fi
fi


# Use this project's .zshrc
if $TEST_INSTALLED && [ -r $HOME/.zshrc ]; then
    if $TEST_INSTALLED && [ "$(readlink $HOME/.zshrc)" = "$DIR/dotfiles/zshrc" ]; then
        message_ok "Your zsh is configured to use this project's .zshrc configuration"
    else
        echo ""
        message_info "You have a .zshrc file in your home directory, but it's not using this project's configuration."
        message "I can rename your original $HOME/.zshrc and create a symlink to this project's zshrc."
        if ask_yna "Do you want to use this project's zshrc?" "Yes" "No" "Abort"; then
            backup="$HOME/.zshrc.$(date +"%Y.%m.%d.%H.%M")"
            installcmd <<'__EOF__'
                mv "$HOME/.zshrc" "$backup"
                ln -s "$DIR/dotfiles/zshrc" "$HOME/.zshrc"
__EOF__
            message_ok "Created symlink from $DIR/dotfiles/zshrc to $HOME/.zshrc"
            message_info "Original file is renamed to $backup"
        else
            message "Not using this project's .zshrc configuration."
            message_info "If you change your mind, you can do 'ln -s $DIR/dotfiles/zshrc to $HOME/.zshrc'"
            message_info "Or add 'source $DIR/dotfiles/p10k.zsh' to your $HOME/.zshrc"
        fi
    fi
else
    echo ""
    message "you don't have a .zshrc config file in your home directory. Do you want to use this project's configuration?"
    if ask_yna "Configure .zshrc? "; then
        installcmd 'ln -s "$DIR/dotfiles/zshrc" "$HOME/.zshrc"'
        message_ok "Created symlink from $DIR/dotfiles/zshrc to $HOME/.zshrc"
    else
        message "Skipping configuration of .zshrc"
    fi
fi

# Use this project's .zshenv
if $TEST_INSTALLED && [ -r $HOME/.zshenv ]; then
    if $TEST_INSTALLED && [ "$(readlink $HOME/.zshenv)" = "$DIR/dotfiles/zshenv" ]; then
        message_ok "Your zsh is configured to use this project's .zshenv configuration"
    else
        echo ""
        message_info "You have a .zshenv file in your home directory, but it's not using this project's configuration."
        message "I can rename your original $HOME/.zshenv and create a symlink to this project's zshenv."
        if ask_yna "Do you want to use this project's zshenv?" "Yes" "No" "Abort"; then
            backup="$HOME/.zshenv.$(date +"%Y.%m.%d.%H.%M")"
            isntallcmd <<'__EOF__'
                mv "$HOME/.zshenv" "$backup"
                ln -s "$DIR/dotfiles/zshenv" "$HOME/.zshenv"
__EOF__
            message_ok "Created symlink from $DIR/dotfiles/zshenv to $HOME/.zshenv"
            message_info "Original file is renamed to $backup"
        else
            message "Not using this project's .zshenv configuration."
            message-info "If you change your mind, you can do 'ln -s $DIR/dotfiles/zshenv to $HOME/.zshenv'"
            message-info "Or add 'source $DIR/dotfiles/zshenv' to your $HOME/.zshenv"
        fi
    fi
else
    echo ""
    message "you don't have a .zshenv config file in your home directory. Do you want to use this project's configuration?"
    if ask_yna "Configure .zshenv? "; then
        installcmd 'ln -s "$DIR/dotfiles/zshenv" "$HOME/.zshenv"'
        message_ok "Created symlink from $DIR/dotfiles/zshenv to $HOME/.zshenv"
    else
        message "Skipping configuration of .zshenv"
    fi
fi


echo ""
message "Configuring basic development tools"

# git
if $TEST_INSTALLED && command -v git &> /dev/null; then
    message_ok "git is installed"
else
    message "You don't have git installed. Git is a widely used version control system."
    message_info "For information about git, see https://git-scm.com/"
    if ask_yna "Install git? "; then
        installcmd $brew install git
        message_ok "git installed."
    else
        message "Skipping installation of git."
    fi
fi

# asdf
if $TEST_INSTALLED && command -v asdf &> /dev/null; then
    message_ok "asdf is installed"
else
    message "You don't have asdf installed. asdf lets you manage versions for many runtimes."
    message_info "You can use asdf to manage versions of python, node, and other systems."
    message_info "For information about git, see https://asdf-vm.com/"
    if ask_yna "Install asdf? "; then
        installcmd $brew install asdf
        message_ok "asdf installed."
    else
        message "Skipping installation of asdf. Stuff will probably break, because several"
        message "tools that are installed with this script depend on asdf."
    fi
fi

# pre-commit
if $TEST_INSTALLED && command -v pre-commit &> /dev/null; then
    message_ok "pre-commit is installed"
else
    message "You don't have pre-commit installed. This is a tool for managing git hooks."
    message_info "You can use pre-commit to configure git hooks that run before every commit."
    message_info "For information about pre-commit, see https://pre-commit.com/"
    if ask_yna "Install pre-commit? "; then
        installcmd $brew install pre-commit
        message_ok "pre-commit installed."
    else
        message "Skipping installation of pre-commit."
    fi
fi