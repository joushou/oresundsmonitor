#!/bin/bash -e

cd "$(dirname "${BASH_SOURCE}")"

# settings must contain (as shell variables):
# TWILIO_ACCSID, TWILIO_TOKEN, FROM, TO, USERAGENT
source settings
mkdir -p status
mkdir -p messages
mkdir -p notifications

fixtime() {
	i="${1}"
	if [[ "${i}" == "" ]] || [[ "${i}" == "null" ]]
	then
		return
	fi

	t="$(echo "${i}" | cut -d'T' -f2 | cut -d'.' -f1)"
	hour="$(echo "${t}" | cut -d':' -f1)"
	minute="$(echo "${t}" | cut -d':' -f2)"
	hour="$(( hour + 1 ))"
	echo "${hour}:${minute}"
}

notify() {
	idx="${1}"
	status="${2}"

	location="$(jq -r '.location' "messages/${idx}")"
	direction="$(jq -r '.direction' "messages/${idx}")"
	restriction="$(jq -r '.restriction' "messages/${idx}")"
	eventtxt="$(jq -r '.event' "messages/${idx}")"
	comment="$(jq -r '.comment' "messages/${idx}")"
	start="$(fixtime "$(jq -r '.time' "messages/${idx}")")"
	end="$(fixtime "$(jq -r '.endtime' "messages/${idx}")")"

	msg=""
	case "${status}" in
		1)
			msg="Bridge: Open"
			;;
		2)
			msg="Bridge: Warning"
			;;
		3)
			msg="Bridge: Closed"
			;;
		*)
			msg="Bridge: UNKNOWN"
	esac

	[[ "${eventtxt}" != "" ]] && msg="${msg}, ${eventtxt}"
	# [[ "${location}" != "" ]] && [[ "${location}" != "The Øresund Bridge" ]] && msg="${msg}, at ${location}"
	[[ "${direction}" != "" ]] && msg="${msg}, ${direction}"
	[[ "${restriction}" != "" ]] && msg="${msg}, restriction: ${restriction}"
	# [[ "${comment}" != "" ]] && msg="${msg}, comment: ${comment}"
	[[ "${start}" != "" ]] && msg="${msg}, time: ${start}"
	[[ "${end}" != "" ]] && msg="${msg}, end: ${end}"

	curl -s -X POST \
		-H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
		--data-urlencode "From=${FROM}" \
		--data-urlencode "To=${TO}" \
		--data-urlencode "Body=${msg}" \
		-u "${TWILIO_ACCSID}:${TWILIO_TOKEN}" \
		"https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCSID}/Messages.json"
	echo
	echo "${msg}" > "notifications/${idx}"
	echo "Notification sent to ${TO}"
}

blob="$(curl -s -A "${USERAGENT}" https://www.oresundsbron.com/api/modules/bromeld/messages)"

eventid="$(echo "${blob}" | jq -r '.data.status.event_id')"
status="$(echo "${blob}" | jq -r '.data.status.status')"
echo "${status}" > "status/${eventid}"

messages="$(echo "${blob}" | jq -r '.data.messages | to_entries')"
messages_length="$(echo "${messages}" | jq -r 'length')"

for i in $(seq 0 $(expr ${messages_length} - 1))
do
	key="$(echo "${messages}" | jq -r ".[${i}].key")"
	value="$(echo "${messages}" | jq -r ".[${i}].value")"
	UPDATE="1"

	if [ -f "messages/${key}" ]
	then
		old_value="$(cat "messages/${key}")"
		if [[ "${old_value}" == "${value}" ]]
		then
			UPDATE="0"
		fi
	fi

	if [[ "${UPDATE}" == "1" ]]
	then
		echo "${value}" > "messages/${key}"
		notify "${key}" "${status}"
	fi
done
