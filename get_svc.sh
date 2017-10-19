#!/bin/bash
# safety options
set -e -o pipefail

# CloudForms Get Services - Patrick Rutledge <prutledg@redhat.com>
# CloudForms Out of the Browser - Guillaume Coré <gucore@redhat.com>

ORIG="$(cd "$(dirname "$0")" || exit; pwd)"

# shellcheck source=common.sh
. "${ORIG}/common.sh"

# Dont touch from here on

usage() {
    echo "Error: Usage $0 [-u <username>] [ -w <uri> ] [ -i <id> ]"
}

while getopts nu:w:i: FLAG; do
    case $FLAG in
        u) username="$OPTARG";;
        w) uri="$OPTARG";;
        i) id="$OPTARG";;
        *) usage;exit;;
    esac
done

if ! which jq > /dev/null; then
    echo >&2 "please install jq"
    exit 2
fi

if [ -z "$uri" ]; then
    echo >&2 -n "Enter CF URI: "
    read -r uri
fi

if [ -z "$username" ]; then
    echo >&2 -n "Enter CF Username: "
    read -r username
fi

if [ -z "$password" ]; then
    echo >&2 -n "Enter CF Password: "
    stty -echo
    read -r password
    stty echo
    echo
fi

my_id=$(get_my_user_id)

if [ -n "$id" ]; then
    cfget \
        "/api/services/${id}?attributes=all\&filter\[\]=evm_owner_id=${my_id}\&expand=resources" \
        | jq .
else
    cfget \
        "/api/services?attributes=name\&filter\[\]=evm_owner_id=${my_id}\&expand=resources" \
        | jq -r '.resources[]|(.id|tostring) + " " + .name'
fi
