#!/bin/bash

cd "$(dirname "${BASH_SOURCE}")"

# settings must contain (as shell variables):
# TWILIO_ACCSID, TWILIO_TOKEN, FROM, TO, USER, PW, USERAGENT
source settings
mkdir -p messages
mkdir -p notifications

blob="$(curl -s -X POST -A "${USERAGENT}" https://www.oresundsbron.com/api/selfservice/login -H 'Content-Type: application/json' --data "{\"login\": \"${USER}\", \"password\": \"${PW}\", \"bypassPwd\": true, \"type\": \"login\"}")"

usages="$(echo "${blob}" | jq -r '.data.latestUsage')"
usages_length="$(echo "${usages}" | jq -r 'length')"

highest_idx="0"
highest_id="0"
for i in $(seq 0 $(expr ${usages_length} - 1))
do
	usage_id="$(echo "${usages}" | jq -r ".[${i}].id")"
	echo "$(echo "${usages}" | jq -r ".[${i}]")" > "messages/${usage_id}"

	if [ "${usage_id}" -gt "${highest_id}" ]
	then
		highest_id="${usage_id}"
		highest_idx="${i}"
	fi
done

if [ -f "notifications/${highest_id}" ]
then
	exit
fi

msg="$(echo "${usages}" | jq -r ".[${highest_idx}]")"

direction="$(echo "${msg}" | jq -r '.direction')"
lane="$(echo "${msg}" | jq -r '.lane')"
vehicle="$(echo "${msg}" | jq -r '.reference')"
timestamp="$(echo "${msg}" | jq -r '.usageExitTime')"
price="$(echo "${msg}" | jq -r '.priceInclVAT')"
currency="$(echo "${msg}" | jq -r '.currencyCode')"


if [[ "${direction}" == "2" ]]
then
	direction="Sweden"
else
	direction="Denmark"
fi

body="Bridge passed by ${vehicle} heading towards ${direction}. Time: ${timestamp}, lane: ${lane}, price: ${price} ${currency}"
curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json" \
	--data-urlencode "From=${FROM}" \
	--data-urlencode "To=${TO}" \
	--data-urlencode "Body=${body}" \
	-u "${TWILIO_SID}:${TWILIO_TOKEN}"
echo
echo "${body}" > "notifications/${highest_id}"
echo "Notification sent to ${TO}"
