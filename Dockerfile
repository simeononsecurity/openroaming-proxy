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
        openssl \
        ca-certificates \
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

# Fetch certificates and split each into its own file
RUN  mkdir -p /etc/pki/cacerts_temp && \
    openssl s_client -connect 216.239.34.91:2083 -showcerts </dev/null | awk '/BEGIN CERTIFICATE/{flag=1;c++} flag {print > "/etc/pki/cacerts_temp/orion1_" c ".pem"} /END CERTIFICATE/{flag=0}' && \
    openssl s_client -connect 216.239.32.91:2083 -showcerts </dev/null | awk '/BEGIN CERTIFICATE/{flag=1;c++} flag {print > "/etc/pki/cacerts_temp/orion2_" c ".pem"} /END CERTIFICATE/{flag=0}' && \
    openssl s_client -connect aaa.geo.t-mobile.com:2083 -showcerts </dev/null | awk '/BEGIN CERTIFICATE/{flag=1;c++} flag {print > "/etc/pki/cacerts_temp/tmobile_" c ".pem"} /END CERTIFICATE/{flag=0}'

# Move only valid certificate files to the actual cacerts directory, ignoring empty files
RUN find /etc/pki/cacerts_temp -type f -size +0 -exec mv {} /etc/pki/cacerts/ \; && \
    rm -rf /etc/pki/cacerts_temp

# Copy the CA certificates to the trusted root folder
COPY pki/ /usr/local/share/ca-certificates/
COPY pki/ /etc/ssl/certs/

# Update the trusted root certificates
RUN cp -r /etc/pki/ /usr/local/share/ca-certificates/ && \
    cp -r /etc/pki/ /etc/ssl/certs/ && \
    update-ca-certificates --fresh

# Copy the entrypoint script into the container
COPY entrypoint.sh /

# Set the default command to execute when the container starts
CMD ["sh", "/entrypoint.sh"]

# Expose ports used by radsecproxy for RADIUS communication
EXPOSE 1812/udp
EXPOSE 1813/udp
