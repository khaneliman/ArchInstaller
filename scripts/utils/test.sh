#!/usr/bin/env bash

# @description Select multiple options
# @noargs
function multiselect {

    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "%s[?25h" "$ESC"; }
    cursor_blink_off() { printf "%s[?25l" "$ESC"; }
    cursor_to() { printf "%s[$1;${2:-1}H" "$ESC"; }
    print_inactive() { printf "%s   %s " "$2" "$1"; }
    print_active() { printf "$2  %s[7m $1 %s[27m" "$ESC" "$ESC"; }
    get_cursor_row() {
        IFS=';' read -rsdR -p $'\E[6n' ROW COL
        echo "${ROW#*[}"
    }
    get_cursor_col() {
        IFS=';' read -rsdR -p $'\E[6n' ROW COL
        echo "${COL#*[}"
    }
    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = "" ]]; then echo enter; fi
        if [[ $key = $'\x20' ]]; then echo space; fi
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A ]]; then echo up; fi
            if [[ $key = [B ]]; then echo down; fi
        fi
    }
    toggle_option() {
        local arr_name=$1
        eval "local arr=(\"\${${arr_name}[@]}\")"
        local option=$2
        if [[ ${arr[option]} == true ]]; then
            arr[option]=
        else
            arr[option]=true
        fi
        eval "$arr_name"='("${arr[@]}")'
    }

    local retval=$1
    local options
    local defaults

    # echo $2
    IFS=';' read -r -a options <<<"$2"

    if [[ -z $3 ]]; then
        defaults=()
    else
        IFS=';' read -r -a defaults <<<"$3"
    fi
    local selected=()

    # echo ${#options[@]}

    for ((i = 0; i < ${#options[@]}; i++)); do
        selected+=("${defaults[i]}")
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$((lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
                prefix="[x]"
            fi

            cursor_to $((startrow + idx))
            if [ $idx -eq $active ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
        space) toggle_option selected $active ;;
        enter) break ;;
        up)
            ((active--))
            if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi
            ;;
        down)
            ((active++))
            if [ $active -ge ${#options[@]} ]; then active=0; fi
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    eval "$retval"='("${selected[@]}")'
}

select_option() {

    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "%s[?25h" "$ESC"; }
    cursor_blink_off() { printf "%s[?25l" "$ESC"; }
    cursor_to() { printf "%s[$1;${2:-1}H" "$ESC"; }
    print_option() { printf "%s   %s " "$2" "$1"; }
    print_selected() { printf "$2  %s[7m $1 %s[27m" "$ESC" "$ESC"; }
    get_cursor_row() {
        IFS=';' read -rsdR -p $'\E[6n' ROW COL
        echo "${ROW#*[}"
    }
    get_cursor_col() {
        IFS=';' read -rsdR -p $'\E[6n' ROW COL
        echo "${COL#*[}"
    }
    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        [[ $key = "" ]] && echo enter
        [[ $key = $'\x20' ]] && echo space
        [[ $key = "k" ]] && echo up
        [[ $key = "j" ]] && echo down
        [[ $key = "h" ]] && echo left
        [[ $key = "l" ]] && echo right
        [[ $key = "a" ]] && echo all
        [[ $key = "n" ]] && echo none
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            [[ $key = [A || $key = k ]] && echo up
            [[ $key = [B || $key = j ]] && echo down
            [[ $key = [C || $key = l ]] && echo right
            [[ $key = [D || $key = h ]] && echo left
        fi
    }
    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0

        curr_idx=$((curr_col + curr_row * colmax))

        for option in "${options[@]}"; do

            row=$((idx / colmax))
            col=$((idx - row * colmax))

            cursor_to $((startrow + row + 1)) $((offset * col + 1))
            if [ "$idx" -eq "$curr_idx" ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++))
        done
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local return_value=$1
    local lastrow=$(get_cursor_row)
    local lastcol=$(get_cursor_col)
    local startrow=$((lastrow - $#))
    local startcol=1
    local lines=$(tput lines)
    local cols=$(tput cols)
    local colmax=$2
    local offset=$((cols / colmax))

    local size=$4
    shift 4

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row
        # user key control
        case $(key_input) in
        enter) break ;;
        up)
            ((active_row--))
            [ $active_row -lt 0 ] && active_row=0
            ;;
        down)
            ((active_row++))
            [ $active_row -ge $((${#options[@]} / colmax)) ] && active_row=$((${#options[@]} / colmax))
            ;;
        left)
            ((active_col--))
            [ $active_col -lt 0 ] && active_col=0
            ;;
        right)
            ((active_col++))
            [ $active_col -ge "$colmax" ] && active_col=$((colmax - 1))
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    return $((active_col + active_row * colmax))
}

testthing() {
    # JQ filters
    PACMAN_VALUE_FILTER=".pacman[].package"
    PACMAN_LABEL_FILTER=".pacman[].label"
    AUR_HELPER="paru"
    AUR_FILTER=$([ "$AUR_HELPER" != NONE ] && echo ", .aur[].package" || echo "")

    mapfile -t options < <(for f in ../../packages/optional/*.json; do echo "$f" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done)
    select_option $? 4 "${options[@]}" NONE
    optional_group="${options[$?]}"

    if [[ "$optional_group" != NONE ]]; then
        # Parse file with JQ to determine packages to install
        packages=($(jq -r "${PACMAN_VALUE_FILTER}""${AUR_FILTER}" ../../packages/optional/"${optional_group}".json | tr -d '[],"'))
        # package_string_test=$(jq -r "${PACMAN_LABEL_FILTER}""${AUR_FILTER}" ../../packages/optional/"${optional_group}".json)
        package_labels=($(jq -r "${PACMAN_VALUE_FILTER}""${AUR_FILTER}" ../../packages/optional/"${optional_group}".json))

        for i in "${package_labels[@]}"; do
            package_string+="$i;"
        done

        # echo $package_string_test
        # echo $package_string

        multiselect SELECTED "${package_string}"

        for i in "${!SELECTED[@]}"; do
            if [ "${SELECTED[$i]}" == "true" ]; then
                CHECKED+=("${packages[$i]}")
            fi
        done

        if [[ "${#CHECKED[@]}" > 0 ]]; then
            echo "pacman -S ${CHECKED[@]}"
        fi
    fi
}

testthing
