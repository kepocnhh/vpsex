#!/usr/local/bin/bash

TELEPROXY_PORT=443
TELEPROXY_DOMAIN='www.google.com'

###

TELEPROXY_DOMAIN_HASH="$(echo -n "${TELEPROXY_DOMAIN}" | openssl dgst -binary -sha256 | xxd -l 8 -p)"
MTPROTO_SECRETS_PATH="${HOME}/.config/mtproto/mtproto_secrets-${TELEPROXY_DOMAIN_HASH}.txt"

ISSUER="${MTPROTO_SECRETS_PATH}"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

TELEPROXY_SECRETS_FLAGS=''
MTPROTO_SECRETS=($(cat "${ISSUER}"))

if test $? -ne 0; then
 echo 'Read secrets error!'; exit 1
elif test ${#MTPROTO_SECRETS[@]} == 0; then
 echo 'No secrets!'; exit 1
else
 for it in ${MTPROTO_SECRETS[@]}; do
  if test "${#it}" != '32'; then
   echo 'Wrong secret!'; exit 1; fi
  TELEPROXY_SECRETS_FLAGS+=" -S ${it}"
 done
fi

###

MTPROTO_PROXY_SECRET_PATH="${HOME}/.config/mtproto/mtproto_secret.bin"

MTPROTO_PROXY_SECRET_URL='https://core.telegram.org/getProxySecret'

ISSUER='/tmp/mtproto_secret.bin'
rm "${ISSUER}"
curl -m 4 -s "${MTPROTO_PROXY_SECRET_URL}" -o "${ISSUER}"

if test $? -ne 0; then
 echo "Get proxy secret error!"
elif [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"
else
 mv "${ISSUER}" "${MTPROTO_PROXY_SECRET_PATH}"
fi

ISSUER="${MTPROTO_PROXY_SECRET_PATH}"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

###

MTPROTO_PROXY_CONFIG_PATH="${HOME}/.config/mtproto/mtproto_config.txt"

MTPROTO_PROXY_CONFIG_URL='https://core.telegram.org/getProxyConfig'

ISSUER='/tmp/mtproto_config.txt'
rm "${ISSUER}"
curl -m 4 -s "${MTPROTO_PROXY_CONFIG_URL}" -o "${ISSUER}"

if test $? -ne 0; then
 echo "Get proxy secret error!"
elif [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"
else
 mv "${ISSUER}" "${MTPROTO_PROXY_CONFIG_PATH}"
fi

ISSUER="${MTPROTO_PROXY_CONFIG_PATH}"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

###

${HOME}/.local/bin/teleproxy \
 -u "${USER}" \
 -H $TELEPROXY_PORT \
 ${TELEPROXY_SECRETS_FLAGS} \
 --aes-pwd "${MTPROTO_PROXY_SECRET_PATH}" "${MTPROTO_PROXY_CONFIG_PATH}" \
 -D "${TELEPROXY_DOMAIN}"
