# Use a lightweight Alpine Linux version 3.18.2 as the base image
FROM alpine:3.18.2

# Set environment variables for PKI and Radsecproxy directories
ENV PKI_DIR=/etc/pki
ENV RADSECPROXY_DIR=/etc/radsecproxy

# Update package index and install necessary packages:
# - radsecproxy: RADIUS to RADSEC proxy
# - envsubst: utility for substituting environment variables
# - bind-tools: utilities for querying DNS servers
# - bash: shell for running scripts
RUN apk update && \
    apk add --no-cache \
        radsecproxy \
        gettext \
        bind-tools \
        bash && \
    # Create directories for Radsecproxy configuration and PKI
    mkdir -p $RADSECPROXY_DIR && \
    mkdir -p $PKI_DIR

# Copy CA certificate and Radsecproxy configuration into the container
COPY pki/ $PKI_DIR/
COPY config/ $RADSECPROXY_DIR/

# Copy the entrypoint script into the container
COPY entrypoint.sh /

# Set the default command to execute when the container starts
CMD ["sh", "/entrypoint.sh"]

# Expose ports used by radsecproxy for RADIUS communication
EXPOSE 1812/udp
EXPOSE 1813/udp
