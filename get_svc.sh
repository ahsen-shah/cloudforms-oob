#!/bin/bash
# safety options
set -e -o pipefail

# CloudForms Get Services - Patrick Rutledge <prutledg@redhat.com>
# CloudForms Out of the Browser - Guillaume Coré <gucore@redhat.com>

ORIG=$(cd $(dirname $0); pwd)
. "${ORIG}/common.sh"

# Dont touch from here on

usage() {
    echo "Error: Usage $0 [-u <username>] [ -w <uri> ]"
}

while getopts nu:w: FLAG; do
    case $FLAG in
        n) noni=1;;
        u) username="$OPTARG";;
        w) uri="$OPTARG";;
        *) usage;exit;;
    esac
done

if ! which jq > /dev/null; then
    echo >&2 "please install jq"
    exit 2
fi

if [ -z "$uri" ]; then
    echo >&2 -n "Enter CF URI: "
    read uri
fi

if [ -z "$username" ]; then
    echo >&2 -n "Enter CF Username: "
    read username
fi

if [ -z "$password" ]; then
    echo >&2 -n "Enter CF Password: "
    stty -echo
    read password
    stty echo
    echo
fi

get_token

my_id=$(get_my_user_id)

curl -s \
     -H "X-Auth-Token: ${tok}" \
     -H "Content-Type: application/json" \
     -X GET \
     "${uri}/api/services?attributes=name\&filter\[\]=evm_owner_id=${my_id}\&expand=resources" \
    | jq -r '.resources[]|(.id|tostring) + " " + .name'
