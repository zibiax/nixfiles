//@ pragma IconTheme Papirus-Dark
import Quickshell
import Quickshell.Io

// Replaces waybar + rofi. Started by scripts/local/relaunch.sh; hyprland.lua binds
//   SUPER + SPACE          qs ipc call launcher toggle
//   SUPER + SHIFT + SPACE  qs ipc call powermenu toggle
//   SUPER + CTRL + V       qs ipc call clipboard toggle
ShellRoot {
    Bar {}

    Launcher {
        id: launcher
    }

    PowerMenu {
        id: powerMenu
    }

    Clipboard {
        id: clipboard
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            powerMenu.visible = false
            clipboard.visible = false
            launcher.toggle()
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            launcher.visible = false
            clipboard.visible = false
            powerMenu.toggle()
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            launcher.visible = false
            powerMenu.visible = false
            clipboard.toggle()
        }
    }
}
