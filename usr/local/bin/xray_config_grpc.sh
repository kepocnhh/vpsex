#!/usr/local/bin/bash

if [[ $# -lt 3 ]]; then
 echo 'Wrong arguments!' >&2; exit 1; fi

XRAY_CONFIG_PATH="$1"

if [[ -z "${XRAY_CONFIG_PATH}" ]]; then
 echo 'No dst!' >&2; exit 1
elif [[ -L "${XRAY_CONFIG_PATH}" ]]; then
 echo "\"${XRAY_CONFIG_PATH}\" is a symlink!" >&2; exit 1
elif [[ -e "${XRAY_CONFIG_PATH}" ]]; then
 if [[ -f "${XRAY_CONFIG_PATH}" ]]; then
  echo "\"${XRAY_CONFIG_PATH}\" exists!" >&2; exit 1
 else
  echo "\"${XRAY_CONFIG_PATH}\" is not a file!" >&2; exit 1
 fi
fi

XRAY_CONFIG_SERVICE_NAME_SRC="$2"

if [[ -z "${XRAY_CONFIG_SERVICE_NAME_SRC}" || ! -v "${XRAY_CONFIG_SERVICE_NAME_SRC}" || -z "${!XRAY_CONFIG_SERVICE_NAME_SRC}" ]]; then
 echo 'Wrong service name!' >&2; exit 1; fi

XRAY_CONFIG_LOGLEVEL='warning' # todo
XRAY_CONFIG_OUTBOUND_PROTOCOL='freedom'
XRAY_CONFIG_OUTBOUND_TAG='direct'
XRAY_CONFIG_INBOUND_LISTEN='127.0.0.1'
XRAY_CONFIG_INBOUND_PORT='10001'
XRAY_CONFIG_INBOUND_PROTOCOL='vless'

XRAY_CONFIG_JSON='{}'
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".log.loglevel=\"${XRAY_CONFIG_LOGLEVEL}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".outbounds[0].protocol=\"${XRAY_CONFIG_OUTBOUND_PROTOCOL}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".outbounds[0].tag=\"${XRAY_CONFIG_OUTBOUND_TAG}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].listen=\"${XRAY_CONFIG_INBOUND_LISTEN}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].port=${XRAY_CONFIG_INBOUND_PORT}")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].protocol=\"${XRAY_CONFIG_INBOUND_PROTOCOL}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].streamSettings.network=\"grpc\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].streamSettings.security=\"none\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].streamSettings.grpcSettings.serviceName=\"${!XRAY_CONFIG_SERVICE_NAME_SRC}\"")"
XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].settings.decryption=\"none\"")"

for ((i=3; i<=$#; i++)); do
 XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].settings.clients[$((i-3))].id=\"${!i}\"")"
 XRAY_CONFIG_JSON="$(printf '%s' "${XRAY_CONFIG_JSON}" | yq -p=json -o=json ".inbounds[0].settings.clients[$((i-3))].email=\"u$((i-2))\"")"
done

printf '%s' "${XRAY_CONFIG_JSON}" > "${XRAY_CONFIG_PATH}"
