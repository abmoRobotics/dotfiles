#!/usr/bin/env bash
# Lock the screen with i3lock, showing an unblurred sim render on every monitor
# (replaces i3lock-fancy, which blurs a screenshot of the desktop).
#
#   lock.sh            build the image and lock
#   lock.sh -o FILE    only write the lock image to FILE (preview, does not lock)
set -o errexit -o nounset -o pipefail

WALLPAPERS="${XDG_CONFIG_HOME:-$HOME/.config}/awesome/wallpapers"
SIM_GLOB="16x_standard_Apollo*"
ICON="/usr/share/i3lock-fancy/lock.png"
TEXT="Type password to unlock"
FONT="DejaVu-Sans"

OUT=""
if [[ "${1:-}" == "-o" ]]; then
    OUT="${2:?usage: lock.sh [-o FILE]}"
fi

shopt -s nullglob
SIMS=("$WALLPAPERS"/$SIM_GLOB)
shopt -u nullglob

IMAGE="$(mktemp --suffix=.png)"
trap 'rm -f "$IMAGE"' EXIT

build_image() {
    local xr screen_w screen_h line w h x y i=0
    local -a order layers=() overlay=()

    xr="$(xrandr)"
    [[ "$xr" =~ current\ ([0-9]+)\ x\ ([0-9]+) ]] || return 1
    screen_w=${BASH_REMATCH[1]}
    screen_h=${BASH_REMATCH[2]}

    (( ${#SIMS[@]} > 0 )) || return 1
    mapfile -t order < <(printf '%s\n' "${SIMS[@]}" | shuf)

    while read -r line; do
        [[ "$line" =~ \ connected.*\ ([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+) ]] || continue
        w=${BASH_REMATCH[1]} h=${BASH_REMATCH[2]} x=${BASH_REMATCH[3]} y=${BASH_REMATCH[4]}

        # One sim render (16:9) per monitor. Fill and centre-crop, except when the
        # monitor is only a bit taller than 16:9 (e.g. 16:10): then fit the width
        # and leave thin black bars, so the SIM / REAL labels are not cut off.
        local fill="^"
        if (( h <= w && (h - w * 9 / 16) * 100 <= 15 * h && h * 16 >= w * 9 )); then
            fill=""
        fi
        layers+=(\( -define "jpeg:size=${w}x${h}" "${order[i % ${#order[@]}]}"
                 -resize "${w}x${h}${fill}" -background black -gravity center
                 -extent "${w}x${h}" \)
                 -gravity NorthWest -geometry "+${x}+${y}" -composite)
        i=$((i + 1))

        # Lock icon and hint in the middle of the monitor, on a dark pill so
        # they stay readable on top of bright regolith
        local cx=$((x + w / 2)) cy=$((y + h / 2))
        overlay+=(-fill '#000000A0' -stroke none
                  -draw "roundrectangle $((cx - 190)),$((cy - 70)) $((cx + 190)),$((cy + 80)) 16,16"
                  "$ICON" -gravity NorthWest -geometry "+$((cx - 30))+$((cy - 50))" -composite
                  \( -background none -fill '#E6E6E6' -font "$FONT" -pointsize 20
                  -size 380x -gravity center "caption:$TEXT" \)
                  -gravity NorthWest -geometry "+$((cx - 190))+$((cy + 28))" -composite)
    done <<<"$xr"

    (( i > 0 )) || return 1
    convert -size "${screen_w}x${screen_h}" xc:black "${layers[@]}" "${overlay[@]}" \
        -define png:compression-level=1 "PNG24:$IMAGE"
}

if ! build_image; then
    # Never fail open: fall back to a plain dark lock if the image can't be built
    [[ -n "$OUT" ]] && { echo "lock.sh: could not build lock image" >&2; exit 1; }
    exec i3lock -n -c 101418
fi

if [[ -n "$OUT" ]]; then
    cp -f "$IMAGE" "$OUT"
    exit 0
fi

i3lock -n -i "$IMAGE" || i3lock -n -c 101418
