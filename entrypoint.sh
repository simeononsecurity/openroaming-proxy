#!/bin/sh

# Function to check if key exists
checkForKey() {
    if [ ! "$2" ]; then
        echo "Error: Key \"$1\" is missing." >&2
        exit 1
    fi
}

# Check for user-provided env vars
checkForKey CLIENT_KEY "$CLIENT_KEY"
checkForKey CLIENT_CRT "$CLIENT_CRT"
checkForKey LOCAL_SHARED_SECRET "$LOCAL_SHARED_SECRET"

# Generate Radsecproxy config file from env vars
LOCAL_SHARED_SECRET="${LOCAL_SHARED_SECRET}" \
PKI_DIR="${PKI_DIR}" \
RADSECPROXY_DIR="${RADSECPROXY_DIR}" \
envsubst < "${RADSECPROXY_DIR}/radsecproxy.conf.template" \
> "${RADSECPROXY_DIR}/radsecproxy.conf"

# Write key and certs env vars to their locations
echo "$CLIENT_KEY" | base64 -d > "${PKI_DIR}/client.key"
echo "$CLIENT_CRT" | base64 -d > "${PKI_DIR}/client.chain.crt"

# Start Radsecproxy
/usr/sbin/radsecproxy -c "${RADSECPROXY_DIR}/radsecproxy.conf" -f
