#!/bin/bash

{ # Start a group to enable piping

    # Prompt for Ollama installation
    read -r -p "Install Ollama? (y/N) " choice
    install_ollama=n # Default to not installing Ollama

    # Check if user input matches yes (case-insensitive)
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_ollama=y

        # Download Ollama installer
        echo "Downloading Ollama installer..."
        if ! ollama_script=$(wget -qO- https://ollama.com/install.sh); then
            echo "Error: Failed to download Ollama installer." >&2
            exit 1
        fi

        # Prompt user before running installer
        read -r -p "Downloaded Ollama installer. Proceed with installation? (y/N) " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            # Run Ollama installer
            echo "Installing Ollama..."
            if ! echo "$ollama_script" | bash; then
                echo "Error: Ollama installation failed." >&2
                exit 1
            fi
            echo "Ollama installation successful."
        else
            echo "Skipping Ollama installation."
        fi

        # Update system packages after Ollama installation
        echo "Updating system packages..."
        sudo apt-get update && sudo apt-get dist-upgrade -y
    else
        echo "Skipping Ollama installation."
    fi 

    # Prompt for Lambda Stack installation
    read -r -p "Would you like to install Lambda Stack (for GPU drivers)? (y/N) " choice
    install_lambda=n # Default to not installing Lambda Stack

    # Check if user input matches yes (case-insensitive)
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_lambda=y

        # Download Lambda Stack installer
        echo "Downloading Lambda Stack installer..."
        if ! lambda_script=$(wget -qO- https://lambdalabs.com/install-lambda-stack.sh); then
            echo "Error: Failed to download Lambda Stack installer." >&2
            exit 1
        fi

        # Prompt user before running installer
        read -r -p "Downloaded Lambda Stack installer. Proceed with installation? (y/N) " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            # Run Lambda Stack installer
            echo "Installing Lambda Stack..."
            if ! echo "$lambda_script" | bash; then
                echo "Error: Lambda Stack installation failed." >&2
                exit 1
            fi
            echo "Lambda Stack installation successful."
        else
            echo "Skipping Lambda Stack installation."
        fi
    else
        echo "Skipping Lambda Stack installation."
    fi
    
    # Set OLLAMA_HOST environment variable
    echo "Setting OLLAMA_HOST environment variable..."
    export OLLAMA_HOST=0.0.0.0

    # Start Ollama server in the background and log output to ollama.log
    echo "Starting Ollama server..."
    (ollama serve > ollama.log 2>&1) &

    # Reload systemd daemon and ensure Ollama service starts
    echo "Reloading systemd daemon and starting Ollama service..."
    sudo systemctl daemon-reload
    if ! sudo systemctl start ollama; then
        echo "Error: Failed to start Ollama service." >&2
        exit 1
    fi

    # Prompt user to enter the model to run
    echo "Enter the model to run (e.g., llama2, llama3, etc.) or press Enter to skip:"
    read -p "Model: " model

    # Run the specified model if provided, otherwise skip
    if [ -n "$model" ]; then
        echo "Running $model model..."
        ollama run "$model"
    else
        echo "Skipping model run."
    fi
    
    echo "Installation complete. Ollama is running in the background."

} # End of command grouping for one-liner execution
