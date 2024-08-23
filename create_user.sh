#!/bin/bash

# Prompt for the username
read -p "Enter username: " username

# Check if the user already exists
if id -u "$username" >/dev/null 2>&1; then
    echo "User '$username' already exists."
else
    # Prompt for the password
    read -sp "Enter password for $username: " password
    echo

    # Create the user and set the password
    adduser --disabled-password --gecos "" "$username"
    echo "$username:$password" | chpasswd

    echo "User '$username' has been created."
fi