#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Confirmation dialog
read -p "This will delete all non-root accounts and reset the system. Are you sure you want to continue? (y/n): " choice
case "$choice" in
  y|Y )
    # Delete all non-root accounts except root
    for user in $(awk -F':' '{ if ($3 >= 1000 && $1 != "root") print $1 }' /etc/passwd)
    do
      userdel -r "$user"
      echo "Deleted user: $user"
    done
    
    # Prompt for new username and password
    read -p "Enter the new username: " new_username
    useradd -m "$new_username"
    passwd "$new_username"  # Set password for the new user
    
    # Reboot the system
    read -p "Factory reset complete. Press Enter to reboot the system..."
    reboot
    ;;
  n|N ) echo "Factory reset aborted";;
  * ) echo "Invalid choice. Factory reset aborted";;
esac
