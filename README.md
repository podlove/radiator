# Radiator 🔥

Radiator is the 100% open source podcast hosting project for the next century of the internet.

[![Build Status](https://cloud.drone.io/api/badges/podlove/radiator/status.svg)](https://cloud.drone.io/podlove/radiator)

## Status

We are still in an exploration phase. Technically the foundation for hosting a podcast with a valid RSS feed is there but it's very simplistic and missing features left and right. Using this in production is not recommended yet as breaking changes will occur without prior notice.

## Built With

- [Phoenix Framework][phoenix] &mdash; the backend API (currently both GraphQL and REST endpoints) and (currently) admin interface
- [PostgreSQL][pgsql] &mdash; main data store
- [Minio][minio] &mdash; private cloud storage for audio and image files
- [Vue.js][vuejs] &mdash; JavaScript framework

## Development

**Docker Deployment**

If you just want to take a look at the project, you can deploy a ready-to-run stack with [docker-compose](https://docs.docker.com/compose/):

```shell
git clone https://github.com/podlove/radiator
cd radiator
docker-compose up
```

Then access the following services:

| Service  | URL                                |
| -------- | ---------------------------------- |
| Radiator | http://localhost:4000              |
| Minio    | http://localhost:9000              |
| MailHog  | http://localhost:8025              |
| GraphiQL | http://localhost:4000/api/graphiql |

**Minio Setup**

- [Install minio][minio-setup]
- [Install minio client][minio-client-setup]
- start minio and take note of the AccessKey and SecretKey in the startup notice (for example manually `minio server ./data`)
- configure minio client:

```shell
mc config host add radiator http://127.0.0.1:9000 <AccessKey> <SecretKey>
```

- setup minio:

```shell
mc mb radiator/radiator
mc mb radiator/radiator-test
mc policy set public radiator/radiator
```

**Phoenix Setup**

```shell
git clone https://github.com/podlove/radiator.git
cd radiator

# start postgres

# set minio access keys in config/config.exs
#   config :ex_aws,
#     access_key_id: "<AccessKey>",
#     secret_access_key: "<SecretKey>",
#     json_codec: Jason

mix deps.get
mix ecto.create
mix ecto.migrate
cd assets && npm install
cd ..
mix phx.server
```

Seed database with data for development (unless you did `mix ecto.reset`, it runs seeds automatically):

```shell
mix run priv/repo/seeds.exs
```

Creates:

- "ACME" network
- user "admin" with password "password"

Download UserAgent database for tracking:

```shell
mix ua_inspector.download --force
```

## ⚠️ Migrations during development ⚠️

During the early stages of development we _edit_ existing migrations to keep them readable instead of adding new ones as you would expect in a live system.

So whenever you pull an update that changed a migration, you need to:

```shell
mix ecto.reset
env MIX_ENV=test mix ecto.reset
```

## API

At the moment both GraphQL and REST endpoints are available. The aim is to provide a full GraphQL api as primary target and some basic REST endpoints for quick usecases.

### GraphQL

Entrypoint: `/api/graphql`

Open http://localhost:4000/api/graphiql for schema and documentation exploration.

For calls that need authentication, make sure to put the token gotten from a

```GraphQL
mutation {
	authenticatedSession(
		username_or_email: "admin",
		         password: "password" ) {
		token
	}
}
```

request into the `Authorization: Bearer <token>` header.

### REST

⚠️ The REST API has not been updated in a long time and is probably out of order. For now, use GraphQL if you can.

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
[minio-setup]: https://docs.minio.io/docs/minio-quickstart-guide.html
[minio-client-setup]: https://docs.minio.io/docs/minio-client-quickstart-guide.html
[pgsql]: https://www.postgresql.org/
[hal]: http://stateless.co/hal_specification.html
[license]: https://github.com/podlove/radiator/blob/master/LICENSE
[vuejs]: https://vuejs.org/
