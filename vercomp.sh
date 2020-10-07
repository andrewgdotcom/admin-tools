# A version string comparator blatantly stolen from stack overflow
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash

# Exits with code 0 for equality, 1 when $1 > $2 and 2 when $1 < $2

vercomp() { (
    use swine

    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local ver1=($1)
    local ver2=($2)
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
            return 1
        fi
        if ((10#${ver1[$i]} < 10#${ver2[$i]}))
        then
            return 2
        fi
    done
    exit 0
) }
