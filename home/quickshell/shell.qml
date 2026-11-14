//@ pragma UseQApplication
//@ pragma NativeTextRendering
//@ pragma Env QT_SCALE_FACTOR_ROUNDING_POLICY = RoundPreferFloor
//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import "bar"

ShellRoot {
    Bar {}
}
