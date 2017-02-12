# oresundsmonitor

Öresundsbron travel and weather SMS notification services. The services are configured through a shell script file called "settings". The expected variables are written at the top of the scripts.

## travelmonitor

Monitors bridge passes, and sends an SMS through Twilio when a pass is detected. User credentials for the monitored subscription is required.

## bridgemonitor

Monitors bridge status, and sends an SMS through Twilio when the status changes.
