#!/bin/bash
# This script uses order_svc.sh and print only the GUID in stdout
# mandatory env variables:
# - credentials  (username:password)
# - uri

set -ue -o pipefail
ORIG="$(cd $(dirname "$0")/..; pwd)"

. "${ORIG}/common.sh"

# Env variables
: "${credentials?"credentials not defined"}"
: "${uri?"uri not defined"}"

export username=$(echo $credentials | cut -d: -f1)
export password=$(echo $credentials | cut -d: -f2)

service_request_id=$(${ORIG}/order_svc.sh -y "$@" |jq -r '.results[].id')

for i in $(seq 20); do
    status=$(cfget "${uri}/api/service_requests/${service_request_id}" \
                 | jq -r '.request_state + "-" + .message')

    if [ "$status" = "active-In Process" ]; then
        break
    fi

    sleep "$i"
done

get_token

# grab last env, export service_id for next job in pipeline
service_id=$("${ORIG}/get_svc.sh" | sort -n | tail -n1 | cut -d' ' -f 1)

# workaround to get GUID: wait for the name to be changed
# (until guid is set back into the service_request, so it can be query properly
# using service_request_id)

for i in $(seq 30); do
    GUID=$("${ORIG}/get_svc.sh" \
               | sort -n | tail -n1 \
               | perl -pe 'if (/-[\w\d]+$/) {s/.*-([\d\w]+)$/$1/} else {$_ = ""}')
    if [ -n "$GUID" ]; then
        break
    fi

    sleep "$i"
done

[ -n "${GUID}" ]
echo "${GUID}"
