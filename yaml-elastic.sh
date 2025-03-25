# shellcheck disable=SC2148
# Tool for extracting information from an elasticsearch-style yaml file.
# Requires @kislyuk's yq (the one from python-pip, not the other one)

_KISLYUK_YQ=$(which yq || echo "/usr/local/bin/yq")
if [[ ! -x $_KISLYUK_YQ ]] || ! $_KISLYUK_YQ --help | grep -q kislyuk/yq; then
    echo "yaml-elastic requires https://github.com/kislyuk/yq under /usr/local/bin" >&2
    echo "This can be installed using python3-pip" >&2
    exit 1
fi

yaml-expand-forms() { (
    use strict
    use utils

    # recursively enumerate all the collapsed forms of a json entity
    # we leave out the outermost double quotes at each stage, to save time
    # adding and then re-stripping them at each recursion stage
    # this means that the final output is missing its outermost double quotes,
    # so we have to add them afterwards
    local head=${1%%.*}
    local tail=${1#*.}
    if [[ "$tail" != "$1" ]]; then
        for tail_form in $(yaml-expand-forms "$tail"); do
            echo "$head\".\"$tail_form"
            echo "$head.$tail_form"
        done
    else
        echo "$head"
    fi
) }

yaml-extract() { (
    use strict
    use utils

    # perform a recursive tree search for all collapsed forms of the search term
    local key="$1"
    local file="$2"
    local result=null
    for searchterm in $(yaml-expand-forms "$key"); do
        # remember to add the double quotes, see expand_forms above
        result=$($_KISLYUK_YQ ".\"$searchterm\"" "$file")
        if [[ "$result" != null ]]; then
            # Strip quotes from the value
            result="${result#\"}"
            result="${result%\"}"
            echo "$result"
            return
        fi
    done
    echo
) }

yaml-replace() { (
    use strict
    use utils

    # perform a recursive tree search for all collapsed forms of the search term
    local key=${1%%=*}
    local value="${1#*=}"
    local file=$2
    local result=null
    local modified=
    for searchterm in $(yaml-expand-forms "$key"); do
        # remember to add the double quotes, see expand_forms above
        result=$($_KISLYUK_YQ ".\"$searchterm\"" "$file")
        if [[ "$result" != null ]]; then
            cp "$file" "${file}.bak"
            $_KISLYUK_YQ -y ".\"$searchterm\" |= \"$value\"" "${file}.bak" > "$file"
            modified=true
            break
        fi
    done
    if [[ ! $modified && "${3:-}" == "or-add" ]]; then
        cp "$file" "${file}.bak"
        $_KISLYUK_YQ -y ".\"$key\" |= \"$value\"" "${file}.bak" > "$file"
    fi
) }

yaml-delete() { (
    use strict
    use utils

    # perform a recursive tree search for all collapsed forms of the search term
    local key=$1
    local file=$2
    local result=null
    for searchterm in $(yaml-expand-forms "$key"); do
        # remember to add the double quotes, see expand_forms above
        result=$($_KISLYUK_YQ ".\"$searchterm\"" "$file")
        if [[ "$result" != null ]]; then
            cp "$file" "${file}.bak"
            $_KISLYUK_YQ -y "del(.\"$searchterm\")" "${file}.bak" > "$file"
            return
        fi
    done
) }
