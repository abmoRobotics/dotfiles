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

install_yq() {
    if command -v yq >/dev/null 2>&1; then
        echo "yq is already installed."
    else
        echo "Installing yq..."
        sudo snap install yq
    fi
}

install_github() {
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
	# Prepare Installation
	# ----------------------------
    install_yq

    # Update and upgrade system packages
    echo "Updating and upgrading system packages..."
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

    install_configs

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
    echo "2) Install Git and configure GitHub"
    echo "3) Install Docker"
    echo "4) Install optional packages and configure symlinks"
    echo "5) Install everything"
    echo "e) Exit"
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
            install_github
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
