#!/bin/bash

# Function to check if an apt package is installed
is_apt_installed() {
    local package=$1
    dpkg -s "$package" &> /dev/null
}

# Function to check if a pip package is installed
is_pip_installed() {
    local package=$1
    pip3 show "$package" &> /dev/null
}

# Function to check if a snap package is installed
is_snap_installed() {
    local package=$1
    snap list "$package" &> /dev/null
}

# Function to check if flatpak is installed
is_flatpak_installed() {
    command -v flatpak >/dev/null 2>&1
}

# Function to check if a PPA is already added
is_ppa_added() {
    local ppa_name=$(echo "$1" | cut -d':' -f2-)
    local ppa_escaped=${ppa_name//\//\\/} # Escape slashes for grep
    grep -q "^deb .*${ppa_escaped}" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null
}

install_yq() {
    if command -v yq >/dev/null 2>&1; then
        echo "yq is already installed."
    else
        echo "Installing yq..."
        sudo snap install yq
    fi
}

install_chrome() {
    # Check if Google Chrome is installed
    if is_apt_installed "google-chrome-stable"; then
        echo "Google Chrome is already installed."
    else
        echo "Installing Google Chrome..."
        # Download and install Google signing key into keyring (apt-key is deprecated)
        wget -q -O- https://dl.google.com/linux/linux_signing_key.pub | \
            gpg --dearmor | sudo tee /usr/share/keyrings/google-linux-signing-keyring.gpg >/dev/null
        # Add Google Chrome repository using the keyring
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | \
            sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
        sudo apt update
        sudo apt install -y google-chrome-stable
    fi
}

add_ppa_repositories() {
    echo "Adding required PPA repositories..."

    # Read the list of required PPA repositories from packages.yaml
    if [ -f config/packages.yaml ]; then
        REQUIRED_PPA_REPOSITORIES=($(yq e '.apt-ppa-repositories[]' config/packages.yaml))
    else
        echo "Error: packages.yaml not found."
        exit 1
    fi

    for ppa in "${REQUIRED_PPA_REPOSITORIES[@]}"; do
        if [[ -z "$ppa" ]]; then
            echo "Skipping empty PPA entry."
            continue
        fi

        if is_ppa_added "$ppa"; then
            echo "PPA '$ppa' is already added. Skipping."
        else
            echo "Adding PPA '$ppa'..."
            sudo add-apt-repository -y "$ppa"
            if [ $? -eq 0 ]; then
                echo "Successfully added PPA '$ppa'."
            else
                echo "Failed to add PPA '$ppa'. Please check for errors."
            fi
        fi
    done

    # Update package lists after adding PPAs
    sudo apt update
}

install_git() {
    # Check if Git is installed
    if command -v git >/dev/null 2>&1; then
        echo "Git is already installed."
    else
        echo "Installing Git..."
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y git git-lfs
    fi

    echo "Configuring Git..."

    # Prompt for email to use for both Git and SSH
    read -p "Enter the email you want to use for both GIT and SSH: " email

    # Check if Git is already configured
    if git config --global user.name &>/dev/null; then
        echo "Git is already configured with the following settings:"
        echo "User Name: $(git config --global user.name)"
        echo "User Email: $(git config --global user.email)"
    else
        read -p "Enter the name you want to use for GIT user.name: " git_username

        git config --global user.name "$git_username"
        git config --global user.email "$email"

        echo "Git configuration complete."
    fi

    git config --global credential.helper store
    # Call generate_ssh_key with the same email after Git setup
    generate_ssh_key "$email"
}

install_main(){
    echo "Starting main installation..."
    # ----------------------------
    # First install chrome
    install_chrome

	# ----------------------------
	# Snap Installation and Setup
	# ----------------------------

	# Check if snap is installed
	if command -v snap >/dev/null 2>&1; then
	    echo "Snap is already installed."
	else
	    echo "Snap is not installed. Installing Snap..."
	    sudo apt update
	    sudo apt install -y snapd
	    if [ $? -eq 0 ]; then
		echo "Successfully installed Snap."
		# Enable and start snapd service
		sudo systemctl enable --now snapd.socket
		sudo systemctl start snapd
	    else
		echo "Failed to install Snap. Please check for errors."
		exit 1
	    fi
	fi
	# ----------------------------
	# pip3 Installation and Setup
	# ----------------------------

    # Check if pip3 is installed
    if command -v pip3 >/dev/null 2>&1; then
        echo "pip3 is already installed."
    else
        echo "pip3 is not installed. Installing pip3..."
        sudo apt install -y python3-pip
    fi

    # ----------------------------
    # Flatpak Installation and Setup
    # ----------------------------

    # Check if flatpak is installed
    if is_flatpak_installed; then
        echo "Flatpak is already installed."
    else
        echo "Flatpak is not installed. Installing Flatpak..."
        sudo apt update
        sudo apt install -y flatpak
        if [ $? -eq 0 ]; then
            echo "Successfully installed Flatpak."
            # Add Flathub repository
            echo "Adding Flathub repository..."
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            echo "Failed to install Flatpak. Please check for errors."
            exit 1
        fi
    fi

    echo "Starting main installation..."
    
    # ----------------------------
    # Prepare Installation
    # ----------------------------
    install_yq

    # ----------------------------
    # Add PPA Repositories
    # ----------------------------
    echo "Adding PPA repositories..."
    add_ppa_repositories

    # ----------------------------
    # Update system package cache and upgrade
    # ----------------------------
    echo "Updating package lists and upgrading system packages..."
    sudo apt update && sudo apt upgrade -y
	# ----------------------------
	# Find packages 
	# ----------------------------

    # Read the list of required apt packages from packages.yaml
    if [ -f config/packages.yaml ]; then
        REQUIRED_APT_PACKAGES=($(yq e '.apt_packages[]' config/packages.yaml))
    else
        echo "Error: packages.yaml not found."
        exit 1
    fi

    # Read the list of required pip packages from packages.yaml
    if [ -f config/packages.yaml ]; then
        REQUIRED_PIP_PACKAGES=($(yq e '.pip_packages[]' config/packages.yaml))
    else
        echo "Error: packages.yaml not found."
        exit 1
    fi

    # Read the list of required pip packages from packages.yaml
    if [ -f config/packages.yaml ]; then
        mapfile -t RAW_SNAP_PACKAGES < <(yq e '.snap_packages[]' config/packages.yaml)
        # Process packages to handle any flags
        REQUIRED_SNAP_PACKAGES=()
        for line in "${RAW_SNAP_PACKAGES[@]}"; do
            # Remove comments and leading/trailing whitespace
            line=$(echo "$line" | sed 's/#.*//' | xargs)
            if [[ -z "$line" ]]; then
                continue
            fi
            REQUIRED_SNAP_PACKAGES+=("$line")
        done
    else
        echo "Error: packages.yaml not found."
        exit 1
    fi


    # Read the list of required flatpak packages from packages.yaml
    if [ -f config/packages.yaml ]; then
        REQUIRED_FLATPAK_PACKAGES=($(yq e '.flatpak_packages[]' config/packages.yaml))
    else
        echo "Error: packages.yaml not found."
        exit 1
    fi

	# ----------------------------
	# Installation
	# ----------------------------

    # Install required apt packages
    echo "Installing required apt packages..."
    for package in "${REQUIRED_APT_PACKAGES[@]}"; do
        if is_apt_installed "$package"; then
            echo "Package '$package' is already installed. Skipping."
        else
            echo "Installing package '$package'..."
            sudo apt install -y "$package"
            if [ $? -eq 0 ]; then
                echo "Successfully installed '$package'."
            else
                echo "Failed to install '$package'. Please check for errors."
            fi
        fi
    done


    # Install common pip packages
    echo "Installing common pip packages..."
    for package in "${REQUIRED_PIP_PACKAGES[@]}"; do
        if is_pip_installed "$package"; then
            echo "Pip package '$package' is already installed. Skipping."
        else
            echo "Installing pip package '$package'..."
            pip3 install --user "$package"
            if [ $? -eq 0 ]; then
                echo "Successfully installed pip package '$package'."
            else
                echo "Failed to install pip package '$package'. Please check for errors."
            fi
        fi
    done

    # Install required snap packages
    echo "Installing required Snap packages..."
    for package in "${REQUIRED_SNAP_PACKAGES[@]}"; do
        # Extract package name and any additional flags
        PACKAGE_NAME=$(echo "$package" | awk '{print $1}')
        PACKAGE_FLAGS=$(echo "$package" | cut -d' ' -f2-)

        if is_snap_installed "$PACKAGE_NAME"; then
            echo "Snap package '$PACKAGE_NAME' is already installed. Skipping."
        else
            echo "Installing Snap package '$PACKAGE_NAME'..."
            sudo snap install "$PACKAGE_NAME" $PACKAGE_FLAGS
            if [ $? -eq 0 ]; then
                echo "Successfully installed Snap package '$PACKAGE_NAME'."
            else
                echo "Failed to install Snap package '$PACKAGE_NAME'. Please check for errors."
            fi
        fi
    done

    # Install required Flatpak packages
    echo "Installing required Flatpak packages..."
    for package in "${REQUIRED_FLATPAK_PACKAGES[@]}"; do
        if is_flatpak_package_installed "$package"; then
            echo "Flatpak package '$package' is already installed. Skipping."
        else
            echo "Installing Flatpak package '$package'..."
            flatpak install -y flathub "$package"
            if [ $? -eq 0 ]; then
                echo "Successfully installed Flatpak package '$package'."
            else
                echo "Failed to install Flatpak package '$package'. Please check for errors."
            fi
        fi
    done

    install_configs
    install_arc_icons
        # Install Oh My Sh
    install_oh_my_zsh

    # Read whether Oh My Sh is installed
    CONFIG_FILE="config/configs.yaml"
    INSTALL_OH_MY_ZSH=$(yq e '.oh_my_zsh.install' "$CONFIG_FILE")

    if [[ "$INSTALL_OH_MY_ZSH" == "true" ]]; then
        # Install Zsh Plugins based on configs.yaml
        install_zsh_plugins

    else
        echo "Oh My Sh is not installed. Skipping Zsh plugins installation."
    fi

    echo "Main installation complete."

}


install_extras() {
    echo "Preparing to install optional packages and configure settings..."

    # Initialize variables to store user choices
    install_ros2_choice="n"
    install_watchers_choice="n"
    install_latex_choice="n"

    # Prompt the user for each optional package
    echo "Please answer the following questions to select optional packages for installation:"
    read -p "Do you want to install ROS2 Humble? (y/n): " install_ros2_choice
    read -p "Do you want to change max file watchers? (y/n): " install_watchers_choice
    read -p "Do you want to install LaTeX? (y/n): " install_latex_choice

    echo ""
    echo "Processing your selections..."

    # Install ROS2 Humble if the user chose yes
    if [[ "$install_ros2_choice" =~ ^[Yy]$ ]]; then
        install_ros2
    else
        echo "Skipping ROS2 Humble installation."
    fi

    # Change max file watchers if the user chose yes
    if [[ "$install_watchers_choice" =~ ^[Yy]$ ]]; then
        change_max_file_watchers
    else
        echo "Skipping max file watchers configuration."
    fi

    # Install LaTeX if the user chose yes
    if [[ "$install_latex_choice" =~ ^[Yy]$ ]]; then
        install_latex
    else
        echo "Skipping LaTeX installation."
    fi

    echo "Optional packages installation complete."
}

install_ros2() {
    echo "Installing ROS2 Humble..."

    # Configure locale
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Add universe repository
    sudo add-apt-repository universe -y

    # Add ROS2 GPG key
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

    # Add ROS2 repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

    # Update and upgrade packages
    sudo apt update
    sudo apt upgrade -y

    # Install ROS2 Humble Desktop
    sudo apt install ros-humble-desktop -y

    # Install Gazebo Fortress
    sudo apt-get install ros-humble-ros-gz

    # Source ROS2 setup script
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    source ~/.bashrc

    echo "ROS2 Humble installation complete."
}

change_max_file_watchers() {
    echo "Changing max file watchers..."

    # Check current value
    current_value=$(sysctl fs.inotify.max_user_watches | awk '{print $3}')
    if [ "$current_value" -ge 524288 ]; then
        echo "Max user watches is already set to $current_value."
    else
        echo "Setting fs.inotify.max_user_watches to 524288..."
        echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p

        # Verify the change
        new_value=$(sysctl fs.inotify.max_user_watches | awk '{print $3}')
        echo "fs.inotify.max_user_watches is now set to $new_value."
    fi

    echo "Max file watchers configuration complete."
}

install_latex() {
    echo "Installing LaTeX..."

    # Check if texlive-full is already installed
    if dpkg -l | grep -qw texlive-full; then
        echo "LaTeX (texlive-full) is already installed."
    else
        echo "Installing texlive-full..."
        sudo apt-get install texlive-full -y
        echo "LaTeX installation complete."
    fi
}

# Function to clone repositories based on config/repositories.yaml
clone_repos() {
    install_yq
    CONFIG_FILE="config/repositories.yaml"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file $CONFIG_FILE not found."
        return 1
    fi

    echo "Cloning repositories as per $CONFIG_FILE..."

    # Read the number of repositories
    repo_count=$(yq e '.repositories | length' "$CONFIG_FILE")

    for i in $(seq 0 $(($repo_count - 1))); do
        repo_url=$(yq e ".repositories[$i].url" "$CONFIG_FILE")
        destination=$(yq e ".repositories[$i].destination" "$CONFIG_FILE")
        folder_name=$(yq e ".repositories[$i].folder_name // \"\"" "$CONFIG_FILE")

        # Remove quotes if any
        repo_url=$(echo "$repo_url" | tr -d '"')
        destination=$(echo "$destination" | tr -d '"')
        folder_name=$(echo "$folder_name" | tr -d '"')

        # **Expand ~ to $HOME**
        if [[ "$destination" == ~* ]]; then
            destination="${destination/#\~/$HOME}"
        fi

        if [ -z "$repo_url" ] || [ -z "$destination" ]; then
            echo "Invalid configuration for repository index $i."
            continue
        fi

        # Determine the target directory name
        if [ -n "$folder_name" ]; then
            target_dir="$destination/$folder_name"
            echo "Using custom folder name '$folder_name' for repository."
        else
            # Derive repository name from URL
            repo_name=$(basename "$repo_url" .git)
            target_dir="$destination/$repo_name"
            echo "No folder_name provided or it is empty. Using repository name '$repo_name'."
        fi

        # Create the destination directory if it doesn't exist
        if [ ! -d "$destination" ]; then
            echo "Creating base directory $destination..."
            mkdir -p "$destination"
            if [ $? -ne 0 ]; then
                echo "Failed to create directory $destination. Skipping repository index $i."
                continue
            fi
        else
            echo "Base directory $destination already exists."
        fi

        # Check if the target directory exists and is a Git repository
        if [ -d "$target_dir/.git" ]; then
            existing_url=$(git -C "$target_dir" config --get remote.origin.url)
            if [ "$existing_url" == "$repo_url" ]; then
                echo "Repository already cloned at $target_dir. Pulling latest changes..."
                git -C "$target_dir" pull
            else
                echo "Directory $target_dir exists but is linked to a different repository ($existing_url). Skipping clone."
            fi
        elif [ -d "$target_dir" ]; then
            echo "Directory $target_dir exists but is not a Git repository. Skipping clone to avoid overwriting."
        else
            echo "Cloning $repo_url into $target_dir..."
            git clone "$repo_url" "$target_dir"
            if [ $? -ne 0 ]; then
                echo "Failed to clone repository $repo_url into $target_dir."
                continue
            fi
        fi

        echo ""  # Add an empty line for readability
    done

    echo "Repository cloning completed."
}


install_docker() {
    echo "Installing Docker..."

    echo 'Installing Docker'
    sudo apt-get purge docker docker-engine docker.io
    sudo apt-get install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    docker --version

    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo chmod 777 /var/run/docker.sock

    echo 'Installing docker-compose'
    sudo curl -L "https://github.com/docker/compose/releases/download/2.3.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    echo 'Installing docker nvidia toolkit'
    sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install nvidia-container-toolkit -y
    # Configure the default nvidia-container-runtime
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker

}

# Function to install configuration symlinks
install_configs() {
    echo "Installing configuration symlinks..."

    # Path to configs.yaml
    CONFIGS_YAML="config/configs.yaml"

    # Check if configs.yaml exists
    if [ ! -f "$CONFIGS_YAML" ]; then
        echo "Error: $CONFIGS_YAML not found."
        return 1
    fi

    # Read the list of configs from configs.yaml
    CONFIGS=($(yq e '.configs[]' "$CONFIGS_YAML"))

    # Directory where your dotfiles are located
    DOTFILES_DIR="$(pwd)/.."

    # Iterate over each config and create symlinks
    for config in "${CONFIGS[@]}"; do
        echo "Processing configuration: $config"

        SOURCE_PATH="$DOTFILES_DIR/$config"
        TARGET_PATH="$HOME/$config"

        # Check if source exists
        if [ ! -e "$SOURCE_PATH" ]; then
            echo "Warning: Source $SOURCE_PATH does not exist. Skipping."
            continue
        fi

        # Determine if the source is a directory or a file
        if [ -d "$SOURCE_PATH" ]; then
            TYPE="directory"
        elif [ -f "$SOURCE_PATH" ]; then
            TYPE="file"
        else
            echo "Warning: Source $SOURCE_PATH is neither a file nor a directory. Skipping."
            continue
        fi

        # Backup existing config if it exists
        if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            BACKUP_DIR="$HOME/.config_backup/$(date +%Y%m%d_%H%M%S)/$config"
            echo "Backing up existing $TARGET_PATH to $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET_PATH" "$BACKUP_DIR"
        fi

        # Ensure parent directory exists
        mkdir -p "$(dirname "$TARGET_PATH")"

        # Create symbolic link
        ln -s "$SOURCE_PATH" "$TARGET_PATH"
        if [ $? -eq 0 ]; then
            echo "Symlink created: $TARGET_PATH -> $SOURCE_PATH"
        else
            echo "Failed to create symlink for $config."
        fi
    done

    echo "Configuration symlinks installation complete."
}

install_arc_icons() {
    # Define the repository URL and target directory
    REPO_URL="https://github.com/horst3180/arc-icon-theme.git"
    TARGET_DIR="/usr/share/icons/Arc"

    # Check if the Arc folder already exists
    if [ -d "$TARGET_DIR" ]; then
        echo "The Arc icon theme is already installed at $TARGET_DIR."
        return
    fi

    # Create a temporary directory for cloning the repository
    TMP_DIR=$(mktemp -d)
    echo "Cloning the repository to temporary directory: $TMP_DIR"

    # Clone the repository
    git clone "$REPO_URL" "$TMP_DIR" || {
        echo "Failed to clone the repository."
        return 1
    }

    # Check if the Arc folder exists in the cloned repository
    if [ ! -d "$TMP_DIR/Arc" ]; then
        echo "The Arc folder was not found in the cloned repository."
        rm -rf "$TMP_DIR"
        return 1
    fi

    # Copy the Arc folder to /usr/share/icons
    echo "Copying the Arc folder to $TARGET_DIR..."
    sudo cp -r "$TMP_DIR/Arc" /usr/share/icons || {
        echo "Failed to copy the Arc folder to $TARGET_DIR."
        rm -rf "$TMP_DIR"
        return 1
    }

    # Clean up the temporary directory
    echo "Cleaning up..."
    rm -rf "$TMP_DIR"

    echo "The Arc icon theme has been installed successfully."
}



install_oh_my_zsh() {
    echo "Checking if Oh My Zsh installation is enabled in configs.yaml..."

    CONFIG_FILE="config/configs.yaml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file $CONFIG_FILE not found. Skipping Oh My Zsh installation."
        return 1
    fi

    INSTALL_OH_MY_ZSH=$(yq e '.oh_my_zsh.install' "$CONFIG_FILE")

    if [[ "$INSTALL_OH_MY_ZSH" != "true" ]]; then
        echo "Oh My Zsh installation is disabled in configs.yaml. Skipping."
        return 0
    fi

    echo "Installing Oh My Zsh..."

    # Check if Oh My Zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh is already installed. Skipping installation."
    else
        echo "Cloning Oh My Zsh repository into $HOME/.oh-my-zsh..."
        git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"

        if [ $? -eq 0 ]; then
            echo "Oh My Zsh cloned successfully."
            # Copy the default .zshrc if it doesn't exist
            if [ ! -f "$HOME/.zshrc" ]; then
                cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
                echo "Default .zshrc configuration copied."
            fi
        else
            echo "Failed to clone Oh My Zsh repository. Please check for errors."
            return 1
        fi
    fi

    # Apply theme
    THEME=$(yq e '.oh_my_zsh.theme' "$CONFIG_FILE")

    if [ -n "$THEME" ] && [ "$THEME" != "null" ]; then
        if [ "$THEME" = "powerlevel10k" ]; then
            echo "Installing Powerlevel10k theme..."
            # Install Powerlevel10k theme
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

            # # Update .zshrc to use Powerlevel10k theme
            # sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/" "$HOME/.zshrc"

            # Optionally copy .p10k.zsh configuration file if it exists
            # P10K_CONFIG_SOURCE="$(pwd)/../.config/oh-my-zsh/.p10k.zsh"
            # P10K_CONFIG_DEST="$HOME/.p10k.zsh"

            # if [ -f "$P10K_CONFIG_SOURCE" ]; then
            #     cp "$P10K_CONFIG_SOURCE" "$P10K_CONFIG_DEST"
            #     echo "Copied .p10k.zsh configuration file."
            # else
            #     echo ".p10k.zsh configuration file not found. Skipping."
            # fi
        else
            # Handle custom themes
            THEME_SOURCE="$(pwd)/../.config/oh-my-zsh/$THEME.zsh-theme"
            THEME_DEST="$HOME/.oh-my-zsh/custom/themes/$THEME.zsh-theme"

            if [ -f "$THEME_SOURCE" ]; then
                cp "$THEME_SOURCE" "$THEME_DEST"
                echo "Custom theme '$THEME' copied to Oh My Zsh themes directory."

                # Update Oh My Zsh configuration to use the custom theme
                sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME\"/" "$HOME/.zshrc"

                echo "Oh My Zsh theme set to '$THEME'."
            else
                echo "Custom theme source $THEME_SOURCE does not exist. Skipping theme setup."
            fi
        fi
    fi

    # Check if default shell should be set to Zsh
    DEFAULT_SHELL=$(yq e '.oh_my_zsh.default_shell' "$CONFIG_FILE")

    if [ "$DEFAULT_SHELL" = "true" ]; then
        CURRENT_SHELL=$(basename "$SHELL")
        if [ "$CURRENT_SHELL" != "zsh" ]; then
            # Set the default shell to Zsh
            chsh -s "$(command -v zsh)"
            echo "Default shell set to Zsh."
        else
            echo "Default shell is already Zsh."
        fi
    fi

    echo "Oh My Zsh installation and configuration complete."
}



install_zsh_plugins() {
    echo "Installing Zsh plugins based on configs.yaml..."

    CONFIG_FILE="config/configs.yaml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file $CONFIG_FILE not found. Skipping Zsh plugins installation."
        return 1
    fi

    # Read the list of Zsh plugins from configs.yaml
    plugin_count=$(yq e '.zsh_plugins | length' "$CONFIG_FILE")

    if [ "$plugin_count" -eq 0 ]; then
        echo "No Zsh plugins specified in configs.yaml. Skipping."
        return 0
    fi

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    mkdir -p "$ZSH_CUSTOM/plugins"

    for i in $(seq 0 $(($plugin_count - 1))); do
        plugin_name=$(yq e ".zsh_plugins[$i].name" "$CONFIG_FILE")
        install_plugin=$(yq e ".zsh_plugins[$i].install" "$CONFIG_FILE")
        plugin_repo=$(yq e ".zsh_plugins[$i].repo" "$CONFIG_FILE")

        if [[ "$install_plugin" != "true" ]]; then
            echo "Skipping plugin $plugin_name as per configs.yaml."
            continue
        fi

        plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"

        if [ -d "$plugin_dir" ]; then
            echo "Plugin $plugin_name is already installed. Skipping."
        else
            echo "Installing plugin $plugin_name..."
            git clone "$plugin_repo" "$plugin_dir"
            if [ $? -eq 0 ]; then
                echo "Plugin $plugin_name installed successfully."
            else
                echo "Failed to install plugin $plugin_name."
            fi
        fi
    done

    echo "Zsh plugins installation based on configs.yaml completed."
}

generate_ssh_key() {
    email=$1
    echo "Setting up SSH key with email: $email"

    # Check if xclip is installed
    if command -v xclip >/dev/null 2>&1; then
        echo "xclip is already installed."
    else
        echo "Installing xclip..."
        sudo apt install -y xclip
    fi

    # Generate SSH key if it doesn’t already exist
    if [[ -f ~/.ssh/id_ed25519 ]]; then
        echo "SSH key already exists. Copying it to clipboard..."
    else
        ssh-keygen -t ed25519 -C "$email"
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        echo "New SSH key generated."
    fi

    # Copy the SSH public key to the clipboard
    cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard
    echo "SSH key (public) has been copied to clipboard. Paste it into GitHub."
}


# Function to display menu
show_menu() {
    echo "Please choose an installation option:"
    echo "1) Install main application"
    echo "2) Git Operations"
    echo "3) Install Docker"
    echo "4) Install optional packages and configure symlinks"
    echo "5) Install everything"
    echo "e) Exit"
}

# Function to show the Git sub-menu
show_git_menu() {
    echo "Please choose a Git installation option:"
    echo "1) Install Git"
    echo "2) Clone Repositories"
    echo "3) Install & Configure Git + Clone Repositories"
    echo "e) Return to main menu"
}

# Function to handle Git sub-menu choices
handle_git_menu() {
    while true; do
        show_git_menu
        read -p "Enter your choice [1-3 or e]: " git_choice
        case $git_choice in
            1)
                install_git
                ;;
            2)
                clone_repos
                ;;
            3)
                install_git
                clone_repos
                ;;
            e|E)
                echo "Returning to main menu."
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or e."
                ;;
        esac
        echo ""
    done
}
# Main loop
while true; do
    show_menu
    read -p "Enter your choice [1-5]: " choice
    case $choice in
        1)
            install_main
            ;;
        2) 
            handle_git_menu
       	    ;;
        3) 
            install_docker
            ;;
        4)
            install_extras
            ;;
        5)
            echo "Installing everything..."
            install_github
            install_main
            install_docker
            install_extras
            echo "All installations complete."
            ;;
        e)
            echo "Exiting installer."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 5."
            ;;
    esac
    echo ""
done
