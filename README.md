# Radiator 🔥

Radiator is the 100% open source podcast hosting project for the next century of the internet.

[![Test](https://github.com/podlove/radiator/actions/workflows/cd.yml/badge.svg)](https://github.com/podlove/radiator/actions/workflows/cd.yml) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

## Contributing

The Radiator team welcomes contributions from anyone who wishes to advance the development of the Radiator!

If you'd like to contribute, please note we have [contribution docs](CONTRIBUTING.md) and a [code of conduct](CODE_OF_CONDUCT.md). Please follow it in all your interactions with the people and the project.

## Setup

### Using Homebrew

Open a Terminal and run the following commands

#### Install Homebrew

- `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

#### Install & Start Postgres

- `brew install postgresql`
- `brew services start postgresql`
- `createuser -d postgres`

#### Install Elixir

- `brew install elixir`

#### Setup and Start Radiator

- Run `mix setup` to install and setup dependencies
- Start Radiator with `iex -S mix phx.server`
- Visit [`localhost:4000`](http://localhost:4000) from your browser
- Use LiveDebugger on [`localhost:4007`](http://localhost:4007) if needed
