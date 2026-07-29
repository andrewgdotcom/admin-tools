# shellcheck disable=SC2148

if ! command -v curl >/dev/null 2>&1; then
    echo "This utility requires curl"
    exit 1
fi

apt-repo() { (
  use strict
  use utils

  CURL_FLAGS="-LSsf"

  SOURCES_DIR=/etc/apt/sources.list.d
  BASENAME=$(basename "$0")

  usage() {
    cat <<EOF
Usage: $BASENAME add REPO_NAME "REPO_CONFIG" PGPKEY_URL
       $BASENAME remove REPO_NAME

A utility to safely add an APT repository with a PGP signing key, while
avoiding the unsafe use of 'curl PGPKEY_URL | apt-key add -'

REPO_NAME is a unique local identifier for the repo.

REPO_CONFIG is the full description of the repo that should be added to the
sources.list file, e.g. "deb http://ftp.debian.org/debian stable main".
Since this will usually contain spaces, it must be enclosed in quotes.

PGPKEY_URL is a URL from which to download the signing key of the repo.

This tool implements the safe third-party repo method as described in
https://wiki.debian.org/DebianRepository/UseThirdParty
EOF
  }

  if [[ ! ${2:-} ]]; then
    usage
    exit 1
  fi

  REPO_NAME="$2"
  SOURCES_FILE="$SOURCES_DIR/$REPO_NAME".list
  PGPKEY_FILE="$SOURCES_DIR/.$REPO_NAME".pgp

  case "$1" in

  "add")

    if [[ ! ${4:-} || ${5:-} ]]; then
      usage
      exit 1
    fi

    REPO_CONFIG="$3"
    PGPKEY_URL="$4"

    if [[ -f $SOURCES_FILE || -f $PGPKEY_FILE ]]; then
      echo "Unable to create files; repo already configured!"
      exit 2
    fi

    ARCH=$(dpkg --print-architecture)
    # normalise whitespace
    REPO_CONFIG=$(sed 's/^\s*//; s/\s*$//; s/\s\s*/ /g' <<< "$REPO_CONFIG")
    # strip any leading "deb" from REPO_CONFIG; we put it back later.
    REPO_CONFIG="${REPO_CONFIG#deb }"
    # strip any options and store them, we will put them back too.
    if [[ $REPO_CONFIG =~ ^\[([^]]+)\]\ (.*)$ ]]; then
      REPO_OPTIONS="${BASH_REMATCH[1]}"
      REPO_CONFIG="${BASH_REMATCH[2]}"
    fi
    : ${REPO_OPTIONS:=arch=$ARCH}

    # sanity test to ensure we have a URL where we expect it
    repo_url="${REPO_CONFIG%% *}"
    if [[ "${repo_url%://*}" == "${repo_url}" ]]; then
        die 3 "'$repo_url' is not a URL"
    fi

    cat <<EOF >"$SOURCES_FILE"
# Created with: $0 add $2 "$3" $4
# To clean up use: $0 remove $2
deb [$REPO_OPTIONS signed-by=$PGPKEY_FILE] $REPO_CONFIG
EOF

    TMPFILE=$(mktemp)
    curl $CURL_FLAGS -o "$TMPFILE" "$PGPKEY_URL"
    if grep -q "^-----BEGIN PGP" "$TMPFILE"; then
      gpg --dearmor < "$TMPFILE" > "$PGPKEY_FILE"
      rm "$TMPFILE"
    else
      mv "$TMPFILE" "$PGPKEY_FILE"
    fi

    # fix permissions
    chown root:root "$PGPKEY_FILE" "$SOURCES_FILE"
    chmod 644 "$PGPKEY_FILE" "$SOURCES_FILE"

    ;;

  "remove")

    if [[ ! ${2:-} || ${3:-} ]]; then
      usage
      exit 1
    fi

    if [[ ! -f $SOURCES_FILE && ! -f $PGPKEY_FILE ]]; then
      echo "Unable to delete files; repo not configured!"
      exit 2
    fi

    rm "$SOURCES_FILE" "$PGPKEY_FILE" || true

    ;;

  * )

    usage
    exit 2
    ;;

  esac
) }
