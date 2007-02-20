#!/bin/sh
sudo mkdir -p /usr/local/bin
echo "Creating /usr/local/bin"
sudo mkdir -p /usr/local/man/man1
echo "Creating /usr/local/man/man1"
sudo cp growlnotify /usr/local/bin/growlnotify
sudo cp growlnotify.1 /usr/local/man/man1/growlnotify.1

echo "Installation complete. Please add /usr/local/bin to your PATH if you have not already. Consult your shell's documentation if you do not know how to do this."
