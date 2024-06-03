#!/bin/bash
{ # Start a group to enable piping

    # Install Ollama without prompt
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh

    # Update system packages
    echo "Updating system packages..."
    sudo apt-get update && sudo apt-get dist-upgrade -y

    # Pause and prompt for Lambda Stack installation
    read -r -p "Ollama installed. Would you like to install Lambda Stack (for GPU drivers)? (y/N) " choice
    install_lambda=n # Default to not installing Lambda Stack

    # Check if user input matches yes (case-insensitive)
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_lambda=y

        # Download and run Lambda Stack installer with error check
        echo "Installing Lambda Stack..."
        if ! wget -nv -O- https://lambdalabs.com/install-lambda-stack.sh | bash; then
            echo "Error: Lambda Stack installation failed." >&2  # Print to stderr for error distinction
            exit 1  # Exit with failure status
        fi
        echo "Lambda Stack installation successful."
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
        exit 1  # Exit with failure status
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
