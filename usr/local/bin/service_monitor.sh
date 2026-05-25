#!/usr/local/bin/bash

if test $# -ne 2; then
 echo 'Wrong arguments!'; exit 1; fi

SERVICE_NAME="$1"
TG_CHAT_ID="$2"

if test -z "${SERVICE_NAME}"; then
 echo "Service name \"${SERVICE_NAME}\" is empty!"; exit 1; fi

if [[ ! "${TG_CHAT_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong chat id!'; exit 1; fi

if [[ ! -s "/etc/systemd/system/${SERVICE_NAME}.service" ]]; then
 echo "No service \"${SERVICE_NAME}\"!"; exit 1; fi

SENDER_NAME='org.freedesktop.systemd1'
SENDER_TYPE='signal'
SENDER_MEMBER='PropertiesChanged'
ESCAPED_NAME="${SERVICE_NAME}.service"
ESCAPED_NAME="${ESCAPED_NAME//_/_5f}"
ESCAPED_NAME="${ESCAPED_NAME//./_2e}"
ESCAPED_NAME="${ESCAPED_NAME//@/_40}"
ESCAPED_NAME="${ESCAPED_NAME//-/_2d}"
SENDER_PATH="/org/freedesktop/systemd1/unit/${ESCAPED_NAME}"
SENDER_MATCHER="type='${SENDER_TYPE}',sender='${SENDER_NAME}',path='${SENDER_PATH}',member='${SENDER_MEMBER}'"

IP_ADDRESS="$(hostname -i)"

LAST_ACTIVE_STATE=$(systemctl show "${SERVICE_NAME}.service" -p ActiveState --value)
LAST_SUB_STATE=$(systemctl show "${SERVICE_NAME}.service" -p SubState --value)
LAST_TIMESTAMP_MICROSECONDS=$(date +%s)000000

while read -r json; do
 [[ "${json}" == *ActiveState*  || "${json}" == *SubState* ]] || continue
 [[ "${json}" != *"${SENDER_PATH}"* ]] && continue
 CURRENT_PATH="$(echo "${json}" | yq -re '.path // ""' 2>/dev/null)" || continue
 [[ "${CURRENT_PATH}" == "${SENDER_PATH}" ]] || continue
 #
 TIMESTAMP_MICROSECONDS="$(echo "${json}" | yq -e '.payload.data[1].StateChangeTimestamp.data // -1' 2>/dev/null)" || continue
 [[ "${TIMESTAMP_MICROSECONDS}" =~ ^[1-9][0-9]+$ ]] || continue
 [[ $TIMESTAMP_MICROSECONDS -le $LAST_TIMESTAMP_MICROSECONDS ]] && continue
 TIMESTAMP_SECONDS=$(( TIMESTAMP_MICROSECONDS / 1000000 ))
 MILLISECONDS=$(( TIMESTAMP_MICROSECONDS % 1000000 / 1000 ))
 DATE_TIME="$(TZ='utc' LC_ALL=C date -d "@$TIMESTAMP_SECONDS" +'%Y/%m/%d %H:%M:%S').$(printf '%03d' "${MILLISECONDS}")"
 #
 if [[ "${json}" == *ActiveState* ]]; then
  ACTIVE_STATE="$(echo "${json}" | yq -e '.payload.data[1].ActiveState.data // ""' 2>/dev/null)" || continue
  [[ -z "${ACTIVE_STATE}" ]] && continue
  [[ "${LAST_ACTIVE_STATE}" == "${ACTIVE_STATE}" ]] && continue
  LAST_ACTIVE_STATE="${ACTIVE_STATE}"
  SUB_STATE="$(echo "${json}" | yq -e '.payload.data[1].SubState.data // ""' 2>/dev/null)"
  [[ -n "${SUB_STATE}" && "${LAST_SUB_STATE}" != "${SUB_STATE}" ]] && LAST_SUB_STATE="${SUB_STATE}"
 elif [[ "${json}" == *SubState* ]]; then
  SUB_STATE="$(echo "${json}" | yq -e '.payload.data[1].SubState.data // ""' 2>/dev/null)" || continue
  [[ -z "${SUB_STATE}" ]] && continue
  [[ "${LAST_SUB_STATE}" == "${SUB_STATE}" ]] && continue
  LAST_SUB_STATE="${SUB_STATE}"
  ACTIVE_STATE="$(echo "${json}" | yq -e '.payload.data[1].ActiveState.data // ""' 2>/dev/null)"
  [[ -n "${ACTIVE_STATE}" && "${LAST_ACTIVE_STATE}" != "${ACTIVE_STATE}" ]] && LAST_ACTIVE_STATE="${ACTIVE_STATE}"
 else continue; fi
 MESSAGE="
UTC: \`${DATE_TIME}\`
IP: \`${IP_ADDRESS}\`
Service: \`${SERVICE_NAME}\`
ActiveState: \`${LAST_ACTIVE_STATE}\`
SubState: \`${LAST_SUB_STATE}\`"
 /usr/local/bin/tgbots/send_message.sh "${MESSAGE}" "${TG_CHAT_ID}" &
done < <(stdbuf -oL busctl monitor "${SENDER_NAME}" --match="${SENDER_MATCHER}" --json=short)
