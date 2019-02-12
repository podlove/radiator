## Show / Podcast

RSS

- title (RSS requirement)
- description (RSS requirement, up to 4000 characters according to Apple Podcasts Connect)
- link (RSS requirement, dynamically generated)
- pubDate (generated, [RFC 822][rfc822])
- lastBuildDate (generated, [RFC 822][rfc822])
- generator (hardcoded)
- image
- language ([ISO 639], e.g. `en-us`)

Apple Podcasts Connect

- itunes:image
- itunes:subtitle
- itunes:summary (identical to description)
- itunes:author
- itunes:owner (nested itunes:email, itunes:name)
- itunes:type (hardcoded, `episodic`)

## Episode

RSS

- title (RSS requirement, one of title or description)
- description (RSS requirement, one of title or description, up to 4000 characters according to Apple Podcasts Connect)
- link (dynamically generated)
- guid (important, internal)
- enclosure (required, contains URL, length, type, e.g. `<enclosure url="http://example.com/p/e001.mp3" length="5650889" type="audio/mpeg"/>`)
- pubDate (generated, [RFC 822][rfc822])

Apple Podcasts Connect

- itunes:image
- content:encoded
- itunes:subtitle
- itunes:summary (identical to description)
- itunes:title
- itunes:duration (`HH:MM:SS`)
- itunes:episode (episode number)
- itunes:episodeType (hardcoded, `full`)

## Phoenix Generator Commands

```
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

```
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

## Notes

- We set out to use "Show" as the generic term for podcasts. However, that is confusing in Phoenix as "show" is used by convention in controller/view contexts (referring to rendering a single entry of a list). Which is why I go back to "Podcast" for now.

## Reference

- [RSS 2.0 Spec][rss2]
- [Apple Podcasts Connect Spec][apple podcasts]
- [Feed Paging (RFC5005)][rfc5005]

[rfc822]: http://asg.web.cmu.edu/rfc/rfc822.html
[apple podcasts]: https://help.apple.com/itc/podcasts_connect/#/itcb54353390
[rss2]: https://cyber.harvard.edu/rss/rss.html
[rfc5005]: ]https://tools.ietf.org/html/rfc5005#section-3
[ISO 639]: http://www.loc.gov/standards/iso639-2/php/code_list.php
