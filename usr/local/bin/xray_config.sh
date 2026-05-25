#!/usr/local/bin/bash

XRAY_CONFIG='/usr/local/etc/xray-config.json'

LOGLEVEL='warning'

INBOUND_PROTOCOL='vless'
INBOUND_LISTEN='0.0.0.0'
INBOUND_PORT=443

echo 'Enter uuid:'
read -r CLIENT_ID

CLIENT_FLOW='xtls-rprx-vision'
SETTINGS_DECRYPTION='none'

STREAM_NETWORK='tcp'
STREAM_SECURITY='reality'

echo 'Enter short id:'
read -r REALITY_SHORTID

echo 'Enter private key:'
read -sr REALITY_PRIVATEKEY

SERVER_NAME='google.com'
REALITY_DEST="www.${SERVER_NAME}:443"
REALITY_SHOW='false'
REALITY_XVER=0

SNIFFING_ENABLED='true'

MESSAGE="{
 \"log\":{\"loglevel\":\"${LOGLEVEL}\"},
 \"inbounds\":[{
  \"sniffing\":{
   \"enabled\":${SNIFFING_ENABLED},
   \"destOverride\":[\"http\", \"tls\"]
  },
  \"streamSettings\":{
   \"network\":\"${STREAM_NETWORK}\",
   \"security\":\"${STREAM_SECURITY}\",
   \"realitySettings\":{
    \"show\":${REALITY_SHOW},
    \"dest\":\"${REALITY_DEST}\",
    \"xver\":${REALITY_XVER},
    \"serverNames\":[\"www.${SERVER_NAME}\", \"${SERVER_NAME}\"],
    \"privateKey\":\"${REALITY_PRIVATEKEY}\",
    \"shortIds\":[\"${REALITY_SHORTID}\"]
   }
  },
  \"settings\":{
   \"clients\":[{
    \"id\":\"${CLIENT_ID}\",
    \"flow\":\"${CLIENT_FLOW}\"
   }],
   \"decryption\":\"${SETTINGS_DECRYPTION}\"
  },
  \"port\":\"${INBOUND_PORT}\",
  \"listen\":\"${INBOUND_LISTEN}\",
  \"protocol\":\"${INBOUND_PROTOCOL}\"
 }],
 \"outbounds\":[
  {\"protocol\":\"freedom\", \"tag\":\"direct\"}
 ]
}"

printf "${MESSAGE}" > "${XRAY_CONFIG}"
if test $? -ne 0; then
 echo 'Write config error!' >&2; exit 1; fi
