certinfo() { (
  use swine

  # X509 tooling is crap. keytool is crap. openssl is crap. It's all crap.
  # But we still have to deal with the hateful stuff. So here goes.
  # How to make the worst tools in the known universe *usable*...

  usage() {
    cat <<EOF
Usage: $0 <command> [<options> ...]

Where <command> is one of:

probe <url> [<url> ...]
    Connect to each <url> and list the certificates in use

list <file> [<file> ...]
    Parse each <file> and list the certificates therein. PEM and JKS formats
    are supported (and automatically detected).
EOF
    exit 1
  }

  jsonescape() {
    local input="$*"
    input=$(perl -pe 's[\\][\\\\]g;s["][\\"]g' <<< $input)
    echo -n "$input"
  }

  # https://stackoverflow.com/a/3352015/1485960
  trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
  }

  getpara() {
    local stream="$1"
    local term="$2"
    local out=$(echo "$stream"|egrep -C1 "$term"|tail -1)
    out=$(trim "$out")
    echo -n "$out"
  }

  getline() {
    local stream="$1"
    local term="$2"
    local out=$(echo "$stream" | egrep "$term")
    out=$(trim "${out##*"${term}"}")
    if [[ ! $out ]]; then
        # Sometimes x509 prints the value on the next line. Handle it.
        out=$(getpara "$stream" "$term")
    fi
    echo -n "$out"
  }

  # Convert a selection of PEM fields into JSON format
  pem2json() {
    local x509text=$(echo "$1" | openssl x509 -text)
    local subject=$(jsonescape $(getline "$x509text" "  Subject:"))
    local end=$(getline "$x509text" "  Not After :")
    local start=$(getline "$x509text" "  Not Before:")
    local san=$(getline "$x509text" "X509v3 Subject Alternative Name:")
    local serial=$(getline "$x509text" "Serial Number:")
    local id=$(getline "$x509text" "X509v3 Subject Key Identifier:")
    local ca=$(getline "$x509text" "X509v3 Authority Key Identifier:")
    local issuer=$(jsonescape $(getline "$x509text" "Issuer:"))
    ca="${ca#keyid:}"
    local expired="no"
    if [[ $(date +%s --date "$end") -lt $(date +%s) ]]; then
        expired="yes"
    fi
    cat <<EOF
{
"subject": "$subject",
"issuer": "$issuer",
"san": "$san",
"serial": "$serial",
"id": "$id",
"ca": "$ca",
"start": "$start",
"end": "$end",
"expired": "$expired"
}
EOF
  }

  parseconn() {
    local url="$1"
    local json=()
    url=${url##https://}
    url=${url%%/*}
    if [[ "${url%:*}" == "$url" ]]; then
        url="$url:443"
    fi
    local transcript="$(openssl s_client -showcerts -connect $url </dev/null 2>/dev/null)"
    local numcerts=$(echo "$transcript" | egrep --count "^-----BEGIN CERTIFICATE-----")
    for count in $(seq 1 $numcerts); do
        local output=$(echo "$transcript" | perl -e '$count='$count'; while(<>) { if(/-----BEGIN CERTIFICATE-----/) {$count--}; if($count==0) {print;} }')
        json=("${json[@]}" "\"cert$count\": $(pem2json "$output")")
    done
    echo -n "\"$url\": { \"_type\": \"url\", " $(IFS=, ; echo "${json[*]}") " }"
  }

  parsejks() {
    local keystore="$1"
    local json=()
    local aliases=$(keytool -keystore $keystore -list </dev/null 2>/dev/null|grep -C1 "Certificate fingerprint"|head -1|awk -F, '{print $1}')
    for alias in $aliases; do
        local output=$(keytool -keystore $keystore -exportcert -rfc -alias $alias </dev/null 2>/dev/null)
        json=("${json[@]}" "\"$alias\": $(pem2json "$output")")
    done
    echo -n "\"$keystore\": { \"_type\": \"jks\", " $(IFS=, ; echo "${json[*]}") " }"
  }

  parsepem() {
    local pemfile="$1"
    local json=()
    local numcerts=$(egrep --count "^-----BEGIN CERTIFICATE-----" $pemfile)
    for count in $(seq 1 $numcerts); do
        local output=$(perl -e '$count='$count'; while(<>) { if(/-----BEGIN CERTIFICATE-----/) {$count--}; if($count==0) {print;} }' < $pemfile)
        json=("${json[@]}" "\"cert$count\": $(pem2json "$output")")
    done
    echo -n "\"$pemfile\": { \"_type\": \"pem\", " $(IFS=, ; echo "${json[*]}") " }"
  }

  ####

  case $1 in

  probe)
    shift
    [[ $1 ]] || usage
    json_total=()
    for url in $*; do
        json_total=("${json_total[@]}" "$(parseconn $url)")
    done
    echo "{ " $(IFS=, ; echo "${json_total[*]}") " }"
    ;;

  list)
    shift
    [[ $1 ]] || usage
    json_total=()
    for filename in $*; do
        if file $filename | grep -q "Java KeyStore"; then
            json_total=("${json_total[@]}" "$(parsejks $filename)")
        elif egrep -q "^-----BEGIN CERTIFICATE-----" $filename; then
            json_total=("${json_total[@]}" "$(parsepem $filename)")
        elif egrep -q "^-----BEGIN (ENCRYPTED )?PRIVATE KEY-----" $filename; then
            json_total=("${json_total[@]}" "\"$filename\": { \"_type\": \"privkey\"}")
        else
            json_total=("${json_total[@]}" "\"$filename\": { \"_type\": \"unknown\"}")
        fi
    done
    echo "{ " $(IFS=, ; echo "${json_total[*]}") " }"
    ;;

  *)
    usage
    ;;

  esac
) }
