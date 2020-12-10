# shellcheck disable=SC2148
certinfo() { (
  use swine

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
    input=$(perl -pe 's[\\][\\\\]g;s["][\\"]g' <<< "$input")
    printf "%s" "$input"
  }

  # https://stackoverflow.com/a/3352015/1485960
  trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf "%s" "$var"
  }

  getpara() {
    local stream="$1"
    local term="$2"
    local out
    out=$(grep -C1 "$term" <<< "$stream"|tail -1)
    out=$(trim "$out")
    printf "%s" "$out"
  }

  getline() {
    local stream="$1"
    local term="$2"
    local out
    out=$(grep "$term" <<< "$stream")
    out=$(trim "${out##*"${term}"}")
    if [[ ! $out ]]; then
        # Sometimes x509 prints the value on the next line. Handle it.
        out=$(getpara "$stream" "$term")
    fi
    printf "%s" "$out"
  }

  # Convert a selection of PEM fields into JSON format
  pem2json() {
    local ca x509text end
    local expired="no"
    x509text=$(openssl x509 -text <<< "$1")
    ca=$(getline "$x509text" "X509v3 Authority Key Identifier:")
    end=$(getline "$x509text" "  Not After :")
    if [[ $(date +%s --date "$end") -lt $(date +%s) ]]; then
        expired="yes"
    fi
    cat <<EOF
{
"subject": "$(jsonescape "$(getline "$x509text" "  Subject:")")",
"issuer": "$(jsonescape "$(getline "$x509text" "Issuer:")")",
"san": "$(getline "$x509text" "X509v3 Subject Alternative Name:")",
"serial": "$(getline "$x509text" "Serial Number:")",
"id": "$(getline "$x509text" "X509v3 Subject Key Identifier:")",
"ca": "${ca#keyid:}",
"start": "$(getline "$x509text" "  Not Before:")",
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
    local transcript numcerts
    transcript="$(openssl s_client -showcerts -connect "$url" </dev/null 2>/dev/null)"
    numcerts=$(grep --count "^-----BEGIN CERTIFICATE-----" <<< "$transcript")
    for count in $(seq 1 "$numcerts"); do
        local output
        output=$(echo "$transcript" | count="$count" perl -e \
        '$count=$ENV{"count"};
        while(<>) {
            if(/-----BEGIN CERTIFICATE-----/) {$count--};
            if($count==0) {print;}
        }')
        json[${#json[*]}]="\"cert$count\": $(pem2json "$output")"
    done
    printf "%s" "\"$url\": { \"_type\": \"url\", $(IFS=, ; echo "${json[*]:-}") }"
  }

  parsejks() {
    local keystore="$1"
    local json=()
    local aliases
    aliases=$(keytool -keystore "$keystore" -list </dev/null 2>/dev/null|grep -C1 "Certificate fingerprint"|head -1|awk -F, '{print $1}')
    for alias in $aliases; do
        local output
        output=$(keytool -keystore "$keystore" -exportcert -rfc -alias "$alias" </dev/null 2>/dev/null)
        json[${#json[*]}]="\"$alias\": $(pem2json "$output")"
    done
    printf "%s" "\"$keystore\": { \"_type\": \"jks\", $(IFS=, ; echo "${json[*]:-}") }"
  }

  parsepem() {
    local pemfile="$1"
    local json=()
    local numcerts
    numcerts=$(grep --count "^-----BEGIN CERTIFICATE-----" "$pemfile")
    for count in $(seq 1 "$numcerts"); do
        local output
        output=$(count="$count" perl -e \
        '$count=$ENV{"count"};
        while(<>) {
             if(/-----BEGIN CERTIFICATE-----/) {$count--};
             if($count==0) {print;}
        }' < "$pemfile")
        json[${#json[*]}]="\"cert$count\": $(pem2json "$output")"
    done
    printf "%s" "\"$pemfile\": { \"_type\": \"pem\", $(IFS=, ; echo "${json[*]:-}") }"
  }

  ####

  case $1 in

  probe)
    shift
    [[ $1 ]] || usage
    json_total=()
    for url in "$@"; do
        json_total[${#json_total[*]}]=$(parseconn "$url")
    done
    say "{ $(IFS=, ; echo "${json_total[*]:-}") }"
    ;;

  list)
    shift
    [[ $1 ]] || usage
    json_total=()
    for filename in "$@"; do
        if file "$filename" | grep -q "Java KeyStore"; then
            json_total[${#json_total[*]}]=$(parsejks "$filename")
        elif grep -q "^-----BEGIN CERTIFICATE-----" "$filename"; then
            json_total[${#json_total[*]}]=$(parsepem "$filename")
        elif grep -q "^-----BEGIN (ENCRYPTED )?PRIVATE KEY-----" "$filename"; then
            json_total[${#json_total[*]}]="\"$filename\": { \"_type\": \"privkey\"}"
        else
            json_total[${#json_total[*]}]="\"$filename\": { \"_type\": \"unknown\"}"
        fi
    done
    say "{ $(IFS=, ; echo "${json_total[*]:-}") }"
    ;;

  *)
    usage
    ;;

  esac
) }
