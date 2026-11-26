FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.50.1
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY lib ./lib
COPY assets ./assets
COPY web ./web
RUN flutter build web --release --no-pub --no-web-resources-cdn

FROM caddy:2-alpine
ENV APP_ADDRESS=:8080 APP_ROOT=/srv
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
