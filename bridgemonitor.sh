#!/bin/bash -e

cd "$(dirname "${BASH_SOURCE}")"

# settings must contain (as shell variables):
# TWILIO_ACCSID, TWILIO_TOKEN, FROM, TO, USERAGENT
source settings
mkdir -p status
mkdir -p messages
mkdir -p blobs
mkdir -p notifications

blob="$(curl -s -A "${USERAGENT}" https://www.oresundsbron.com/api/modules/bromeld/messages)"

eventid="$(echo "${blob}" | jq -r '.data.status.event_id')"
status="$(echo "${blob}" | jq -r '.data.status.status')"
echo "${status}" > "status/${eventid}"

messages="$(echo "${blob}" | jq -r '.data.messages | to_entries')"
messages_length="$(echo "${messages}" | jq -r 'length')"

highest_key="0"
for i in $(seq 0 $(expr ${messages_length} - 1))
do
	key="$(echo "${messages}" | jq -r ".[${i}].key")"
	value="$(echo "${messages}" | jq -r ".[${i}].value")"
	echo "${value}" > "messages/${key}"
	if [ "${key}" -gt "${highest_key}" ]
	then
		highest_key="${key}"
	fi
done

if [ -f "notifications/${highest_key}" ]
then
	exit
fi
echo "${blob}" > "blobs/${highest_key}"

restriction="$(jq -r '.restriction' "messages/${highest_key}")"
eventtxt="$(jq -r '.event' "messages/${highest_key}")"
comment="$(jq -r '.comment' "messages/${highest_key}")"
time="$(jq -r '.time' "messages/${highest_key}" | cut -d'T' -f2 | cut -d'.' -f1)"
date="$(jq -r '.time' "messages/${highest_key}" | cut -d'T' -f1)"

msg=""
if [[ "${restriction}" != "" ]] && [[ "${comment}" != "" ]]
then
	msg="Bridge status: ${eventtxt}, restriction: ${restriction}, comment: ${comment}, time: ${time} ${date}"
elif [[ "${restriction}" != "" ]]
then
	msg="Bridge status: ${eventtxt}, restriction: ${restriction}, time: ${time} ${date}"
elif [[ "${comment}" != "" ]]
then
	msg="Bridge status: ${eventtxt}, comment: ${comment}, time: ${time} ${date}"
else
	msg="Bridge status: ${eventtxt}, time: ${time} ${date}"
fi

curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCSID}/Messages.json" \
	--data-urlencode "From=${FROM}" \
	--data-urlencode "To=${TO}" \
	--data-urlencode "Body=${msg}" \
	-u "${TWILIO_ACCSID}:${TWILIO_TOKEN}"
echo
echo "${msg}" > "notifications/${highest_key}"
echo "Notification sent to ${TO}"
