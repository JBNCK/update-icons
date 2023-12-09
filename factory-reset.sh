#!/bin/bash

# Check if script is run as root, sudo, or doas
if [ "$EUID" -ne 0 ] || [[ $(ps -o comm= -p $PPID) =~ ^(sudo|doas)$ ]]; then
  echo "Please run this script directly as root (without sudo/doas)!"
  exit 1
fi

# Check for active user sessions
active_users=$(who | awk '$1 != "root" {print $1}' | uniq)
if [ -n "$active_users" ]; then
  read -p "There are active user sessions. Please run this script from TTY mode logged in as root. Do you want to disable GDM and reboot to TTY mode? (y/n): " tty_choice
  case "$tty_choice" in
    y|Y )
      systemctl disable gdm.service
      echo "GDM disabled. Rebooting to TTY mode..."
      sleep 3
      reboot
      ;;
    * )
      echo "Please run this script from a TTY as root."
      exit 1
      ;;
  esac
fi

# Check if running in a graphical environment
if [ -n "$DISPLAY" ]; then
  read -p "This script should be run in a TTY environment. Do you want to disable GDM and reboot in TTY mode? (y/n): " graphical_choice
  case "$graphical_choice" in
    y|Y )
      # Disable GDM and reboot to TTY mode
      systemctl disable gdm.service
      echo "GDM disabled. Rebooting to TTY mode..."
      sleep 3
      reboot
      ;;
    n|N ) 
      echo "Factory reset aborted"
      exit 0 
      ;;
    * ) 
      echo "Invalid choice. Factory reset aborted"
      exit 1 
      ;;
  esac
fi

# Confirmation dialog for factory reset
read -p "This will delete all non-root accounts and reset the system. Are you sure you want to continue? (y/n): " choice
case "$choice" in
  y|Y )
    # Delete all non-root accounts except root
    for user in $(awk -F':' '{ if ($3 >= 1000 && $1 != "root") print $1 }' /etc/passwd)
    do
      pkill -KILL -u "$user"
      userdel -r "$user"
      echo "Deleted user: $user"
    done

    # Refresh user database
    echo "Refreshing user database..."
    grep -E ':[^!*]' /etc/passwd | cut -d: -f1 > /tmp/userlist.txt
    ;;
  n|N ) 
    echo "Factory reset aborted"
    systemctl enable gdm.service  # Re-enable GDM if reset is aborted
    exit 0 
    ;;
  * ) 
    echo "Invalid choice. Factory reset aborted"
    systemctl enable gdm.service  # Re-enable GDM if reset is aborted
    exit 1 
    ;;
esac

# Prompt for new username and password
clear
read -p "Enter the new username: " new_username
if grep -q "$new_username" /tmp/userlist.txt; then
  echo "User $new_username already exists. Factory reset aborted."
  systemctl enable gdm.service  # Re-enable GDM if reset is aborted
  exit 1
fi
read -p "Enter the full name of the new user: " new_full_name
useradd -m -g users -G wheel "$new_username"
chfn -f "$new_full_name" "$new_username"
su "$new_username" -c "/usr/bin/flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
usermod -aG video "$new_username"
usermod -aG audio "$new_username"
clear
passwd "$new_username"  # Set password for the new user

# Re-enable GDM
systemctl enable gdm.service

# Clean up and prompt for reboot
echo "Cleaning up..."
rm -rf /tmp/*
clear
read -p "Factory reset complete. Press Enter to reboot the system..."
reboot
