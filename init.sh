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
    ca-certificates
    gnupg
    lsb-release
    libappindicator3-1
    libc++1
    gconf2
    python
    python3
)

ADDITIONAL_PPA=(
   kelleyk/emacs
   https://cli.github.com/packages
)

ADDITIONAL_PACKAGES=(
    emacs27
    spotify-client
    docker-ce
    docker-ce-cli
    containerd.io
    gh
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
    sudo apt-add-repository -y ppa:$1
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
    # Remove sudo access for docker commands
    print_info "Adding $USER to docker group"
    sudo usermod -aG docker $USER
}

function update_ppa(){

    pre_spotify_install

    pre_docker_install

    # Add key to github cli ppa
    print_info "Adding keys required for Github CLI"
    sudo apt-key adv --keyserver \
        keyserver.ubuntu.com --recv-key C99B11DEB97541F0

    for package in ${ADDITIONAL_PPA[@]}
    do
        add_ppa $package
    done
}

function clone_to_configure(){
    # OhMyZsh
    print_info "Installing Oh My Zsh"
    sh -c "$(curl -fsSL \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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

    # TODO Run above commands with gh cli commands
    # Package: Iosevka fonts
    gh auth login
    gh release download --repo be5invis/Iosevka \
        --pattern 'ttf-iosevka-slab-*' --dir /tmp
    # TODO need to make this cleaner
    print_info "Extracting and staging Iosevka fonts to ~/.fonts"
    cd /tmp && unzip *.zip
    mkdir ~/.fonts
    mv /tmp/*.ttf ~/.fonts/
}

function prompt_install_deb_package(){
	#prompt user to Proceed once all the deb packages are available in /tmp dir
    print_info "Please Download following deb packages under ~/Downloads folder \n 1) Slack (https://slack.com/intl/en-in/downloads/linux) \n 2) outlook (https://github.com/tomlm/electron-outlook/releases) \n 3) mailspring (https://getmailspring.com/download) \n 4) code (https://code.visualstudio.com/Download) \n 5) discord (https://discord.com/download) \n 6) virtualbox (https://www.virtualbox.org/wiki/Linux_Downloads) \n 7) steam (https://store.steampowered.com/about/) \n 8) Dropbox (https://www.dropbox.com/install-linux)"
	# TODO Need to also add links to download page
	read -p "Proceed [Y/N]" answer
	while true
	do
		case $answer in
		 [Y]* ) print_info "Proceeding with installing deb packages"
		        for file in ~/Downloads/*.deb
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

function post_script_message(){
    echo "Please proceed with using the packages/softwares installed and configured"\
        "Following software require user login"\
        "Firefox"\
        "Dropbox - Registrationa and sync"\
        "Mailspring"\
        "VPN"\
        "Microsoft Teams"\
        "Outlook Office"\
        "Spotify"\
        "Discord"\
        "Steam"
}

# TODO Choose OS from CLI arg and proceed

function main(){
    # Install packages via package manager
    print_info "Installing packages via Package manager"
    install_via_package_manager ${PACKAGES[@]}


    update_ppa

    install_via_package_manager ${ADDITIONAL_PACKAGES[@]}

    configuring_default

    clone_to_configure

    prompt_install_deb_package

    post_script_message
}

# Calling main function
main
