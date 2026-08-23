#!/bin/sh
#0.3
WHITE='\033[1;37m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
RESET='\033[0m'

COOLDOWN=5
cooldown_remaining=0
cooldown_disabled=0
BOX_WIDTH=34
INNER_WIDTH=$((BOX_WIDTH - 4))
PITY_LIMIT=50

DATA_DIR="$HOME/.local/share/soltui"
mkdir -p "$DATA_DIR" 2>/dev/null
ROLLS_FILE="$DATA_DIR/.rolls"


total_rolls=0
pity_counter=0
count_common=0
count_uncommon=0
count_rare=0
count_legendary=0

load_state() {
    if [ -f "$ROLLS_FILE" ]; then
        . "$ROLLS_FILE"
    fi
}

save_state() {
    {
        printf "total_rolls=%s\n" "$total_rolls"
        printf "pity_counter=%s\n" "$pity_counter"
        printf "count_common=%s\n" "$count_common"
        printf "count_uncommon=%s\n" "$count_uncommon"
        printf "count_rare=%s\n" "$count_rare"
        printf "count_legendary=%s\n" "$count_legendary"
    } > "$ROLLS_FILE"
}

load_state

old_stty=$(stty -g 2>/dev/null)

cleanup() {
    stty "$old_stty" 2>/dev/null
    printf "\033[?25h\n"
}
trap cleanup EXIT INT TERM

printf "\033[?25l"
stty -echo -icanon min 0 time 10 2>/dev/null

rand_num() {
    od -An -N2 -tu2 /dev/urandom | tr -d ' '
}

read_key() {
    dd bs=1 count=1 2>/dev/null
}

spaced() {
    text="$1"
    out=""
    rest="$text"
    while [ -n "$rest" ]; do
        ch=${rest%"${rest#?}"}
        rest=${rest#?}
        if [ -n "$rest" ]; then
            out="${out}${ch} "
        else
            out="${out}${ch}"
        fi
    done
    printf "%s" "$out"
}

S_COMMON=$(spaced "COMMON")
S_UNCOMMON=$(spaced "UNCOMMON")
S_RARE=$(spaced "RARE")
S_LEGENDARY=$(spaced "LEGENDARY")

center_pad() {
    text="$1"
    width="$2"
    textlen=${#text}
    total=$((width - textlen))
    [ "$total" -lt 0 ] && total=0
    left=$((total / 2))
    right=$((total - left))
    i=0; padleft=""
    while [ "$i" -lt "$left" ]; do padleft="${padleft} "; i=$((i + 1)); done
    i=0; padright=""
    while [ "$i" -lt "$right" ]; do padright="${padright} "; i=$((i + 1)); done
    printf "%s%s%s" "$padleft" "$text" "$padright"
}

border() {
    i=0; line=""
    while [ "$i" -lt "$BOX_WIDTH" ]; do line="${line}-"; i=$((i + 1)); done
    printf "%s" "$line"
}

blank_side() {
    i=0; sp=""
    while [ "$i" -lt "$INNER_WIDTH" ]; do sp="${sp} "; i=$((i + 1)); done
    printf "||%s||" "$sp"
}

text_side() {
    color="$1"
    label="$2"
    padded=$(center_pad "$label" "$INNER_WIDTH")
    printf "||%b%s%b||" "$color" "$padded" "$RESET"
}

draw_box() {
    first="$1"
    color="$2"
    label="$3"
    if [ "$first" -eq 0 ]; then
        printf "\033[5A"
    fi
    printf "\033[K%s\n" "$(border)"
    printf "\033[K%s\n" "$(blank_side)"
    printf "\033[K%s\n" "$(text_side "$color" "$label")"
    printf "\033[K%s\n" "$(blank_side)"
    printf "\033[K%s\n" "$(border)"
}

roll_animation() {
    frames=16
    i=0
    first=1
    while [ "$i" -lt "$frames" ]; do
        r=$(rand_num)
        idx=$((r % 4))
        case "$idx" in
            0) c="$WHITE"; l="$S_COMMON" ;;
            1) c="$GREEN"; l="$S_UNCOMMON" ;;
            2) c="$PURPLE"; l="$S_RARE" ;;
            *) c="$YELLOW"; l="$S_LEGENDARY" ;;
        esac
        draw_box "$first" "$c" "$l"
        first=0
        sleep 0.06
        i=$((i + 1))
    done

    pity_counter=$((pity_counter + 1))
    if [ "$pity_counter" -ge "$PITY_LIMIT" ]; then
        forced=1
        roll=0
    else
        forced=0
        roll=$(( $(rand_num) % 100 ))
    fi

    total_rolls=$((total_rolls + 1))

    if [ "$roll" -lt 1 ]; then
        pity_counter=0
        count_legendary=$((count_legendary + 1))
        draw_box 0 "$YELLOW" "* ${S_LEGENDARY} *"
        if [ "$forced" -eq 1 ]; then
            printf "\033[K%b\n" "${YELLOW}LEGENDARY (pity)${RESET}"
        else
            printf "\033[K%b\n" "${YELLOW}LEGENDARY (you lucky boy)${RESET}"
        fi
    elif [ "$roll" -lt 10 ]; then
        count_rare=$((count_rare + 1))
        draw_box 0 "$PURPLE" "$S_RARE"
        printf "\033[K%b\n" "${PURPLE}RARE -- 9% chance${RESET}"
    elif [ "$roll" -lt 40 ]; then
        count_uncommon=$((count_uncommon + 1))
        draw_box 0 "$GREEN" "$S_UNCOMMON"
        printf "\033[K%b\n" "${GREEN}UNCOMMON -- 30% chance${RESET}"
    else
        count_common=$((count_common + 1))
        draw_box 0 "$WHITE" "$S_COMMON"
        printf "\033[K%b\n" "${WHITE}COMMON -- 60% chance${RESET}"
    fi

    printf "\033[K%bPity: %s/%s%b\n\n" "$GRAY" "$pity_counter" "$PITY_LIMIT" "$RESET"

    save_state
}

