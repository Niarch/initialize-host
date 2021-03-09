#!/bin/bash

#sudo apt install neovim
#sudo update-alternatvies --config editor
# git clone nvim setup and move to relevant location
#sudo apt install curl
#sudo apt install tmux
# git clone tmux and move to relevant location
#sudo 

function show_usage(){
    echo "Usage : This is initialization script to install required packages"
    echo "Options: "
    echo " -l|--linux [linux variant], This will select package manager " \
         "based on linux variant, Available options 'ubuntu', 'manjaro' "
}

function print_info(){
    # Ansi color code variable
    green="\e[0;92m"
    reset="\e[0m"
    echo -e "${green}[I] $1${reset}"
}

function print_error(){
    # Ansi color code variable
    red="\e[0;91m"
    reset="\e[0m"
    echo -e "${red}[E] $1${reset}"
}

## Main Function

# Get the installation medium from commandline argument
while [ ! -z "$1" ]; do
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
    elif [[ $1 ==  "-l" ]] || [[ "$1" == "--linux" ]]; then
        LINUX="$2"
        if [[ $LINUX == "ubuntu" ]];then
            PACKAGE_MANAGER="apt install"
        elif [[ $LINUX == "manjaro" ]];then
            PACKAGE_MANAGER="pacman -S"
        fi
        print_info "PACKAGE MANAGER to be used will be '$PACKAGE_MANAGER'"
        shift
    else
        print_error "Incorrect input provided"
        show_usage
    fi
shift
done


