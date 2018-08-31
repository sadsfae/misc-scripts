#!/bin/bash
# send inotify message and toggle microphone mute button on/off
# Lenovo x270 running Fedora 28
# based partly on: https://askubuntu.com/questions/125367/enabling-mic-mute-button-and-light-on-lenovo-thinkpads
# I associate this with an XFCE keyboard shortcut.
INPUT_DEVICE="'Capture'"
YOUR_USERNAME=`whoami`
if amixer sget $INPUT_DEVICE,0 | grep '\[on\]' ; then
    amixer sset $INPUT_DEVICE,0 toggle
    DISPLAY=":0" notify-send -t 50 -i microphone-sensitivity-muted-symbolic "Mic MUTED"
else
    amixer sset $INPUT_DEVICE,0 toggle
    DISPLAY=":0" notify-send -t 50  -i microphone-sensitivity-high-symbolic "Mic ON"
fi
