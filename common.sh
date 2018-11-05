#!/bin/bash
# get a token from CloudForms, keep the current if it's still valid.
get_token() {
    # init variables to support '-u' mode
    tok=${tok:-''}
    tok_expire_on=${tok_expire_on:-0}

    if [ -n "$tok" ]; then
        # verify it's still valid

        if [ "$tok_expire_on" -gt "$(date +%s)" ]; then
            return
        fi
    fi

    : "${username?"Username not set"}"
    : "${password?"password not set"}"
    : "${uri?"uri not set"}"

    token_info=$(curl "${CURLOPT}" -s --user "${username}:${password}" \
                      -X GET -H "Accept: application/json" \
                      "${uri}/api/auth" \
                     | jq -r '.auth_token + ";" + (.token_ttl|tostring)')

    tok=${token_info%;*}
    tok_ttl=${token_info#*;}

    if [ -z "${tok}" ] || [ -z "${tok_ttl}" ]; then
        echo >&2 "issue with token"
        exit 1
    fi

    export tok
    tok_expire_on=$(date --date="now + ${tok_ttl} seconds" +%s)
    export tok_expire_on
}

# curl shortcut to GET, you have to provide complete URI
cfget() {
    get_token

    curl "${CURLOPT}" -s \
         -H "X-Auth-Token: ${tok}" \
         -H "Content-Type: application/json" \
         -X GET \
         "$@"
}


# curl shortcut to POST, you have to provide complete URI
cfpost() {
    get_token

    curl "${CURLOPT}" -s \
         -H "X-Auth-Token: ${tok}" \
         -H "Content-Type: application/json" \
         -X POST \
         "$@"
}

# Run this as admin
get_my_user_id() {
    cfget \
        "${uri}/api/users?attributes=id,userid,name&filter[]=userid='${username}'&expand=resources" \
        | jq -r ".resources[] | select(.userid == \"${username}\") | .id"
}

json_escape () {
    printf '%s' "$1" | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

