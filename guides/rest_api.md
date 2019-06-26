# REST API

## Authentication

To make full use of the API you need to authenticate as an existing user. A successful authentication returns a *token* that you can use in subsequent requests to authenticate yourself as that user. You do this by setting the token as request header.

> curl -H "Authorization: Bearer AUTH-TOKEN" http://localhost:4000/api/rest/v1/

```
POST /api/rest/v1/auth
```

### Parameters

| Name       | Type     | Description                      |
| ---------- | -------- | -------------------------------- |
| `name`     | `string` | **Required.** Username or email. |
| `password` | `string` | **Required.** Password.          |

### Response

```json
{
  "expires_at": "2019-06-25T10:43:29Z",
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NjE0NTk0MDksImlzcyI6InJhZGlhdG9yIiwic3ViIjoiYWRtaW4iLCJ0eXAiOiJhcGlfc2Vzc2lvbiJ9.c1upk8TaENs-r5xZUXxUyZw4PEs5z7hpDusQtKDIwjJKZE1uKdbVs4mzcQdyJNHWHGdzSECwBtX1M4g_u-AhJg",
  "username": "admin"
}
```

## Prolong Session

```
POST /api/rest/v1/auth/prolong
```

### Response

```json
{
  "expires_at": "2019-06-25T10:44:46Z",
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NjE0NTk0ODYsImlzcyI6InJhZGlhdG9yIiwic3ViIjoiYWRtaW4iLCJ0eXAiOiJhcGlfc2Vzc2lvbiJ9.4V6PniEaPlwhtcm8bQDGLapq_HTLL_0wnlYNMU2qpzofkmWGEfFP-sDnIOwzVfQ_JlUXfiXOiQ-hZYsVbHOwTg",
  "username": "admin"
}
```
