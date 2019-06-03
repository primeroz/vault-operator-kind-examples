FROM mysql:5

RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends netbase ca-certificates wget && rm -rf /var/lib/apt/lists/* \
  && TEMP_DEB="$(mktemp)" \
  && wget -O "$TEMP_DEB" 'https://github.com/channable/vaultenv/releases/download/v0.9.0/vaultenv-0-9-0.deb' \
  && dpkg -i "$TEMP_DEB" \
  && rm -f "$TEMP_DEB" \
  && apt-get purge -y --auto-remove ca-certificates wget
