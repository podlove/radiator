# REST API

- [API Usage](#api-usage)
- [Authentication](#authentication)
  - [Login](#login)
    - [Parameters](#parameters)
    - [Response](#response)
  - [Prolong Session](#prolong-session)
    - [Response](#response-1)
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
- [People](#people)
  - [Parameters for Create & Update](#parameters-for-create--update-5)
  - [Create](#create-5)
  - [Read](#read-5)
  - [Update](#update-5)
  - [Delete](#delete-5)
- [Audio](#audio)
  - [Parameters for Create & Update](#parameters-for-create--update-6)
  - [Create](#create-6)
  - [Read](#read-6)
  - [Update](#update-6)
  - [Delete](#delete-6)
- [Audio File](#audio-file)
  - [Parameters for Create](#parameters-for-create)
  - [Create](#create-7)
  - [Read](#read-7)
- [Audio Chapters](#audio-chapters)
  - [Parameters for Create & Update](#parameters-for-create--update-7)
  - [Create](#create-8)
  - [Read](#read-8)
  - [Update](#update-7)
  - [Delete](#delete-7)
- [Tasks](#tasks)
  - [Parameters for Create](#parameters-for-create-1)
    - [Import podcast feed](#import-podcast-feed)
  - [Create](#create-9)
  - [Read](#read-9)
  - [Delete](#delete-8)

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
  "network": {
    "title": "Example Network"
  }
});
```

`DELETE` methods will always return a `204 No Content` when authenticated and the necessary params were in place.

## Authentication

To make full use of the API you need to authenticate as an existing user. A successful authentication returns a _token_ that you can use in subsequent requests to authenticate yourself as that user. You do this by setting the token as request header.

> curl -H "Authorization: Bearer AUTH-TOKEN" http://localhost:4000/api/rest/v1/

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

### Prolong Session

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

| Name                   | Type      | Description                                                                           |
| ---------------------- | --------- | ------------------------------------------------------------------------------------- |
| `podcast[title]`       | `string`  | **Required.**                                                                         |
| `podcast[network_id]`  | `integer` | **Required.**                                                                         |
| `podcast[short_id]`    | `string`  | Short ID for this podcast, also used as slug. 2-5 characters usually, e.g. FS,FAN,ATP |
| `podcast[subtitle]`    | `string`  | Attention grabbing one liner appearing in lists/directories                           |
| `podcast[summary]`     | `string`  | Short multiline description, appears in iTunes Preview                                |
| `podcast[image]`       | `Image`   | Cover Image                                                                           |
| `podcast[author]`      | `string`  | One line description of publisher                                                     |
| `podcast[language]`    | `string`  | ISO 639-1                                                                             |
| `podcast[owner_name]`  | `string`  |                                                                                       |
| `podcast[owner_email]` | `string`  |                                                                                       |
| `podcast[slug]`        | `string`  |                                                                                       |

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

| Name                      | Type      | Description                                                             |
| ------------------------- | --------- | ----------------------------------------------------------------------- |
| `episode[title]`          | `string`  | **Required.**                                                           |
| `episode[podcast_id]`     | `integer` | **Required.**                                                           |
| `episode[short_id]`       | `string`  | Full combined short id, usually short_id + Number                       |
| `episode[guid]`           | `string`  | guid, prefilled on publish if unspecified                               |
| `episode[subtitle]`       | `string`  | One line description of the episode                                     |
| `episode[summary]`        | `text`    | Multiline description, plain text only                                  |
| `episode[summary_html]`   | `text`    | Multiline description, html. Will be put in `content:encoded` in a feed |
| `episode[summary_source]` | `text`    | Multiline description, arbitrary format chosen by frontends.            |
| `episode[number]`         | `integer` | Episode "Track" number, will be put in `itunes:episode` in the feed     |
| `episode[publish_state]`  | `string`  | Publication state. "drafted", "scheduled", "published" or "unpublished".     |

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

## Audio

### Parameters for Create & Update

| Name                | Type      | Description                                                |
| ------------------- | --------- | ---------------------------------------------------------- |
| `audio[network_id]` | `integer` | Network ID. Either network ID or episode ID must be given. |
| `audio[episode_id]` | `integer` | Episode ID. Either network ID or episode ID must be given. |
| `audio[title]`      | `string`  |                                                            |
| `audio[image]`      | `file`    | Audio image.                                               |
| `audio[duration]`   | `integer` | Audio duration in milliseconds                             |

### Create

```
POST /api/rest/v1/audios
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

> ⚠️ An [Audio](#Audio) must exist before an Audio File can be created.

### Parameters for Create

| Name                   | Type      | Description                                                 |
| ---------------------- | --------- | ----------------------------------------------------------- |
| `audio_file[audio_id]` | `integer` | **Required.** File is attached to Audio object of given ID. |
| `audio_file[file]`     | `file`    | audio file to upload                                        |
| `audio_file[title]`    | `string`  | file title                                                  |

### Create

```
POST /api/rest/v1/audio_file
```

### Read

```
GET /api/rest/v1/audio_file/:id
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
| `chapter[file]`     | `image`   | chapter image                                                  |

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
