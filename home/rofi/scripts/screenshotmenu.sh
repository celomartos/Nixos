
#!/usr/bin/env bash

set -euo pipefail

screenshot_dir="$HOME/Pictures/Screenshots"

[[ -d "$screenshot_dir" ]] || exit 1

mapfile -t files < <(
    find "$screenshot_dir" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
        -printf '%T@ %p\n' |
        sort -rn |
        cut -d' ' -f2-
)

((${#files[@]})) || exit 0

selected=$(
    for file in "${files[@]}"; do
        printf '%s\0icon\x1fthumbnail://%s\n' "${file##*/}" "$file"
    done |
        rofi -dmenu -i -p "Screenshots" -no-custom -show-icons
) || exit 0

[[ -n "$selected" ]] || exit 0

selected_file="$screenshot_dir/$selected"

action=$(
    {
        printf '%s\0icon\x1f%s\n' "Edit" "applications-graphics"
        printf '%s\0icon\x1f%s\n' "Copy" "edit-copy"
        printf '%s\0icon\x1f%s\n' "Open" "document-open"
        printf '%s\0icon\x1f%s\n' "Delete" "user-trash"
    } |
        rofi -dmenu -i -p "$selected" -no-custom -show-icons
) || exit 0

case "$action" in
    Edit)
        satty --filename "$selected_file" --copy-command wl-copy &
        ;;
    Copy)
        mime_type=$(file --brief --mime-type "$selected_file")
        wl-copy --type "$mime_type" < "$selected_file"
        notify-send "Screenshots" "Image copied."
        ;;
    Open)
        xdg-open "$selected_file" >/dev/null 2>&1 &
        ;;
    Delete)
        confirmation=$(
            printf '%s\n' "Cancel" "Delete permanently" |
                rofi -dmenu -i -p "Delete $selected?" -no-custom
        ) || exit 0

        if [[ "$confirmation" == "Delete permanently" ]]; then
            rm -- "$selected_file"
            notify-send "Screenshots" "Image deleted."
        fi
        ;;
esac

