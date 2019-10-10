# REST API

- [API Usage](#api-usage)
- [Authentication](#authentication)
  - [Signup](#signup)
    - [Parameters](#parameters)
    - [Response](#response)
  - [Login](#login)
    - [Parameters](#parameters-1)
    - [Response](#response-1)
  - [Resend Verification Email](#resend-verification-email)
    - [Parameters](#parameters-2)
    - [Response](#response-2)
  - [Send Reset Password Email](#send-reset-password-email)
    - [Parameters](#parameters-3)
    - [Response](#response-3)
  - [Prolong Session](#prolong-session)
    - [Response](#response-4)
- [Networks](#networks)
  - [Parameters for Create & Update](#parameters-for-create--update)
  - [Create](#create)
  - [Read](#read)
  - [Update](#update)
  - [Delete](#delete)
- [Network Collaborators](#network-collaborators)
  - [Parameters for Create & Update](#parameters-for-create--update-1)
    - [Read](#read-1)
    - [Create](#create-1)
    - [Update](#update-1)
    - [Delete](#delete-1)
- [Podcasts](#podcasts)
  - [Parameters for Create & Update](#parameters-for-create--update-2)
  - [Create](#create-2)
  - [Read](#read-2)
  - [Update](#update-2)
  - [Delete](#delete-2)
- [Podcasts Collaborators](#podcasts-collaborators)
  - [Parameters for Create & Update](#parameters-for-create--update-3)
    - [Read](#read-3)
    - [Create](#create-3)
    - [Update](#update-3)
    - [Delete](#delete-3)
- [Episodes](#episodes)
  - [Parameters for Create & Update](#parameters-for-create--update-4)
  - [Create](#create-4)
  - [Read](#read-4)
  - [Update](#update-4)
  - [Delete](#delete-4)
- [AudioPublications](#audiopublications)
  - [Parameters for Create & Update](#parameters-for-create--update-5)
  - [Index](#index)
  - [Create](#create-5)
  - [Read](#read-5)
  - [Update](#update-5)
  - [Delete](#delete-5)
- [People](#people)
  - [Parameters for Create & Update](#parameters-for-create--update-6)
  - [Create](#create-6)
  - [Index](#index-1)
  - [Read](#read-6)
  - [Update](#update-6)
  - [Delete](#delete-6)
- [Contributions](#contributions)
  - [Parameters for Create & Update](#parameters-for-create--update-7)
  - [Create](#create-7)
  - [Index](#index-2)
  - [Read](#read-7)
  - [Update](#update-7)
  - [Delete](#delete-7)
- [Audio](#audio)
  - [Parameters for Create & Update](#parameters-for-create--update-8)
  - [Create (in network / audio publication)](#create-in-network--audio-publication)
  - [Create (in podcast / episode)](#create-in-podcast--episode)
  - [Read](#read-8)
  - [Update](#update-8)
  - [Delete](#delete-8)
- [Audio File](#audio-file)
  - [Parameters for Create](#parameters-for-create)
  - [Index](#index-3)
  - [Create](#create-8)
  - [Read](#read-9)
  - [Update](#update-9)
  - [Delete](#delete-9)
- [Audio Chapters](#audio-chapters)
  - [Parameters for Create & Update](#parameters-for-create--update-9)
  - [Index](#index-4)
  - [Create](#create-9)
  - [Read](#read-10)
  - [Update](#update-10)
  - [Delete](#delete-10)
- [Tasks](#tasks)
  - [Parameters for Create](#parameters-for-create-1)
    - [Import podcast feed](#import-podcast-feed)
  - [Create](#create-10)
  - [Read](#read-11)
  - [Delete](#delete-11)
- [Convert Chapters](#convert-chapters)

## API Usage

All requests need to be authenticated. See [Authentication](#authentication) below for details.

The documentation will often write parameters like this: `network[title]`. This indicates hierarchical parameter keys.

In JavaScript there are multiple ways to set them:

```js
// using FormData
var data = new FormData();
data.append("network[title]", "Example Network");

// using nested JSON
var data = JSON.stringify({
  network: {
    title: "Example Network"
  }
});
```

`DELETE` methods will always return a `204 No Content` when authenticated and the necessary params were in place.

## Authentication

To make full use of the API you need to authenticate as an existing user. A successful authentication returns a _token_ that you can use in subsequent requests to authenticate yourself as that user. You do this by setting the token as request header.

> curl -H "Authorization: Bearer AUTH-TOKEN" http://localhost:4000/api/rest/v1/

Obviously excempt from this are the `logn`, `signup`, `reset_password` and `resend_verification_email` endpoints.

### Signup

```
POST /api/rest/v1/auth/signup
```

#### Parameters

| Name           | Type     | Description                                                     |
| -------------- | -------- | --------------------------------------------------------------- |
| `name`         | `string` | **Required.** Username.                                         |
| `email`        | `string` | **Required.** Email.                                            |
| `password`     | `string` | **Required.** Password.                                         |
| `display_name` | `string` | display name, optional, defaults to nil and that means use name |
| `image`        | `file`   | avatar image, optional                                          |

#### Response

A user if successful. Error if username was already taken or arguments are missing.

```json
{…}
```

### Login

```
POST /api/rest/v1/auth
```

#### Parameters

| Name       | Type     | Description                      |
| ---------- | -------- | -------------------------------- |
| `name`     | `string` | **Required.** Username or email. |
| `password` | `string` | **Required.** Password.          |

#### Response

```json
{
  "expires_at": "2019-06-25T10:43:29Z",
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NjE0NTk0MDksImlzcyI6InJhZGlhdG9yIiwic3ViIjoiYWRtaW4iLCJ0eXAiOiJhcGlfc2Vzc2lvbiJ9.c1upk8TaENs-r5xZUXxUyZw4PEs5z7hpDusQtKDIwjJKZE1uKdbVs4mzcQdyJNHWHGdzSECwBtX1M4g_u-AhJg",
  "username": "admin"
}
```

### Resend Verification Email

```
POST /api/rest/v1/auth/resend_verification_email
```

#### Parameters

| Name            | Type     | Description                      |
| --------------- | -------- | -------------------------------- |
| `name_or_email` | `string` | **Required.** Username or email. |

#### Response

```json
{
  "name_or_email":  "whateveryousent",
  "verification": "sent"
}
```

### Send Reset Password Email

```
POST /api/rest/v1/auth/reset_password
```

#### Parameters

| Name            | Type     | Description                      |
| --------------- | -------- | -------------------------------- |
| `name_or_email` | `string` | **Required.** Username or email. |

#### Response

```json
{
  "name_or_email":  "whateveryousent",
  "reset": "sent"
}
```


### Prolong Session

Needs an authenticated session. Is a `POST` but doesn't need a payload.

```
POST /api/rest/v1/auth/prolong
```

#### Response

```json
{
  "expires_at": "2019-06-25T10:44:46Z",
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NjE0NTk0ODYsImlzcyI6InJhZGlhdG9yIiwic3ViIjoiYWRtaW4iLCJ0eXAiOiJhcGlfc2Vzc2lvbiJ9.4V6PniEaPlwhtcm8bQDGLapq_HTLL_0wnlYNMU2qpzofkmWGEfFP-sDnIOwzVfQ_JlUXfiXOiQ-hZYsVbHOwTg",
  "username": "admin"
}
```

## Networks

### Parameters for Create & Update

| Name             | Type     | Description                     |
| ---------------- | -------- | ------------------------------- |
| `network[title]` | `string` | **Required.** Network title.    |
| `network[image]` | `file`   | Image representing the Network. |
| `network[slug]`  | `string` | Slug for this network           |

### Create

```
POST /api/rest/v1/networks
```

### Read

```
GET /api/rest/v1/networks/:id
```

### Update

```
PATCH /api/rest/v1/networks/:id
```

### Delete

```
DELETE /api/rest/v1/networks/:id
```

## Network Collaborators

### Parameters for Create & Update

| Name         | Type     | Description                                                      |
| ------------ | -------- | ---------------------------------------------------------------- |
| `username`   | `string` | **Required.** Name of user to modify                             |
| `permission` | `string` | **Required.** one of `"own"`, `"manage"`, `"edit"`, `"readonly"` |

#### Read

use GraphQL API to list them

```
GET /api/rest/v1/networks/:id/collaborators/:username
```

#### Create

```
POST /api/rest/v1/networks/:id/collaborators
```

#### Update

```
PATCH /api/rest/v1/networks/:id/collaborators/:username
```

#### Delete

```
DELETE /api/rest/v1/networks/:id/collaborators/:username
```

## Podcasts

### Parameters for Create & Update

| Name                     | Type      | Description                                                                                       |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------------- |
| `podcast[title]`         | `string`  | **Required.**                                                                                     |
| `podcast[network_id]`    | `integer` | **Required.**                                                                                     |
| `podcast[short_id]`      | `string`  | Short ID for this podcast, also used as slug. Not unique. 2-5 characters usually, e.g. FS,FAN,ATP |
| `podcast[subtitle]`      | `string`  | Attention grabbing one liner appearing in lists/directories                                       |
| `podcast[summary]`       | `string`  | Short multiline description, appears in iTunes Preview                                            |
| `podcast[image]`         | `Image`   | Cover Image                                                                                       |
| `podcast[author]`        | `string`  | One line description of publisher                                                                 |
| `podcast[language]`      | `string`  | ISO 639-1                                                                                         |
| `podcast[owner_name]`    | `string`  |                                                                                                   |
| `podcast[owner_email]`   | `string`  |                                                                                                   |
| `podcast[slug]`          | `string`  |                                                                                                   |
| `podcast[publish_state]` | `string`  | Publication state. "drafted", "scheduled", "published" or "unpublished".                          |

### Create

```
POST /api/rest/v1/podcasts
```

### Read

```
GET /api/rest/v1/podcasts/:id
```

### Update

```
PATCH /api/rest/v1/podcasts/:id
```

### Delete

```
DELETE /api/rest/v1/podcasts/:id
```

## Podcasts Collaborators

### Parameters for Create & Update

| Name         | Type     | Description                                                      |
| ------------ | -------- | ---------------------------------------------------------------- |
| `username`   | `string` | **Required.** Name of user to modify                             |
| `permission` | `string` | **Required.** one of `"own"`, `"manage"`, `"edit"`, `"readonly"` |

#### Read

use GraphQL API to list them

```
GET /api/rest/v1/podcasts/:id/collaborators/:username
```

#### Create

```
POST /api/rest/v1/podcasts/:id/collaborators
```

#### Update

```
PATCH /api/rest/v1/podcasts/:id/collaborators/:username
```

#### Delete

```
DELETE /api/rest/v1/podcasts/:id/collaborators/:username
```

## Episodes

### Parameters for Create & Update

| Name                      | Type      | Description                                                              |
| ------------------------- | --------- | ------------------------------------------------------------------------ |
| `episode[title]`          | `string`  | **Required.**                                                            |
| `episode[podcast_id]`     | `integer` | **Required.**                                                            |
| `episode[short_id]`       | `string`  | Full combined short id, usually short_id + Number. Not unique.           |
| `episode[guid]`           | `string`  | guid, prefilled on publish if unspecified                                |
| `episode[subtitle]`       | `string`  | One line description of the episode                                      |
| `episode[summary]`        | `text`    | Multiline description, plain text only                                   |
| `episode[summary_html]`   | `text`    | Multiline description, html. Will be put in `content:encoded` in a feed  |
| `episode[summary_source]` | `text`    | Multiline description, arbitrary format chosen by frontends.             |
| `episode[number]`         | `integer` | Episode "Track" number, will be put in `itunes:episode` in the feed      |
| `episode[publish_state]`  | `string`  | Publication state. "drafted", "scheduled", "published" or "unpublished". |

### Create

```
POST /api/rest/v1/episodes
```

### Read

```
GET /api/rest/v1/episodes/:id
```

### Update

```
PATCH /api/rest/v1/episodes/:id
```

### Delete

```
DELETE /api/rest/v1/episodes/:id
```

## AudioPublications

Represents an Audio in a Network

### Parameters for Create & Update

| Name                               | Type       | Description                                                              |
| ---------------------------------- | ---------- | ------------------------------------------------------------------------ |
| `audio_publication[publish_state]` | `string`   | Publication state. "drafted", "scheduled", "published" or "unpublished". |
| `audio_publication[published_at]`  | `datetime` | publication date (readonly, is set automatically on first publication)   |
| `audio_publication[network_id]`    | `string`   | network id (readonly)                                                    |
| `audio_publication[audio_id]`      | `string`   | audio id (readonly)                                                      |

### Index

```
GET /api/rest/v1/audio_publications?network_id=:network_id
```

### Create

Use "Create Audio" instead with network parameter.

### Read

```
GET /api/rest/v1/audio_publications/:id
```

### Update

```
PATCH /api/rest/v1/audio_publications/:id
```

### Delete

```
DELETE /api/rest/v1/audio_publications/:id
```

## People

### Parameters for Create & Update

| Name                   | Type      | Description                                           |
| ---------------------- | --------- | ----------------------------------------------------- |
| `person[network_id]`   | `integer` | **Required.**                                         |
| `person[name]`         | `string`  | Full name of that person                              |
| `person[display_name]` | `string`  | Name to be used in all public pages, defaults to nick |
| `person[nick]`         | `string`  | Nick name of that person                              |
| `person[image]`        | `Image`   | Avatar Image                                          |

### Create

```
POST /api/rest/v1/people
```

### Index

Needs `person[network_id]` parameter.

```
GET /api/rest/v1/people
```

### Read

```
GET /api/rest/v1/people/:id
```

### Update

```
PATCH /api/rest/v1/people/:id
```

### Delete

```
DELETE /api/rest/v1/people/:id
```

## Contributions

### Parameters for Create & Update

| Name                                 | Type      | Description                                              |
| ------------------------------------ | --------- | -------------------------------------------------------- |
| `contribution[podcast_id]`           | `integer` | **Required.** Either podcast_id or audio_id can be given |
| `contribution[audio_id]`             | `integer` | **Required.**                                            |
| `contribution[contribution_role_id]` | `integer` | **Required.**                                            |
| `contribution[person_id]`            | `integer` | **Required.**                                            |
| `contribution[position]`             | `float`   | Sort order inside contributions                          |

Possible values for the `contribution_role_id` can be fetched with the GraphQL query `contributionRoles`

### Create

```
POST /api/rest/v1/contributions
```

### Index

Needs parameters, either `contribution[podcast_id]` or `contribution[audio_id]`

```
GET /api/rest/v1/contributions
```

### Read

```
GET /api/rest/v1/contributions/:id
```

### Update

```
PATCH /api/rest/v1/contributions/:id
```

### Delete

```
DELETE /api/rest/v1/contributions/:id
```

## Audio

### Parameters for Create & Update

| Name                | Type      | Description                                                  |
| ------------------- | --------- | ------------------------------------------------------------ |
| `audio[network_id]` | `integer` | Network ID. (readonly)                                       |
| `audio[episode_id]` | `integer` | Episode ID. (readonly)                                       |
| `audio[image]`      | `file`    | Audio image.                                                 |
| `audio[duration]`   | `integer` | Audio duration in milliseconds, will be set by an audio file |

When creating, you can send parameters for the audio publication or episode in the same request.

| Name                       | Type     | Description |
| -------------------------- | -------- | ----------- |
| `audio_publication[title]` | `string` | Title       |

| Name                                    | Type     | Description |
| --------------------------------------- | -------- | ----------- |
| `episode[title]`                        | `string` | Title       |
| `episode[subtitle]`                     | `string` | Subtitle    |
| see [Episodes](#episodes) for full list | ...      | ...         |

### Create (in network / audio publication)

```
POST /api/rest/v1/networks/:network_id/audios
```

### Create (in podcast / episode)

```
POST /api/rest/v1/episodes/:episode_id/audios
```

### Read

```
GET /api/rest/v1/audios/:id
```

### Update

```
PATCH /api/rest/v1/audios/:id
```

### Delete

```
DELETE /api/rest/v1/audios/:id
```

## Audio File

### Parameters for Create

| Name                | Type     | Description                                            |
| ------------------- | -------- | ------------------------------------------------------ |
| `audio_file[file]`  | `file`   | audio file to upload                                   |
| `audio_file[title]` | `string` | file title (deduced from upload filename if not given) |

### Index

```
GET /api/rest/v1/audios/:audio_id/audio_files
```

### Create

```
POST /api/rest/v1/audios/:audio_id/audio_files
```

### Read

```
GET /api/rest/v1/audio_files/:id
```

### Update

*Only title is supported for update!*

```
PATCH /api/rest/v1/audio_files/:id
```

### Delete

```
DELETE /api/rest/v1/audio_files/:id
```

## Audio Chapters

> ⚠️ A chapter is uniquely identified by its start time and the associated audio. There can only be exactly one chapter per audio with a given start time.

### Parameters for Create & Update

| Name                | Type      | Description                                                    |
| ------------------- | --------- | -------------------------------------------------------------- |
| `chapter[audio_id]` | `integer` | **Required.** Chapter is attached to Audio object of given ID. |
| `chapter[start]`    | `integer` | **Required.** chapter start time in milliseconds               |
| `chapter[title]`    | `string`  | chapter title                                                  |
| `chapter[link]`     | `string`  | chapter link                                                   |
| `chapter[image]`    | `file`    | chapter image                                                  |

### Index

```
GET /api/rest/v1/audios/:audio_id/chapters[?format=rest|json|psc|mp4chaps]
```

### Create

```
POST /api/rest/v1/audios/:audio_id/chapters
```

### Read

```
GET /api/rest/v1/audios/:audio_id/chapters/:start
```

### Update

```
PATCH /api/rest/v1/audios/:audio_id/chapters/:start
```

### Delete

```
DELETE /api/rest/v1/audios/:audio_id/chapters/:start
```

## Tasks

### Parameters for Create

#### Import podcast feed

| Name                                   | Type                | Description                                                                                                                                            |
| -------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `import_podcast_feed[network_id]`      | `integer`           | Network ID. (required).                                                                                                                                |
| `import_podcast_feed[feed_url]`        | `string`            | feed or show url (check availablity and extent with GraphQL query `feedInfo`                                                                           |
| `import_podcast_feed[enclosure_types]` | `array` of `string` | Optional. E.g. `["audio/mpeg","audio/mp4"]` or [] for none. Defaults to all available enclosures (not implemented yet, currently only mp3 is imported) |
| `import_podcast_feed[short_id]`        | `string`            | Short ID for the podcast. E.g. `"CRE"`, `"FAN"`, `"FG"`.                                                                                               |
| `import_podcast_feed[limit]`           | `integer`           | Limits the amount of episodes to import. Optional, Defaults to all found.                                                                              |

### Create

```
POST /api/rest/v1/tasks
```

### Read

```
GET /api/rest/v1/tasks/:id
```

Example:

```json
{
  "end_time": "2019-07-25T12:18:40.810667Z",
  "id": 543,
  "progress": 4,
  "start_time": "2019-07-25T10:55:38.521178Z",
  "state": "exited",
  "title": "Import 'freakshow.fm' into ACME",
  "total": 8,
  "_links": {
    "rad:subject": {
      "href": "/api/rest/v1/podcasts/14"
    },
    "self": {
      "href": "/api/rest/v1/tasks/543"
    }
  }
}
```

| Name         | Type                                         | Description                                      |
| ------------ | -------------------------------------------- | ------------------------------------------------ |
| `state`      | one of `setup`,`running`,`finished`,`exited` |
| `progress`   | `integer`                                    | amount of items finished                         |
| `total`      | `integer`                                    | total amount of items                            |
| `title`      | `string`                                     | Human readable english title describing the task |
| `start_time` | `timestamp`                                  |
| `end_time`   | `timestamp`                                  | can be nil. time the task `finished` or `exited` |

### Delete

You should delete a task after it is done. Eventually done tasks will clear out on their own too (not implemented yet)

```
DELETE /api/rest/v1/tasks/:id
```

## Convert Chapters

```
POST /api/rest/v1/convert/chapters
```

The chapters converter endpoint takes a string of one of the following formats:

- PSC (Podlove Simple Chapters)
- mp4chaps
- JSON

The input format is detected automatically.

**Parameters**

| Name   | Type     | Description                        |
| ------ | -------- | ---------------------------------- |
| `data` | `string` | **Required.** raw chapters content |
