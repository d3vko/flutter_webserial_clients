# syntax=docker/dockerfile:1

# Cirrus Labs images often lag behind Flutter/Dart releases (stable ≈ Dart 3.12.0).
# Install Flutter from git so Docker matches local dev (Flutter 3.44.4 / Dart 3.12.2).
FROM docker.io/library/debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.44.4

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
ENV TAR_OPTIONS="--no-same-owner"

RUN git clone https://github.com/flutter/flutter.git \
        --branch "${FLUTTER_VERSION}" \
        --depth 1 \
        "${FLUTTER_HOME}" \
    && flutter config --no-analytics

WORKDIR /app

ARG WARDRIVE_LOGIN_URL=""
ARG WARDRIVE_REGISTER_URL=""
ARG WARDRIVE_RESET_URL=""
ARG WARDRIVE_UPLOAD_URL=""
ARG WARDRIVE_TOKEN_REFRESH_URL=""

ENV CI=true \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    WARDRIVE_LOGIN_URL=$WARDRIVE_LOGIN_URL \
    WARDRIVE_REGISTER_URL=$WARDRIVE_REGISTER_URL \
    WARDRIVE_RESET_URL=$WARDRIVE_RESET_URL \
    WARDRIVE_UPLOAD_URL=$WARDRIVE_UPLOAD_URL \
    WARDRIVE_TOKEN_REFRESH_URL=$WARDRIVE_TOKEN_REFRESH_URL

COPY pubspec.yaml pubspec.lock analysis_options.yaml ./
COPY lib/ lib/
COPY web/ web/
COPY assets/ assets/

RUN flutter pub get \
    && flutter build web --release \
    --no-wasm-dry-run \
    --pwa-strategy=none \
    --dart-define=WARDRIVE_LOGIN_URL=${WARDRIVE_LOGIN_URL} \
    --dart-define=WARDRIVE_REGISTER_URL=${WARDRIVE_REGISTER_URL} \
    --dart-define=WARDRIVE_RESET_URL=${WARDRIVE_RESET_URL} \
    --dart-define=WARDRIVE_UPLOAD_URL=${WARDRIVE_UPLOAD_URL} \
    --dart-define=WARDRIVE_TOKEN_REFRESH_URL=${WARDRIVE_TOKEN_REFRESH_URL}

FROM docker.io/library/nginx:alpine AS runtime

RUN rm -f /etc/nginx/conf.d/default.conf

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8090

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8090/ > /dev/null || exit 1
