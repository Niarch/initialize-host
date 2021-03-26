#!/bin/bash

declare -a PACKAGES
declare -a ADDITIONAL_PPA
declare -a ADDITIONAL_PACKAGES
declare -a REPOSITORIES

PACKAGES=(
    git
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
    apt-transport-https
    ca-ceritificates
    gnupg
    lsb-release
)

ADDITIONAL_PPA=(
   kelleyk/emacs 
)

ADDITIONAL_PACKAGES=(
    emacs27
    spotify-client
    docker-ce
    docker-ce-cli
    containerd.io
)

REPOSITORIES=(
   https://github.com/Niarch/dotfiles.git 
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

function pre_spotify_install(){
  print_info "Adding Spotify Deb package to source.list"
  curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg \
      | sudo apt-key add -   
  echo "deb http://repository.spotify.com stable non-free" \
      | sudo tee /etc/apt/sources.list.d/spotify.list
}

function pre_docker_install(){
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

function configuring_default(){
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
}

function update_ppa(){

    for package in ${ADDITIONAL_PPA[@]}
    do
        add_ppa $package
    done

    pre_spotify_install

    pre_docker_install
}

function clone_to_configure(){
    # OhMyZsh
    print_info "Installing Oh My Zsh"
    curl -fsSL \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    # TODO Need to make my own zshrc config evnetually

    # Doom-emacs
    print_info "Installing Doom emacs"
    rm -rf ~/.emacs.d
    git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install

    # Vim and Tmux conf
    # Install Vim-plug first
    print_info "Installing Vim-Plug"
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim \
        --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    print_info "User needs to manually run 'PluginInstall' after init.vim is ready"

    # Clone dotfiles repository
    print_info "Cloning Dotfiles from personal repo"
    git clone https://github.com/Niarch/dotfiles.git /tmp/dotfiles
    # vim config
    mkdir $HOME/.config/nvim
    mv /tmp/dotfiles/.config/nvim/init.vim $HOME/.config/nvim/init.vim
    print_info "Setup neovim config completed"
    # tmux config
    mv /tmp/dotfiles/.tmux.conf $HOME/.tmux.conf
    print_info "Setup tmux config completed"
}

function prompy_install_deb_package(){
	#prompt user to Proceed once all the deb packages are available in /tmp dir
	print_info "Please Download following deb packages under /tmp folder \n 1) Slack \n 2) outlook \n 3) mailspring \n 4) code \n 5) discord \n 6) virtualbox \n 7) steam "
	# TODO Need to also add links to download page
	read -p "Proceed [Y/N]" answer
	while true
	do
		case $answer in
		 [Y]* ) print_info "prcoeeding with installing deb packages"
		        for file in /tmp/*.deb
		        do
				print_info "Install deb $file"
				sudo dpkg -i $file
			done
			break;;
		 [N]* ) print_error "You have choosen to skip deb installation, please refer to script for pending task"
			exit;;
		esac
	done

}

:'
# Get the installation medium from commandline argument
#while [ ! -z "$1" ]; do
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
'

function main(){
    # Install packages via package manager
    print_info "Installing packages via Package manager"
    install_via_package_manager ${PACKAGES[@]}

    configuring_default

    update_ppa

    install_via_package_manager ${ADDITIONAL_PACKAGES[@]}

    clone_to_configure

    prompt_install_deb_package
}

# Calling main function
main
