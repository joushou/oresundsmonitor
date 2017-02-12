# oresundsmonitor

Öresundsbron travel and weather SMS notification services. The services are configured through a shell script file called "settings" stored beside the script. The expected variables are written at the top of the individual scripts.

To use, fill out a "settings" file beside the script you want to use, and set up a cronjob or similar to call the script at a fitting interval (5-10 minutes?).

## travelmonitor

Monitors bridge passes, and sends an SMS through Twilio when a pass is detected. User credentials for the monitored subscription is required in plaintext, so make sure you're using a random password.

## bridgemonitor

Monitors bridge status, and sends an SMS through Twilio when the status changes.

## bugs

* bridgemonitor will only give you the last message if multiple are present.
