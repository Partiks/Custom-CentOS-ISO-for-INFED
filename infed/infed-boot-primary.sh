#!/bin/bash
#This file is executed by normal USER, NOT ROOT
[ -e /home/INFEDConfiguredSuccessfully.txt ] && exit 0

gnome-terminal -e "sudo /home/infed-boot-secondary.sh $USER" --full-screen
#gnome-terminal -e "su root /home/infed-boot-secondary.sh $USER" --full-screen

