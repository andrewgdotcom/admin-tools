#####################################################################
# Extended getopt handler based on https://stackoverflow.com/a/29754866/1485960
# This file has no magic number, and is not executable.
# THIS IS INTENTIONAL as it should never be executed, only sourced.
#####################################################################

# PO_SHORT_MAP and PO_LONG_MAP must be declared in the calling script, e.g.:
#
# --
# declare -A PO_SHORT_MAP
# PO_SHORT_MAP["d::"]="DEBUG=1"
# PO_SHORT_MAP["v"]="VERBOSE"
# PO_SHORT_MAP["f"]="FORCE"
#
# declare -A PO_LONG_MAP
# PO_LONG_MAP["output:"]="OUTPUT"
# PO_LONG_MAP["input:"]="INPUT"
# PO_LONG_MAP["verbose"]="VERBOSE"
# --
#
# A single colon in the key indicates that a value *must* be provided, and a
# double colon indicates that a value *may* be provided. Otherwise the option
# takes no value. This is the standard behaviour of enhanced getopt.
#
# The map values are the names of the shell variables to which the command-line
# values will be assigned. If the map value contains an assignment, it defines
# the default value of the variable when the command line option is provided
# with no value. Default values must only be used with double-colon keys.
#
# If a no-value option is supplied, the corresponding variable is set to
# "true". A no-value long option "<OPTION>" implies the existence of a no-value
# inverse long option of the form "--no-<OPTION>", which sets the corresponding
# variable to "false".

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "Enhanced getopt not found!"
    exit 1
fi

__PO__set_var_with_default() {
    local __PO__var_with_default="$1"
    local __PO__value="$2"
    # split on `=` into variable and default value
    __PO__variable="${__PO__var_with_default%=*}"
    __PO__default="${__PO__var_with_default#${__PO__variable}}"
    __PO__default="${__PO__default#=}"
    # if we have been passed a value, set the variable to it,
    # otherwise to the default (if that was provided)
    if [[ $__PO__value ]]; then
        eval $__PO__variable="$__PO__value"
    elif [[ $__PO_default ]]; then
        eval $__PO__variable="$__PO__default"
    fi
}

for __PO__key in "${!PO_SHORT_MAP[@]}"; do
    if [[ "${PO_SHORT_MAP[$__PO__key]%=*}" != "${PO_SHORT_MAP[$__PO__key]}" && \
        "${__PO__key%::}" == "${__PO__key}" ]]; then
        # sanity failure!
        echo "PANIC: non-optional key '$__PO__key' must not have a default value"
        exit 4
    fi
done

declare -A __PO__LONG_INVERSES
for __PO__key in "${!PO_LONG_MAP[@]}"; do
    if [[ "${PO_LONG_MAP[$__PO__key]%=*}" != "${PO_LONG_MAP[$__PO__key]}" && \
        "${__PO__key%::}" == "${__PO__key}" ]]; then
        # sanity failure!
        echo "PANIC: non-optional key '$__PO__key' must not have a default value"
        exit 4
    fi
    if [[ "$__PO__key" == "${__PO__key%:}" ]]; then
        # key takes no value, therefore we can support no-<key>
        __PO__LONG_INVERSES["no-$__PO__key"]="${PO_LONG_MAP[$__PO__key]}"
    fi
done

# concatenate option hash keys and invoke enhanced getopt on ARGV
! __PO__PARSED=$(getopt \
    -o $(IFS="";echo "${!PO_SHORT_MAP[*]}") \
    -l $(IFS=,;echo "${!PO_LONG_MAP[*]}","${!__PO__LONG_INVERSES[*]}") \
    --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

# `set` reloads ARGV from __PO_PARSED; `--` forbids set from consuming options
# `eval` parses the embedded single quotes in enhanced-getopt's output
eval set -- "$__PO__PARSED"

# we have now reconstituted ARGV in canonical form, so we can consume in order
while true; do
    if [[ "$1" == "--" ]]; then
        # stop processing options
        shift
        break
    fi
    for __PO__key in "${!PO_SHORT_MAP[@]}"; do
        # strip trailing colon(s)
        __PO__opt="${__PO__key%%:*}"
        __PO__variable="${PO_SHORT_MAP[$__PO__key]}"
        if [[ "$1" == "-$__PO__opt" ]]; then
            if [[ "$__PO__opt" == "$__PO__key" ]]; then
                eval ${__PO__variable}="true"
                shift
                continue 2
            else
                __PO__set_var_with_default "${__PO__variable}" "$2"
                shift 2
                continue 2
            fi
        fi
    done
    for __PO__key in "${!PO_LONG_MAP[@]}"; do
        # strip trailing colon(s)
        __PO__opt="${__PO__key%%:*}"
        __PO__variable="${PO_LONG_MAP[$__PO__key]}"
        if [[ "$1" == "--$__PO__opt" ]]; then
            if [[ "$__PO__opt" == "$__PO__key" ]]; then
                eval ${__PO__variable}="true"
                shift
                continue 2
            else
                __PO__set_var_with_default "${__PO__variable}" "$2"
                shift 2
                continue 2
            fi
        elif [[ "$__PO__opt" == "$__PO__key" && "$1" == "--no-$__PO__opt" ]]; then
            eval ${__PO__variable}="false"
            shift
            continue 2
        fi
    done
    echo "PANIC when parsing options, aborting"
    exit 3
done
