#!/usr/bin/env bash
set -e

VERSION="1.0.0"
CONFIG_FILE=".circleci-matrix.yml"
STOP_ON_ERROR=0
FAILED_COMMANDS=0

# Ensure sane defaults and export for subshells
export CIRCLE_NODE_TOTAL=${CIRCLE_NODE_TOTAL:-1}
export CIRCLE_NODE_INDEX=${CIRCLE_NODE_INDEX:-0}

error() {
    local message=$1
    echo >&2 "ERROR: $message"
    exit 1
}

info() {
    local message=$1
    if [ "$message" == "" ]; then
        echo ""
    else
        echo "$message"
    fi
}

print_horizontal_rule () {
    printf "%$(tput cols)s\n" | tr " " "-"
}

print_help() {
    info "Usage: circleci-matrix [OPTIONS]"
    info ""
    info "Options:"
    info "  --help, -h           Print this screen"
    info "  --version            Current version of circleci-matrix"
    info "  --config, -c         Specify the config file to use"
    info "                       (default: .circleci-matrix.yml)"
    info "  --stop-on-error,-s   Halt after the first failed command"
}

parse_args() {
    while : ; do
    case "$1" in
    -h|--help)
        print_help
        exit 0
        ;;

    --version)
        info "$VERSION"
        exit 0
        ;;

    -c|--config)
        if [ "$2" == "" ]; then
            error "Missing argument for: $1"
        fi
        CONFIG_FILE=$2
        shift 2
        ;;

    -s|--stop-on-error)
        STOP_ON_ERROR=1
        shift
        ;;

    *)
        if [ "$1" != "" ]; then
            error "Unknown option: $1"
        fi
        break
        ;;
    esac
    done
}

ensure_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "No $CONFIG_FILE file found!"
    fi
}

sources() {
    # Detect and load nvm for NodeJS
    if [ -f ~/nvm/nvm.sh ]; then
        echo "source ~/nvm/nvm.sh;"
    fi
}

read_file() {
    local group=$1
    local active_group=0
    local group_indent=0
    local current_line=""
    local default_spacer=" "
    local next_spacer="${default_spacer}"

    while IFS='' read -r line; do
        local start=$(trim_right "${line:0:$group_indent}")
        if [[ $active_group -eq 1 && "$start" != "" ]]; then
            active_group=0
        fi

        if [[ $active_group -eq 0 && "$line" == "${group}:" ]]; then
            active_group=1
            continue
        fi

        if [ $active_group -ne 1 ]; then
            continue
        fi

        # Detect group indentation
        if [ $group_indent -eq 0 ]; then
            # Ignore empty lines
            if [ "$line" == "" ]; then
                continue
            fi

            # Ignore comment lines
            local first_chars=$(echo "$line" | sed -e 's/^ *//' | cut -c1-2)
            if [ "${first_chars:0:1}" == "#" ]; then
                continue
            fi

            # A new block is about to start
            if [[ "$first_chars" != "- " && "$line" = *":" ]]; then
                active_group=0
                continue
            fi

            local line_trimmed=$(echo "$line" | sed -e 's/^ *//')
            local len_trimmed=$(expr "$line_trimmed" : '.*')
            local len_full=$(expr "$line" : '.*')
            local group_indent=$((len_full - len_trimmed))
        fi

        local line_trimmed=${line:$group_indent}

        # Detect element-end
        local first_chars=${line_trimmed:0:2}
        if [[ "$first_chars" == "- " && "$current_line" != "" ]]; then
            echo "${current_line:2}"
            current_line=""
            default_spacer=" "
        fi

        # Skip comments
        if [ "${first_chars:0:1}" == "#" ]; then
            continue
        fi

        # Detect special multi-line blocks
        local line_content=${line_trimmed:1}
        local first_chars_trimmed=${line_trimmed:0:3}
        if [[ "$first_chars_trimmed" == "- |" || "$first_chars_trimmed" == "- >" ]]; then
            current_line="  "
            default_spacer="\n"
            next_spacer=""
            continue
        fi

        # Handle empty lines for normal (dash) rows
        if [[ "${line_content}" == "" && "${default_spacer}" == " " ]]; then
            current_line="${current_line}\n"
            next_spacer=""
            continue
        fi

        # Handle lines
        current_line="${current_line}${next_spacer}${line_content}"
        next_spacer="${default_spacer}"
    done < <(cat "$CONFIG_FILE")

    current_line="${current_line:2}"
    echo "${current_line}"
}

process_commands() {
    local line=""
    local envfile=$1
    local tempfile=$(mktemp -t circleci_matrix.XXX)

    while read -r line; do
        cp -f "$envfile" "$tempfile"
        echo -e "$line" >> "$tempfile"

        echo -e "\$ ${line//\\n/\\n> }"
        set +e
        (bash "$tempfile")
        local exitcode=$?
        set -e
        rm -rf "$tempfile"

        if [ $exitcode -ne 0 ]; then
            ((FAILED_COMMANDS=FAILED_COMMANDS+1))
            if [ $STOP_ON_ERROR -eq 1 ]; then
                exit 1
            fi
        fi
    done < <(read_file "command")
}

process_envs() {
    local line=""
    local i=0
    local tempfile=$(mktemp -t circleci_matrix.XXX)
    local sources_prefix="$(sources)"

    while read -r line; do
        if [ $((i % CIRCLE_NODE_TOTAL)) -eq "$CIRCLE_NODE_INDEX" ]; then
            print_horizontal_rule
            info "-- Env: $line"
            print_horizontal_rule

            rm -rf "$tempfile"
            {
                echo "#!/usr/bin/env bash";
                echo "$sources_prefix";
                echo -e "$line"
            } >> "$tempfile"
            process_commands "$tempfile"
            rm -rf "$tempfile"

            info ""
        fi
        ((i=i+1))
    done < <(read_file "env")
}

main() {
    parse_args "$@"

    print_horizontal_rule
    info "-- circleci-matrix version: $VERSION"
    info "-- circleci node total: $CIRCLE_NODE_TOTAL"
    info "-- circleci node index: $CIRCLE_NODE_INDEX"
    print_horizontal_rule

    ensure_file
    info ""

    process_envs

    if [ $FAILED_COMMANDS -gt 0 ]; then
        error "$FAILED_COMMANDS command(s) failed"
    fi
}

trim_right() {
    local var="$1"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

main "$@"
