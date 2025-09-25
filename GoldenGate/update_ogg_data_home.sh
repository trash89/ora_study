#!/bin/bash

# Prompt for protocol with validation
while true; do
  read -p "Enter protocol (http or https): " PROTOCOL
  if [[ "$PROTOCOL" == "http" || "$PROTOCOL" == "https" ]]; then
  break
  else
  echo "Invalid input. Please enter 'http' or 'https'."
  fi
done

# Prompt for input
read -p "Enter OGG MA Service Manager Hostname: " HOSTNAME
read -p "Enter OGG MA Service Manager Port: " PORT
read -p "Enter OGG MA Service Manager Username: " USERNAME
read -s -p "Enter OGG MA Service Manager Password: " PASSWORD
echo
read -p "Enter Deployment Name: " DEPLOYMENT
read -p "Enter New oggDataHome Path: " NEW_OGGDATAHOME

# Encode credentials to Base64
CREDENTIALS=$(echo -n "$USERNAME:$PASSWORD" | base64)

# Create a timestamp for the log file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="ogg_update_data_home_log_$TIMESTAMP.log"

# Display action and log file location
echo "Sending PATCH request to update oggDataHome..."
echo "Logging output to $LOGFILE"

# Perform the curl request and log the output
curl -X PATCH "$PROTOCOL://$HOSTNAME:$PORT/services/v2/deployments/$DEPLOYMENT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $CREDENTIALS" \
  -d "{
  \"oggDataHome\": \"$NEW_OGGDATAHOME\",
  \"status\": \"restart\"
  }" --insecure | tee "$LOGFILE"
