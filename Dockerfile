FROM beardedeagle/alpine-elixir-builder:1.9.1 AS elixir_prep

# git: git dependency in mix.exs
# make gcc libc-dev: argon2_elixir
RUN apk update && apk add git make gcc libc-dev

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

# compile and fail if there are any warnings
RUN mix compile --warnings-as-errors

# this starts the application which sucks because there is no db when building?
# RUN mix ua_inspector.download --force
RUN mix run --no-start -e "UAInspector.Downloader.download()"

# ---- Node/Asset Stage ----
FROM node:10.16-alpine AS node_builder

# fix for Error: could not get uid/gid
# https://stackoverflow.com/questions/52196518/could-not-get-uid-gid-when-building-node-docker

# Add the patch fix
COPY docker-fixes/stack-fix.c /lib/

# Prepare the libraries packages
RUN set -ex \
  && apk add --no-cache  --virtual .build-deps build-base \
  && gcc  -shared -fPIC /lib/stack-fix.c -o /lib/stack-fix.so \
  && apk del .build-deps

# export the environment variable of LD_PRELOAD
ENV LD_PRELOAD /lib/stack-fix.so

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
FROM alpine:3.9 as app

ENV LANG=C.UTF-8

# Install openssl
RUN apk update && apk add openssl wget imagemagick ffmpeg

# Create non root user in a canonical cross linux way (was for debian: RUN useradd --create-home app)
# https://stackoverflow.com/questions/49955097/how-do-i-add-a-user-when-im-using-alpine-as-a-base-image
ENV USER=app
ENV UID=12345
ENV GID=23456
ENV USER_HOME=/home/app

RUN addgroup --gid "$GID" "$USER" \
  && adduser \
  --disabled-password \
  --gecos "" \
  --home "$USER_HOME" \
  --ingroup "$USER" \
  --uid "$UID" \
  "$USER"


# Copy over the build artifact from the previous step and create a non root user
WORKDIR $USER_HOME

# Install minio client
RUN wget --quiet https://dl.minio.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc
# Make sure we are allowed to write in our own home
RUN chown $USER $USER_HOME

COPY --from=elixir_builder /app/_build .
COPY --from=elixir_builder /app/priv ./priv
RUN chown -R app: ./prod
RUN chown -R app: ./priv
USER app

COPY entrypoint.sh .
ENTRYPOINT [ "./entrypoint.sh" ]

# expose our default port
EXPOSE 4000
