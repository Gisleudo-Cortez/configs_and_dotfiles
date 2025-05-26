#!/usr/bin/env bash

configs=(
   nvim
   fish  
   hypr
   waybar
   kitty
)

echo "Starting configuration backup..."
echo "================================"

for config in "${configs[@]}"; do
   if [[ -d ~/.config/"$config" ]]; then
       echo "Copying ~/.config/$config/ ..."
       cp -r ~/.config/"$config"/ .
       echo "✓ Successfully copied $config configuration"
   else
       echo "⚠ Warning: ~/.config/$config not found, skipping"
   fi
done

echo ""
echo "Copying additional files..."
if [[ -f ~/.zshrc ]]; then
   echo "Copying ~/.zshrc ..."
   cp ~/.zshrc .
   echo "✓ Successfully copied .zshrc"
else
   echo "⚠ Warning: ~/.zshrc not found, skipping"
fi

echo ""
echo "Configuration backup completed!"
echo "Files copied to: $(pwd)"
