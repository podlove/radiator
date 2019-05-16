FROM elixir:1.8.1

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force && mix local.rebar --force

# Install:
# npm for the assets folder
# inotify-tools for phoenix
# postgresql-client to connect with the remote db
RUN apt-get update -yq \
    && apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install nodejs inotify-tools postgresql-client -yq

# Create the app directory
RUN mkdir /app /app/assets
WORKDIR /app

# Install the mimio client
RUN wget --quiet https://dl.minio.io/client/mc/release/linux-amd64/mc
RUN chmod +x mc
RUN echo $PWD

# Get the Dependencies
## Elixir
COPY mix.* /app/
RUN mix deps.get
## npm
COPY assets/package*.json /app/assets/
WORKDIR /app/assets
RUN npm install
WORKDIR /app

# copy the Elixir projects into it and compile what's there
COPY . /app
RUN mix compile

ENTRYPOINT [ "/bin/bash", "entrypoint.sh" ]