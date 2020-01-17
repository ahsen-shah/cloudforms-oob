#!/bin/bash
# safety options
set -e -o pipefail

# CloudForms Out of the Browser - List accessible catalog items - Guillaume Coré <gucore@redhat.com>

ORIG="$(cd "$(dirname "$0")" || exit; pwd)"

# shellcheck source=common.sh
. "${ORIG}/common.sh"

# Dont touch from here on

usage() {
    echo "Error: Usage $0 [-u <username>] [ -w <uri> ] [ -i <id> ]"
}

while getopts nu:w: FLAG; do
    case $FLAG in
        u) username="$OPTARG";;
        w) uri="$OPTARG";;
        *) usage;exit;;
    esac
done

if ! command -v jq > /dev/null; then
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

cfget \
    "${uri}/api/service_catalogs?expand=resources,service_templates" \
    | jq -r '.resources[]|{name: .name, services: .service_templates.resources[].name}[]' \
    | while read -r c; do read -r s; echo "${c} / ${s}"; done
