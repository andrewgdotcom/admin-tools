# shellcheck disable=SC2148
# A version string comparator blatantly stolen from stack overflow
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash

# Exits with code 0 for equality, 1 when $1 > $2 and 2 when $1 < $2
__vercomp_eq=0
__vercomp_gt=1
__vercomp_lt=2

vercomp() { (
    use strict
    use utils

    if [[ "$1" == "$2" ]]
    then
        exit $__vercomp_eq
    fi
    local ver1 ver2
    IFS=. read -r -a ver1 <<< "$1"
    IFS=. read -r -a ver2 <<< "$2"
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[$i]:-} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[$i]=0
        fi
        if ((10#${ver1[$i]} > 10#${ver2[$i]}))
        then
            exit $__vercomp_gt
        fi
        if ((10#${ver1[$i]} < 10#${ver2[$i]}))
        then
            exit $__vercomp_lt
        fi
    done
    exit $__vercomp_eq
) }

vercomp.eq() { vercomp "$@" ; }
vercomp.gt() { __vercomp_err=0; vercomp "$@" || __vercomp_err=$?; [[ $__vercomp_err == $__vercomp_gt ]]; }
vercomp.ge() { __vercomp_err=0; vercomp "$@" || __vercomp_err=$?; [[ $__vercomp_err != $__vercomp_lt ]]; }
vercomp.lt() { __vercomp_err=0; vercomp "$@" || __vercomp_err=$?; [[ $__vercomp_err == $__vercomp_lt ]]; }
vercomp.le() { __vercomp_err=0; vercomp "$@" || __vercomp_err=$?; [[ $__vercomp_err != $__vercomp_gt ]]; }
