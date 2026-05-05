FROM ruby:3.4-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NOWARNINGS="yes" \
    LANG=en_US.UTF-8 \
    BUNDLE_PATH=/bundle_cache \
    GEM_HOME=/bundle_cache \
    GEM_PATH=/bundle_cache
ARG INSTALL_DEVELOPMENT_DEPENDENCIES=false
ARG TARGETARCH
ARG NODE_24_VERSION=24.14.1

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends ca-certificates curl gnupg2 && \
    mkdir -p /usr/share/keyrings && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -qq -y --no-install-recommends \
      build-essential git-core imagemagick \
      default-libmysqlclient-dev default-mysql-client netcat-openbsd shared-mime-info \
      xvfb \
      libvips42 \
      cmake pkg-config file \
      postgresql-client-15 libpq-dev && \
    case "${TARGETARCH}" in \
      amd64) NODE_TARBALL="node-v${NODE_24_VERSION}-linux-x64.tar.gz" ;; \
      arm64) NODE_TARBALL="node-v${NODE_24_VERSION}-linux-arm64.tar.gz" ;; \
      *) echo "Unsupported Docker target platform for Node.js: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    NODE_BASE_URL="https://nodejs.org/download/release/v${NODE_24_VERSION}" && \
    curl -fsSL "${NODE_BASE_URL}/SHASUMS256.txt" -o SHASUMS256.txt && \
    grep " ${NODE_TARBALL}$" SHASUMS256.txt >/dev/null && \
    curl -fsSLO "${NODE_BASE_URL}/${NODE_TARBALL}" && \
    grep " ${NODE_TARBALL}$" SHASUMS256.txt | sha256sum -c - && \
    tar -xzf "${NODE_TARBALL}" -C /usr/local --strip-components=1 --no-same-owner && \
    rm -f SHASUMS256.txt "${NODE_TARBALL}" && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/man/* /usr/share/doc/*

RUN corepack enable && \
    corepack prepare yarn@stable --activate && \
    gem update --system > /dev/null && \
    gem install bundler --silent && \
    echo "alias m='make'\nalias ms='make start'\nalias mss='make start_no_async'\nalias mc='make console'\nalias mcs='make console_no_async'\nalias r='bundle exec rspec'\nalias ra='bundle exec rubocop -a'\nalias raa='bundle exec rubocop -A'\nalias cred='bin/rails credentials:edit --environment development'\nalias crsd='bin/rails credentials:show --environment development'\nalias cres='bin/rails credentials:edit --environment staging'\nalias crss='bin/rails credentials:show --environment staging'\nalias crep='bin/rails credentials:edit --environment production'\nalias crsp='bin/rails credentials:show --environment production'\nalias cret='bin/rails credentials:edit --environment test'\nalias crst='bin/rails credentials:show --environment test'\nalias sw='bundle exec rake rswag:specs:swaggerize'\nexport EDITOR=vi\nexport PATH=\"/app/bin:/bundle_cache/bin:\$PATH\"" >> ~/.bashrc
