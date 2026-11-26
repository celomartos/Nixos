//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma Env QT_SCALE_FACTOR_ROUNDING_POLICY = RoundPreferFloor

import QtQuick
import Quickshell
import "bar"
import "launcher"
import "clipboard"

ShellRoot {
    Bar {}
    AppLauncher {}
    ClipboardWindow {}
}