printf "=== soltui ===\n"
printf "M = roll, O = disable / enable cooldown, Q = exit\n"
printf "saving rolls to: %s\n\n" "$ROLLS_FILE"

while true; do
    if [ "$cooldown_disabled" -eq 1 ]; then
        printf "\r\033[K%bready, M = roll, O = cooldown enable / disable, Q = exit (pity %s/%s)%b" "$GRAY" "$pity_counter" "$PITY_LIMIT" "$RESET"
    elif [ "$cooldown_remaining" -gt 0 ]; then
        printf "\r\033[K%bcooldown... %ds%b" "$GRAY" "$cooldown_remaining" "$RESET"
    else
        printf "\r\033[KReady, M = roll, O = disable cooldown, Q = quit. (pity %s/%s)" "$pity_counter" "$PITY_LIMIT"
    fi

    key=$(read_key)

    if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
        printf "\r\033[Kplay again soon\n"
        printf "total rolls: %s  (common %s, uncommon %s, rare %s, legendary %s)\n" \
            "$total_rolls" "$count_common" "$count_uncommon" "$count_rare" "$count_legendary"
        break
    fi

    if [ "$key" = "o" ] || [ "$key" = "O" ]; then
        if [ "$cooldown_disabled" -eq 1 ]; then
            cooldown_disabled=0
            printf "\r\033[K%bcooldown is back%b\n" "$GRAY" "$RESET"
        else
            cooldown_disabled=1
            cooldown_remaining=0
            printf "\r\033[K%broll all you want (no cooldown)%b\n" "$GRAY" "$RESET"
        fi
        continue
    fi

    if [ "$cooldown_disabled" -ne 1 ] && [ "$cooldown_remaining" -gt 0 ]; then
        cooldown_remaining=$((cooldown_remaining - 1))
        continue
    fi

    if [ "$key" = "m" ] || [ "$key" = "M" ]; then
        printf "\r\033[K\n"
        roll_animation
        if [ "$cooldown_disabled" -ne 1 ]; then
            cooldown_remaining=$COOLDOWN
        fi
    fi
done
