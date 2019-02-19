# Radiator Spark

[![Build Status](https://travis-ci.org/podlove/radiator-spark.svg?branch=master)](https://travis-ci.org/podlove/radiator-spark)

Quick project to get started and give the planned architecture a test drive.

## Show / Podcast

### RSS

- title (RSS requirement)
- description (RSS requirement, up to 4000 characters according to Apple Podcasts Connect)
- link (RSS requirement, dynamically generated)
- pubDate (generated, [RFC 822][rfc822])
- lastBuildDate (generated, [RFC 822][rfc822])
- generator (hardcoded)
- image
- language ([ISO 639], e.g. `en-us`)

### Apple Podcasts Connect

- itunes:image
- itunes:subtitle
- itunes:summary (identical to description)
- itunes:author
- itunes:owner (nested itunes:email, itunes:name)
- itunes:type (hardcoded, `episodic`)

## Episode

### RSS

- title (RSS requirement, one of title or description)
- description (RSS requirement, one of title or description, up to 4000 characters according to Apple Podcasts Connect)
- link (dynamically generated)
- guid (important, internal)
- enclosure (required, contains URL, length, type, e.g. `<enclosure url="http://example.com/p/e001.mp3" length="5650889" type="audio/mpeg"/>`)
- pubDate (generated, [RFC 822][rfc822])

### Apple Podcasts Connect

- itunes:image
- content:encoded
- itunes:subtitle
- itunes:summary (identical to description)
- itunes:title
- itunes:duration (`HH:MM:SS`)
- itunes:episode (episode number)
- itunes:episodeType (hardcoded, `full`)

## Phoenix Generator Commands

```bash
mix phx.gen.json Directory Podcast podcasts \
  title:string \
  subtitle:string \
  description:string \
  image:string \
  author:string \
  owner_name:string \
  owner_email:string \
  language:string \
  published_at:utc_datetime \
  last_built_at:utc_datetime
```

```bash
mix phx.gen.json Directory Episode episodes \
  podcast_id:references:podcasts \
  title:string \
  subtitle:string \
  description:string \
  content:string \
  image:string \
  enclosure_url:string \
  enclosure_length:string \
  enclosure_type:string \
  duration:string \
  guid:string \
  number:integer \
  published_at:utc_datetime
```

## API Usage Examples

### Create a Podcast

```bash
curl -sH "Content-Type: application/json" -X POST -d '{"podcast":{"title": "Ep001"}}' http://localhost:4000/api/podcasts
```

### Create an Episode

```bash
curl -sH "Content-Type: application/json" -X POST -d '{"episode":{"title": "Ep001"}}' http://localhost:4000/api/podcasts/1/episodes
```

## How would a hal+json document look like

### Podcast

```json
{
  "_links": {
    "self": { "href": "/podcasts/1" },
  },
  "id": 1,
  ...
  "title": "My Podcast"
}
```

### Podcast List

```json
{
  "_links": {
    "self": { "href": "/podcasts" },
    "next": { "href": "/podcasts?page=2" },
    "curies": [{ "name": "rad", "href": "https://podlove.org/radiator/docs/rels/{rel}", "templated": true }]
  },
  "_embedded": {
    "rad:podcasts": [
      {
        "_links": {
          "self": { "href": "/podcasts/1" },
        },
        "id": 1,
        ...
        "title": "My Podcast"
      }      
    ]
  }
}
```

### Episode

```json
{
  "_links": {
    "self": { "href": "/podcasts/1/episodes/2" },
    "curies": [{ "name": "rad", "href": "https://podlove.org/radiator/docs/rels/{rel}", "templated": true }]
  },
  "_embedded": {
    "rad:podcast": {
      "_links": {
        "self": { "href": "/podcasts/1" },
      },
      ...
      "title": "My Podcast"
    }
  },
  "id": 2,
  ...
  "title": "Episode 001"
}
```

## Storage

- [Minio](https://minio.io/), S3 compatible object storage
- compatible with [ExAws](https://hexdocs.pm/ex_aws/ExAws.html), an Elixir client for AWS services

### Implemented

- run Minio server via homebrew:

```bash
brew install minio/stable/minio
minio server /data
```

- API Endpoint: URL Presigning + Upload
- Access/Download file through Phoenix endpoint

### Upload Example (fish shell script)

```bash
set podcast_id 3
set episode_id 5
set filepath "/local/path/to/episode001.mp3"

set filename (string split -n -r -m1 / $filepath | tail -n 1)

# PUT $storage_url uploads file
# GET $storage_url downloads file
set storage_url "http://localhost:4000/api/podcasts/$podcast_id/episodes/$episode_id/upload/$filename"

# get presigned url
set presigned_url (curl -s -X POST $storage_url | jq -r .upload_url)

set curl_date (date -R)

echo "=== upload file ==="
echo ""
curl -i -X PUT -T "$filepath" \
    -H "Date: $curl_date" \
    -H "Content-Type: application/octet-stream" \
    $presigned_url

echo "=== test access the file ==="
echo ""
curl -I $storage_url
```


## Notes

- We set out to use "Show" as the generic term for podcasts. However, that is confusing in Phoenix as "show" is used by convention in controller/view contexts (referring to rendering a single entry of a list). Which is why I go back to "Podcast" for now.

## Reference

- [RSS 2.0 Spec][rss2]
- [Apple Podcasts Connect Spec][apple podcasts]
- [Feed Paging (RFC5005)][rfc5005]

[rfc822]: http://asg.web.cmu.edu/rfc/rfc822.html
[apple podcasts]: https://help.apple.com/itc/podcasts_connect/#/itcb54353390
[rss2]: https://cyber.harvard.edu/rss/rss.html
[rfc5005]: https://tools.ietf.org/html/rfc5005#section-3
[ISO 639]: http://www.loc.gov/standards/iso639-2/php/code_list.php
