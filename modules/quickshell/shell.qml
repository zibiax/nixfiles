//@ pragma IconTheme Papirus-Dark
import Quickshell
import Quickshell.Io

// Stand-in for waybar + rofi. Run with `qs`, then bind in hyprland.lua:
//   hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
//   hl.bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("qs ipc call powermenu toggle"))
ShellRoot {
    Bar {}

    Launcher {
        id: launcher
    }

    PowerMenu {
        id: powerMenu
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            powerMenu.visible = false
            launcher.toggle()
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            launcher.visible = false
            powerMenu.toggle()
        }
    }
}
