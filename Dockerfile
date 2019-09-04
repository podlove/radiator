FROM elixir:1.9-slim AS elixir_prep

# git: git dependency in mix.exs
# make gcc libc-dev: argon2_elixir
RUN apt-get update && apt-get install -y git make gcc libc-dev

# Set environment variables for building the application
ENV MIX_ENV=prod \
  LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy and build deps first
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get
RUN mix deps.compile

# Copy over all other necessary application files and directories
COPY config ./config
COPY lib ./lib

# only copy selected directories in priv
# - exclude "static" because it will be generated fresh
# - exclude "gettext" because it's unused
# - exclude "user-agent-db" because it will be fetched fresh
RUN mkdir /app/priv
# COPY priv/cert ./priv/cert
COPY priv/repo ./priv/repo

# this starts the application which sucks because there is no db when building?
# RUN mix ua_inspector.download --force
RUN mix run --no-start -e "UAInspector.Downloader.download()"

# ---- Node/Asset Stage ----
FROM node:10.16-stretch AS node_builder

RUN npm install -g webpack webpack-cli

RUN mkdir /app
RUN mkdir /app/deps

COPY assets /app/assets

COPY --from=elixir_prep /app/deps/phoenix /app/deps/phoenix
COPY --from=elixir_prep /app/deps/phoenix_html /app/deps/phoenix_html

# for purgecss
COPY --from=elixir_prep /app/lib/radiator_web/templates /app/lib/radiator_web/templates
COPY --from=elixir_prep /app/lib/radiator_web/views /app/lib/radiator_web/views

WORKDIR /app/assets

RUN npm install
RUN npm audit fix
RUN webpack --mode production

# --- Elixir Builder Stage ---
#  Continues elixir_builder, generating the final release.

FROM elixir_prep AS elixir_builder

COPY --from=node_builder /app/priv/static /app/priv/static

WORKDIR /app

RUN mix phx.digest

# build the application
RUN mix release

# ---- Application Stage ----
FROM debian:stretch AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apt-get update && apt-get install -y openssl wget imagemagick ffmpeg

# Copy over the build artifact from the previous step and create a non root user
RUN useradd --create-home app
WORKDIR /home/app

# Install minio client
RUN wget --quiet https://dl.minio.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc

COPY --from=elixir_builder /app/_build .
COPY --from=elixir_builder /app/priv ./priv
RUN chown -R app: ./prod
RUN chown -R app: ./priv
USER app

COPY entrypoint.sh .

ENTRYPOINT [ "/bin/bash", "entrypoint.sh" ]
