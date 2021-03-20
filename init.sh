#!/bin/bash

#sudo apt install neovim
#sudo update-alternatvies --config editor
# git clone nvim setup and move to relevant location
#sudo apt install curl
#sudo apt install tmux
# git clone tmux and move to relevant location
#sudo 

declare -a PACKAGES
declare -a ADDITIONAL_PPA
declare -a ADDITIONAL_PACKAGES

PACKAGES=(
    curl
    neovim
    tmux
    zsh
    libsecret-1-dev
    gnome-keyring
    virtualenv
    openconnect
    network-manager-openconnect
    tlp
    acpi-call-dkms
    openssh-server
)

ADDITIONAL_PPA=(
   kelleyk/emacs 
)

ADDITIONAL_PACKAGES=(
    emacs27
    spotify-client
)

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

function install_via_package_manager(){
    packages=("$@")
    for package in ${packages[@]}
    do
        print_info "Installing package $package"
        # TODO : Check how the below command can be generalized based on PKG_MAN
        sudo apt install -y $package
    done
}

function is_installed(){
    dpkg -s $1 | grep 'Status: install ok installed' >> /dev/null
    exit_code=$?
    echo $exit_code
}

function add_ppa(){
    print_info "Adding ppa:$1"
    sudo add-apt-repository -y ppa:$1
}

function add_spotify_repo(){
  print_info "Adding Spotify Deb package to source.list"
  curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg \
      | sudo apt-key add -   
  echo "deb http://repository.spotify.com stable non-free" \
      | sudo tee /etc/apt/sources.list.d/spotify.list
}

## Main Function

# Get the installation medium from commandline argument
while [ ! -z "$1" ]; do
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
    elif [[ $1 ==  "-l" ]] || [[ "$1" == "--linux" ]]; then
        LINUX="$2"
        if [[ $LINUX == "ubuntu" ]];then
            PACKAGE_MANAGER="apt"
            sudo $PACKAGE_MANAGER update
            sudo $PACKAGE_MANAGER -y upgrade
        fi
        print_info "PACKAGE MANAGER to be used will be '$PACKAGE_MANAGER'"
        shift
    else
        print_error "Incorrect input provided"
        show_usage
    fi
shift
done


# Install packages via package manager
print_info "Installing packages via Package manager"
install_via_package_manager ${PACKAGES[@]} 
: '
########################### Configuring defaults ###############################
# Package : neovim
status="$(is_installed neovim)"
if [ $status = 0 ]; then
    # set neovim as default editor
    print_info "Making neovim the default editor"
    sudo update-alternatives --set editor /usr/bin/nvim
fi
# Package : zsh
status="$(is_installed zsh)"
if [ $status = 0 ]; then
    # Set zsh as default shell for logged in user
    print_info "Changing default shell to be zsh"
    chsh -s $(which zsh)
fi


################### Packages that needs to be added to ppa #####################
for package in ${ADDITIONAL_PPA[@]}
do
    add_ppa $package
done

add_spotify_repo

# Run install via pkm once all packages configured
install_via_package_manager $ADDITIONAL_PACKAGES
'
