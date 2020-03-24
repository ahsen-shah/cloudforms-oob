#!/bin/bash
# This script is a wrapper to delete_svc.sh
# mandatory env variables:
# - credentials  (username:password)
# - admin_credentials  (username:password)
# - uri

set -ue -o pipefail
ORIG="$(cd "$(dirname "$0")"/..; pwd)"

# shellcheck source=common.sh
. "${ORIG}/common.sh"

# Env variables
: "${credentials?"credentials not defined"}"
: "${admin_credentials?"admin_credentials not defined"}"
: "${uri?"uri not defined"}"

username=$(echo "$credentials" | cut -d: -f1)
export username
password=$(echo "$credentials" | cut -d: -f2)
export password
admin_username=$(echo "$admin_credentials" | cut -d: -f1)
export admin_username
admin_password=$(echo "$admin_credentials" | cut -d: -f2)
export admin_password


guid="$1"
# GUID is not empty string
[ -n "${guid}" ]
# GUID should be at least 4 chars
[ "${#guid}" -ge 4 ]

# Get svc id and name (using regular user).
# Then delete using admin account. Why delete using admin account ?
# Because there is a limitation in the cloudforms API:
# you can order a service with regular user,
# but you cannot retire the service. This is a workaround.

MAX_RETRIES=4
retry=0
set +e
while [ $retry -lt $MAX_RETRIES ]; do
    "${ORIG}/get_svc.sh" \
        | grep -E "${guid}(\$|_COMPLETED\$|_FAILED\$)" \
        | grep "${username}" \
        | (export username=${admin_username}
           export password=${admin_password}
           "${ORIG}/delete_svc.sh")

    RET=$?
    [ $RET = 0 ] && break

    echo "Delete failed. Retrying (${retry})." >&2
    retry=$((retry + 1))
    sleep $((2 ** retry))
done

exit $RET
