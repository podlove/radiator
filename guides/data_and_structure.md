# Data Model and Structure

## Content


- Network
	- Podcast
		- Episode
			- Audio
	- Audio



### Network

Field   | Type     | Description 
------: | :--------| :-----------
`title` | `String` | The name of the network
`image` | `Image`  | An avatar style image representing the network
 
 
Potential fields open for discussion: 

* `slug` 
* `link`

### Podcast

A **Podcast** belongs to exactly a **Network**

 Field | Type | Description 
   --: | :--  | :--
`shortID` | `String` | Short basis to identify a podcast in an URL, hashtag, etc. Also for easy referring to episodes. E.g. `FS` for freakshow, so an episode becomes `FS130`. Typically between 2 and 5 letters, and has to be unique inside a network as it is used for URL slugs as well.
 `title` | `String` | The name of the podcast
 `image` | `Image`  | An cover image for the podcast
 `subtitle` | `String` | The subtitle line. Is put in `description` and `itunes:subtitle` in the feed. Usually used as one line description display in podcast directories. Currently doesn't appear in iTunes anywhere prominently.
 `summary` | `String` | A longer description of the podcast. Is put in `itunes:summary` in the feed. Is displayed in the iTunes Podcast preview.
`author` | `String` | The Author of this podcast. Prominently displayed by all directories and live players. Put in `itunes:author` for the channel.
`ownerName` | `String` | Owner of the podcast. Put into `itunes:owner` `itunes:name` in the feed
`ownerEmail` | `String` | Owner of the podcast. Put into `itunes:owner` `itunes:email` in the feed - both name and email mostly used for administrative uses - directories e.g. don't expose them.

Important fields currently missing: 

* `language` - [ISO 639-1](http://www.loc.gov/standards/iso639-2/php/code_list.php)

Potential fields open for discussion:  

* `link`
* More iTunes metadata fields  (`itunes:explicit`, `itunes:category`)
* Contributors

Existing fields, worthy of discussion:

* `publishedAt` - is currently both put into the feeds `pubDate` tag (which is quite unused by clients/directories) and used as a switch to say if a podcast is public. @monkeydom: the removing the `publishedAt` would be prudent, as it is ambiguous, and the mechanism to determine the published state of a podcast should be handled differently.

### Episode 

A **Episode** belongs to exactly a **Podcast**

 Field | Type | Description 
 ----: | :--  | :--
`shortID` | `String` | Full short ID of the episode. Defaults to `<shortIDOfPodcast><episodenumberWithLeadingZeros>`, e.g. `FS002`.
 `title` | `String` | The name of the episode. Will be put into `title`, and `itunes:title`. If prefixed with the short ID, the shortID and following whitespace will be stripped for the `itunes:title` to conform with Apple's guidelines there
 `image` | `Image`  | A cover image for the episode. Optional, if none the one of the podcast will be used.
 `subtitle` | `String` | The subtitle line. Is put in `itunes:subtitle` in the feed. Usually used as one line description display tabular listings (e.g. in the iTunes episode table).
 `summary` | `String` | Long form description of the episode. Also known as show notes. Is put in `description` in the feed. No HTML or Links allowed, or if present will not be preserved or shown appropriately by clients. Optional, if clear will be filled by the stripped version of `summaryHtml` if that is present.
 `summaryHTML` | `String` | Long form description of the episode. Also known as show notes. Is put in `content:encoded` in the feed. Clients that are capable will use this, and at least show links, sometimes more. Optional.
 `guid` | `String` | Globally Unique ID of the episode.
 `slug` | `String` | short name that usually looks good in the title of an URL. Defaults to the shortID but can be customized.
 `publishedAt` | `DateTime` | Time of publishing. Currently also used to determine if the  episode has been published and is public.
 `number` | `Integer` | "Track" number of the episode in the podcast. aka `episodeNumber`
 
Potential fields open for discussion:  

* `season`
* `link`
* More iTunes metadata fields (`itunes:explicit`)
* Contributors
 

### Audio

An **Audio** belongs to at least a **Network** or **Episode** but can be used in multiple locations.

 Field | Type | Description 
   --: | :--  | :--
 `title` | `String` | The name of the Audio. Mostly used internally or when not used in an Episode
 `duration` | `String` | Duration of the Audio in [normal play time](https://www.w3.org/TR/media-frags/#naming-time) (e.g. 1:30:00.123 )
 `publishedAt` | `DateTime` | Time of publishing. Currently also used to determine if the  audio has been published and is public.
 

Important fields currently missing: 

* `renderedAudioFiles` | `listOf(AudioFiles)` | Audio files representing rendered version of the audio 


### AudioFile

An **AudioFile** belongs to an **Audio**

 Field | Type | Description 
   --: | :--  | :--
 `title` | `String` | The name of the AudioFile. Maybe this should rather be a filename?
 `mimeType` | `String` | mime type of the audio file. Usually `audio/mpeg` for `.mp3` or `audio/mp4` for `.m4a`
 `byteLength` | `Integer` | File size
 
### Chapter

An **Chapter** belongs to an **Audio**

 Field | Type | Description 
   --: | :--  | :--
`start` | `Integer` | start of chapter in microseconts
`title` | `String` | title of the chapter
`image` | `Image` | Chapter Image (optional)
`link` | `String` | Chapter URL to link to (optional)



#### Feed Specs

* [Apple Podcast Requirements](https://help.apple.com/itc/podcasts_connect/#/itcb54353390)
* [Overcast Info for Podcasters](https://overcast.fm/podcasterinfo)
* [Google RSS feed requirements](https://developers.google.com/search/reference/podcast/rss-feed)
