#!/bin/bash

# Check if source and destination directories exist
if [ -d "/usr/share/mods/" ] && [ -d "/usr/share/applications/" ]; then
    # Copy specific files or handle the copying process as required
    cp /usr/share/mods/* /usr/share/applications/
    echo "Icons updated successfully."
else
    echo "Source or destination directory does not exist."
fi
