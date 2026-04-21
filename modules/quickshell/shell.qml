import Quickshell
import Quickshell.Io

ShellRoot {
    Bar {}

    Launcher {
        id: launcher
        visible: false
    }

    PowerMenu {
        id: powerMenu
        visible: false
    }

    IpcHandler {
        target: "launcher"
        function handle(message) {
            launcher.visible = !launcher.visible
        }
    }

    IpcHandler {
        target: "powermenu"
        function handle(message) {
            powerMenu.visible = !powerMenu.visible
        }
    }
}
