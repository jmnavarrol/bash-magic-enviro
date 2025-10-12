# Creates a docker container to exhibit BME features
# See https://github.com/jmnavarrol/bash-magic-enviro/blob/main/docker-container/README.md
FROM debian:trixie-slim

# Standard container labels (See http://label-schema.org/rc1/)
LABEL org.label-schema.name="BME"
LABEL org.label-schema.description="Bash Magic Enviro container"
LABEL org.label-schema.url="https://github.com/jmnavarrol/bash-magic-enviro"

# Define variables
ARG BME_REPO='https://github.com/jmnavarrol/bash-magic-enviro.git'
ARG BME_VERSION='v1.10.1'

# Copy data from local repository
COPY --chown=root:root etc /etc
COPY --chown=root:root --chmod=0755 entrypoint.sh /entrypoint.sh

# Install packaged utilities
RUN echo "Installing utilities..." \
	&& apt-get update \
	&& apt-get install -y \
	# local user management
		sudo \
	# development utilities
		git make jq python3.13-venv virtualenvwrapper \
	# other utilities
		curl nano tree \
# 		curl nano tree libffi-dev \
	# final clean
	&& apt-get clean

# Install BME under /opt/bme
RUN cd /usr/local/src/ \
	&& git clone --depth 1 --branch ${BME_VERSION} ${BME_REPO} \
	&& cd bash-magic-enviro \
	&& export PATH=/opt/bme:$PATH && make DESTDIR=/opt/bme install

# Final drop to entrypoint
CMD ["bash"]
ENTRYPOINT ["/entrypoint.sh"]
