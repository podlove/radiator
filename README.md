# Radiator Spark 🔥

Radiator is the 100% open source podcast hosting project for the next century of the internet.

[![Build Status](https://travis-ci.org/podlove/radiator-spark.svg?branch=master)](https://travis-ci.org/podlove/radiator-spark)

## Status

We are still in an exploration phase. Technically the foundation for hosting a podcast with a valid RSS feed is there but it's very simplistic and missing features left and right. Using this in production is not recommended yet as breaking changes will occur without prior notice.

## Built With

- [Phoenix Framework][phoenix] &mdash; the backend API (currently both GraphQL and REST endpoints) and (currently) admin interface
- [PostgreSQL][pgsql] &mdash; main data store
- [Minio][minio] &mdash; private cloud storage for audio and image files
- [Vue.js][vuejs] &mdash; JavaScript framework

## Development

```shell
git clone https://github.com/podlove/radiator-spark.git
cd radiator-spark

# start postgres
# start minio
# set minio access and secret in config/config.exs `config :ex_aws` 
#  (you see them at minio startup in the console)

mix deps.get
mix ecto.create
mix ecto.migrate
cd assets && npm install
cd ..
mix phx.server
```

## API

At the moment both GraphQL and REST endpoints are available. The aim is to provide a full GraphQL api as primary target and some basic REST endpoints for quick usecases.

### GraphQL

Entrypoint: `/api/graphql`

Open http://localhost:4000/api/graphiql for schema and documentation exploration.

### REST

Follows [HAL][hal]+json specification.

Entrypoint: `/api/rest/v1`

Some endpoints:

- `/api/rest/v1/podcasts`
- `/api/rest/v1/podcasts/:podcast_id`
- `/api/rest/v1/podcasts/:podcast_id/episodes`
- `/api/rest/v1/podcasts/:podcast_id/episodes/:episode_id`
- `/api/rest/v1/files`

## Admin Interface

At `http://localhost:4000/admin/podcasts` you will find a simple admin interface to manage podcasts and episodes. There is no concept of users yet, so there is no registration, login or any kind of authentication.

<img alt="Network" src="https://user-images.githubusercontent.com/235918/54268328-40162d80-457b-11e9-9d95-5a085f34c5d7.png" width="720px">

<img alt="Edit Podcast" src="https://user-images.githubusercontent.com/235918/54268396-60de8300-457b-11e9-9b1d-605d37fd4dce.png" width="720px">

## License

Radiator is [MIT Licensed][license].

[phoenix]: https://phoenixframework.org/
[minio]: https://minio.io/
[pgsql]: https://www.postgresql.org/
[hal]: http://stateless.co/hal_specification.html
[license]: https://github.com/podlove/radiator-spark/blob/master/LICENSE
[vuejs]: https://vuejs.org/
