#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get dist-upgrade -y

# Install Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Prompt user to install Lambda Stack (for GPU drivers)
read -p "Install Lambda Stack (for GPU drivers)? (y/N) " -r install_lambda
install_lambda=${install_lambda:-"n"}  # Set default to "n" if user just hits enter

if [[ "$install_lambda" =~ ^[Yy]$ ]]; then
    echo "Installing Lambda Stack..."
    if wget -nv -O- https://lambdalabs.com/install-lambda-stack.sh | sh; then
        echo "Lambda Stack installation successful."
    else
        echo "Lambda Stack installation failed."
    fi
else
    echo "Skipping Lambda Stack installation."
fi

# Update system packages after Ollama and Lambda Stack installation
echo "Updating system packages after installations..."
sudo apt-get update
sudo apt-get dist-upgrade -y

# Set OLLAMA_HOST environment variable
echo "Setting OLLAMA_HOST environment variable..."
export OLLAMA_HOST=0.0.0.0

# Start Ollama server in the background and log output to ollama.log
echo "Starting Ollama server..."
(ollama serve > ollama.log 2>&1) &

# Reload systemd daemon and start Ollama service
echo "Reloading systemd daemon and starting Ollama service..."
sudo systemctl daemon-reload
sudo systemctl start ollama

# Check if Ollama service is running
service_status=$(sudo systemctl status ollama | grep "Active:" | awk '{print $2}')

# Retry starting Ollama service if it fails
retry_service() {
    read -p "Ollama service failed to start. Retry? (Y/n) " choice
    case "$choice" in
        n|N) echo "Exiting script..."; exit 1;;
        *) echo "Retrying..."; sudo systemctl start ollama;;
    esac
}

if [ "$service_status" == "active" ]; then
    echo "Ollama service is running!"
else
    echo "Error: Failed to start Ollama service."
    retry_service
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

# Keep the script running
while true; do
    sleep 60
done
