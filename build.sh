#!/bin/bash

# Define variables
IMAGE_NAME="jupyterhub-local"
CONTAINER_NAME="jupyterhub_container"
PORT_MAPPING="8000:8000"
VOLUME_MAPPING="$(pwd)/home:/srv/jupyterhub/home"

# Check if the environment variable is passed
ENVIRONMENT=${1:-local}

# Function to stop the container
stop_container() {
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Stopping container..."
        docker stop $CONTAINER_NAME
        echo "Container stopped."
    else
        echo "Container is not running."
    fi
}

# Function to remove the container
remove_container() {
    if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
        echo "Removing container..."
        docker rm $CONTAINER_NAME
        echo "Container removed."
    else
        echo "Container does not exist."
    fi
}

# Function to build and run the container
build_and_run() {
    # Build the Docker image
    echo "Building Docker image..."
    docker build -t $IMAGE_NAME .

    # Stop and remove the existing container if it exists
    stop_container
    remove_container

    # Run the Docker container with the ENV variable
    echo "Running Docker container in $ENVIRONMENT mode..."
    docker run -d -p $PORT_MAPPING -v $VOLUME_MAPPING --name $CONTAINER_NAME \
        -e ENV=$ENVIRONMENT \
        $IMAGE_NAME

    # Output the status
    echo "Docker container is up and running in $ENVIRONMENT mode!"
}

# Check the argument provided to the script
case "$2" in
    start)
        build_and_run
        ;;
    stop)
        stop_container
        ;;
    *)
        echo "Usage: $0 {local|production} {start|stop}"
        exit 1
        ;;
esac
