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
# takes no value. This is the standard behaviour of extended getopt.
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

! __PO__PARSED=$(getopt \
    -o $(IFS="";echo "${!PO_SHORT_MAP[*]}") \
    -l $(IFS=,;echo "${!PO_LONG_MAP[*]}","${!__PO__LONG_INVERSES[*]}") \
    --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$__PO__PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    if [[ "$1" == "--" ]]; then
        shift
        break
    fi
    for __PO__key in "${!PO_SHORT_MAP[@]}"; do
        __PO__opt="${__PO__key%%:*}"
        if [[ "$1" == "-$__PO__opt" ]]; then
            if [[ "$__PO__opt" == "$__PO__key" ]]; then
                eval ${PO_SHORT_MAP[$__PO__key]}="true"
                shift
                continue 2
            else
                if [[ $2 ]]; then
                    eval ${PO_SHORT_MAP[$__PO__key]%=*}="$2"
                else
                    eval ${PO_SHORT_MAP[$__PO__key]}
                fi
                shift 2
                continue 2
            fi
        fi
    done
    for __PO__key in "${!PO_LONG_MAP[@]}"; do
        __PO__opt="${__PO__key%%:*}"
        if [[ "$1" == "--$__PO__opt" ]]; then
            if [[ "$__PO__opt" == "$__PO__key" ]]; then
                eval ${PO_LONG_MAP[$__PO__key]}="true"
                shift
                continue 2
            else
                if [[ $2 ]]; then
                    eval ${PO_LONG_MAP[$__PO__key]%=*}="$2"
                else
                    eval ${PO_LONG_MAP[$__PO__key]}
                fi
                shift 2
                continue 2
            fi
        elif [[ "$__PO__opt" == "$__PO__key" && "$1" == "--no-$__PO__opt" ]]; then
            eval ${PO_LONG_MAP[$__PO__key]}="false"
            shift
            continue 2
        fi
    done
    echo "PANIC when parsing options, aborting"
    exit 3
done
