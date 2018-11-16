#!/bin/bash
# This script uses order_svc.sh and print only the GUID in stdout
# mandatory env variables:
# - credentials  (username:password)
# - uri

set -ue -o pipefail
ORIG="$(cd "$(dirname "$0")"/..; pwd)"

# shellcheck source=common.sh
. "${ORIG}/common.sh"

# Env variables
: "${credentials?"credentials not defined"}"
: "${uri?"uri not defined"}"

username=$(echo "$credentials" | cut -d: -f1)
export username
password=$(echo "$credentials" | cut -d: -f2)
export password

service_request_id=$("${ORIG}/order_svc.sh" -y "$@" |jq -r '.results[].id')

for i in $(seq 40); do
    # Use request_tasks to get the service id (destination_id)
    service_id=$(cfget "${uri}/api/service_requests/${service_request_id}/request_tasks?expand=resources" \
          | jq -r '.resources[].destination_id')

    if [ -n "$service_id" -a "$service_id" != "null" ]; then
        break
    fi

    sleep "$i"
done

[ -n "${service_id}" ]

for i in $(seq 30); do
    GUID=$(cfget "${uri}/api/services/${service_id}" \
               | jq -r .name \
               | perl -pe 'if (/-[\w\d]+$/) {s/.*-([\d\w]+)$/$1/} else {$_ = ""}')

    if [ -n "$GUID" ]; then
        break
    fi

    sleep "$i"
done

[ -n "${GUID}" ]
echo "${GUID}"
