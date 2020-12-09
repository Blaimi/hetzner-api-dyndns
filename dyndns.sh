#!/bin/bash
# DynDNS Script for Hetzner DNS API by FarrowStrange, extended by Blaimi
# v1.0

set -e

auth_api_token=''
record_ttl='60'
record_type='A'
pub_addr_api_v4='api.ipify.org'
pub_addr_api_v6='api64.ipify.org'

realpath=$(realpath $0)
source ${realpath%/*}/config.sh

display_help() {
  cat <<EOF

exec: ./dyndns.sh -z <Zone ID> -r <Record ID> -n <Record Name>

parameters:
  -z  - Zone ID
  -r  - Record ID
  -n  - Record name

optional parameters:
  -t  - TTL (Default: 60)
  -T  - Record type (Default: A)

help:
  -h  - Show Help 

example:
  .exec: ./dyndns.sh -z 98jFjsd8dh1GHasdf7a8hJG7 -r AHD82h347fGAF1 -n dyn

EOF
  exit 1
}

while getopts ":z:r:n:t:T:h:" opt; do
  case "$opt" in
    z  ) zone_id="${OPTARG}";;
    r  ) record_id="${OPTARG}";;
    n  ) record_name="${OPTARG}";;
    t  ) record_ttl="${OPTARG}";;
    T  ) record_type="${OPTARG}";;
    h  ) display_help;;
    \? ) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
  esac
done

if [[ "${zone_id}" = "" ]]; then 
  echo "Missing option for zone ID: -z <Zone ID>"
  echo "Use -h to display help."
  exit 1
elif [[ "${record_id}" = "" ]]; then
  echo "Mission option for record ID: -r <Record ID>"
  echo "Use -h to display help."
  exit 1
elif [[ "${record_name}" = "" ]]; then
  echo "Mission option for record name: -n <Record Name>"
  echo "Use -h to display help."
  exit 1
fi

if [[ "${auth_api_token}" = "" ]]; then
  echo "No Auth API Token specified. Please reference at the top of the Script."
  exit 1
fi

if [[ "${record_type}" = "AAAA" ]]; then
  echo "Using IPv6 as AAAA record is to be set."
  cur_pub_addr=$(curl -6 -s ${pub_addr_api_v6})
else
  echo "Using IPv4 as record type ${record_type} is not explicitly AAAA."
  cur_pub_addr=$(curl -4 -s ${pub_addr_api_v4})
fi

cur_dyn_addr=`curl -s "https://dns.hetzner.com/api/v1/records/${record_id}" -H 'Auth-API-Token: '${auth_api_token} | cut -d ',' -f 4 | cut -d '"' -f 4`

if [[ $cur_pub_addr == $cur_dyn_addr ]]; then
  echo "DNS record \"${record_name}\" is up to date - nothing to to."
  exit 0
else
  echo "DNS record \"${record_name}\" is no longer valid - updating record" 

  curl -s -X "PUT" "https://dns.hetzner.com/api/v1/records/${record_id}" \
    -H 'Content-Type: application/json' \
    -H 'Auth-API-Token: '${auth_api_token} \
    -d $'{
      "value": "'${cur_pub_addr}'",
      "ttl": '${record_ttl}',
      "type": "'${record_type}'",
      "name": "'${record_name}'",
      "zone_id": "'${zone_id}'"
    }'

  if [[ $? != 0 ]]; then
     echo "Unable to update record: \"${record_name}\""
   else
     echo "DNS record \"${record_name}\" updated successfully"
  fi
fi
