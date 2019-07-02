# REST API

- [REST API](#REST-API)
  - [Authentication](#Authentication)
    - [Login](#Login)
      - [Parameters](#Parameters)
      - [Response](#Response)
    - [Prolong Session](#Prolong-Session)
      - [Response](#Response-1)
  - [Networks](#Networks)
    - [Parameters for Create & Update](#Parameters-for-Create--Update)
    - [Create](#Create)
    - [Read](#Read)
    - [Update](#Update)
    - [Delete](#Delete)
  - [Network Collaborators](#Network-Collaborators)
    - [Parameters for Create & Update](#Parameters-for-Create--Update-1)
      - [Read](#Read-1)
      - [Create](#Create-1)
      - [Update](#Update-1)
      - [Delete](#Delete-1)
  - [Podcasts](#Podcasts)
    - [Parameters for Create & Update](#Parameters-for-Create--Update-2)
    - [Create](#Create-2)
    - [Read](#Read-2)
    - [Update](#Update-2)
    - [Delete](#Delete-2)
  - [Episodes](#Episodes)
    - [Parameters for Create & Update](#Parameters-for-Create--Update-3)
    - [Create](#Create-3)
    - [Read](#Read-3)
    - [Update](#Update-3)
    - [Delete](#Delete-3)

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

| Name             | Type     | Description                  |
| ---------------- | -------- | ---------------------------- |
| `network[title]` | `string` | **Required.** Network title. |

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
PUT /api/rest/v1/networks/:id
```

### Delete

```
DELETE /api/rest/v1/networks/:id
```

## Network Collaborators

### Parameters for Create & Update

| Name                       | Type     | Description                                                      |
| -------------------------- | -------- | ---------------------------------------------------------------- |
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
PUT /api/rest/v1/networks/:id/collaborators/:username 
```

#### Delete

```
DELETE /api/rest/v1/networks/:id/collaborators/:username 
```

## Podcasts

### Parameters for Create & Update

| Name                   | Type      | Description   |
| ---------------------- | --------- | ------------- |
| `podcast[title]`       | `string`  | **Required.** |
| `podcast[network_id]`  | `integer` | **Required.** |
| `podcast[subtitle]`    | `string`  |               |
| `podcast[description]` | `string`  |               |
| `podcast[author]`      | `string`  |               |
| `podcast[owner_name]`  | `string`  |               |
| `podcast[owner_email]` | `string`  |               |
| `podcast[language]`    | `string`  |               |

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
PUT /api/rest/v1/podcasts/:id
```

### Delete

```
DELETE /api/rest/v1/podcasts/:id
```

## Podcasts Collaborators

### Parameters for Create & Update

| Name                       | Type     | Description                                                      |
| -------------------------- | -------- | ---------------------------------------------------------------- |
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
PUT /api/rest/v1/podcasts/:id/collaborators/:username 
```

#### Delete

```
DELETE /api/rest/v1/podcasts/:id/collaborators/:username 
```

## Episodes

### Parameters for Create & Update

| Name                   | Type      | Description   |
| ---------------------- | --------- | ------------- |
| `episode[title]`       | `string`  | **Required.** |
| `episode[podcast_id]`  | `integer` | **Required.** |
| `episode[subtitle]`    | `string`  |               |
| `episode[description]` | `string`  |               |
| `episode[number]`      | `integer` |               |
| `episode[short_id]`    | `string`  |               |

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
PUT /api/rest/v1/episodes/:id
```

### Delete

```
DELETE /api/rest/v1/episodes/:id
```
