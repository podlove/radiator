# Statistics

Download statistics can be accessed via GraphQL API. They are available for networks, podcasts, episodes and audio publications.

Here are some sample queries.

- [Total Downloads](#total-downloads)
- [Monthly Downloads of 2019](#monthly-downloads-of-2019)
- [Daily Downloads of August 2019](#daily-downloads-of-august-2019)
- [User Agent Statistics](#user-agent-statistics)

## Total Downloads

```gql
query {
  podcast(id: 1) {
    statistics {
      downloads {
        total
      }
    }
  }
}
```

```json
{
  "data": {
    "podcast": {
      "statistics": {
        "downloads": {
          "total": {
            "downloads": 25840
          }
        }
      }
    }
  }
}
```

## Monthly Downloads of 2019

```gql
query {
  podcast(id: 1) {
    statistics {
      downloads {
        monthly(from: "2019-01", until: "2019-12") {
          date
          value
        }
      }
    }
  }
}
```

```json
{
  "data": {
    "podcast": {
      "statistics": {
        "downloads": {
          "monthly": [
            ...,
            {
              "date": "2019-03",
              "value": 451
            },
            {
              "date": "2019-02",
              "value": 413
            },
            {
              "date": "2019-01",
              "value": 454
            }
          ]
        }
      }
    }
  }
}
```

## Daily Downloads of August 2019

```gql
query {
  podcast(id: 1) {
    statistics {
      downloads {
        daily(from: "2019-08-01", until: "2019-08-31") {
          date
          value
        }
      }
    }
  }
}
```

```json
{
  "data": {
    "podcast": {
      "statistics": {
        "downloads": {
          "daily": [
            {
              "date": "2019-08-31",
              "value": 34
            },
            {
              "date": "2019-08-30",
              "value": 31
            },
            {
              "date": "2019-08-29",
              "value": 22
            },
            ...
          ]
        }
      }
    }
  }
}
```

## User Agent Statistics

```gql
query {
  podcast(id: 1) {
    statistics {
      userAgents {
        total {
          clientName {
            absolute
            percent
            title
          }
          clientType {
            absolute
            percent
            title
          }
          deviceType {
            absolute
            percent
            title
          }
          osName {
            absolute
            percent
            title
          }
        }
      }
    }
  }
}
```

```json
{
  "data": {
    "podcast": {
      "statistics": {
        "userAgents": {
          "total": {
            "clientName": [
              {
                "absolute": 5313,
                "percent": 20.56,
                "title": "Chrome Mobile"
              },
              {
                "absolute": 3135,
                "percent": 12.13,
                "title": "Unknown"
              },
              ...
            ],
            "clientType": [
              {
                "absolute": 15660,
                "percent": 60.6,
                "title": "browser"
              },
              {
                "absolute": 4271,
                "percent": 16.53,
                "title": "mobile app"
              },
              ...
            ],
            "deviceType": [
              {
                "absolute": 11147,
                "percent": 43.14,
                "title": "smartphone"
              },
              {
                "absolute": 6542,
                "percent": 25.32,
                "title": "desktop"
              },
              ...
            ],
            "osName": [
              {
                "absolute": 13490,
                "percent": 52.21,
                "title": "Android"
              },
              {
                "absolute": 4322,
                "percent": 16.73,
                "title": "iOS"
              },
              ...
            ]
          }
        }
      }
    }
  }
}
```
