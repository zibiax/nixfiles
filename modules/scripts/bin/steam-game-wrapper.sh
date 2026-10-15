#!/usr/bin/env bash

# Export environment variables to force display
export SDL_VIDEO_FULLSCREEN_DISPLAY=0
export WINEFSDRV_PREFERRED_DISPLAY=0
export DISPLAY=:1

# Launch with gamemode
gamemoderun "$@"
