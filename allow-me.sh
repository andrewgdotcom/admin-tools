# A quick script to explicitly allow ssh connections in from the calling IP
    
allow-me() { (
    use swine
    use parse-opt
    
    PO_SIMPLE_PARAMS="COMMENT"
    eval $(parse-opt-simple)
    
    : ${COMMENT:="added by $0"}
    
    if [[ "$@" ]]; then
        for source in $@; do
            ufw allow to any app OpenSSH from "${source}" comment "${COMMENT}"
        done
    elif [[ ${SSH_CONNECTION:-} ]]; then
        ssh_connection_array=($SSH_CONNECTION)
        ufw allow to any app OpenSSH from "${ssh_connection_array[0]}" comment "${COMMENT}"
    else
        die 1 "No IPs supplied and could not guess connection details"
    fi
) }
