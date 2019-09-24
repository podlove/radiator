# Data Model and Structure

## Adminstrative


#### Hierarchy
 
 * User
	
### User

A **User** has one **Person** for its public metadata

 Field | Type | Description 
   --: | :--  | :--

### Collaborator

A **Collaborator** defines the permissions of one **User** for one **Network**, **Podcast**, **Episode** or  **AudioPublication**

 Field | Type | Description 
   --: | :--  | :--
`user` | `User` | the user
`permission` | `Permission` | Permission of this user for the subject, one of `readonly`,`edit`,`manage`,`own`
`subject` | `Subject` | The subject for the permissions for this Collaborator. Either a `Network`, `Podcast`,`Episode` or `AudioPublication`

## Content

#### Hierarchy

* Network
   * Podcast
      * Contribution
      * Episode
          * Audio
          * Contribution
   * AudioPublication
      * Audio
   * Person


### Network

Field   | Type     | Description 
------: | :--------| :-----------
`title` | `String` | The name of the network
`image` | `Image`  | An avatar style image representing the network
 
 
Potential fields open for discussion: 

* `slug` 
* `link`

### Podcast

A **Podcast** belongs to exactly one **Network**

 Field | Type | Description 
   --: | :--  | :--
`shortId` | `String` | Short basis to identify a podcast in an URL, hashtag, etc. Also for easy referring to episodes. E.g. `FS` for freakshow, so an episode becomes `FS130`. Typically between 2 and 5 letters, and has to be unique inside a network as it is used for URL slugs as well.
 `title` | `String` | The name of the podcast
 `image` | `Image`  | An cover image for the podcast
 `publicPage` | `String` | URL of the public page of the episode. defaults to `<radiator_instance_url>/<podcast_slug>` - appears as `link` in the feed.
 `subtitle` | `String` | The subtitle line. Is put in `description` and `itunes:subtitle` in the feed. Usually used as one line description display in podcast directories. Currently doesn't appear in iTunes anywhere prominently.
 `summary` | `String` | A longer description of the podcast. Is put in `itunes:summary` in the feed. Is displayed in the iTunes Podcast preview.
`author` | `String` | The Author of this podcast. Prominently displayed by all directories and live players. Put in `itunes:author` for the channel.
`ownerName` | `String` | Owner of the podcast. Put into `itunes:owner` `itunes:name` in the feed
`ownerEmail` | `String` | Owner of the podcast. Put into `itunes:owner` `itunes:email` in the feed - both name and email mostly used for administrative uses - directories e.g. don't expose them.
`language` | [ISO 639-1](http://www.loc.gov/standards/iso639-2/php/code_list.php) | 

Potential fields open for discussion:  

* More iTunes metadata fields  (`itunes:explicit`, `itunes:category`)
* Contributors

Existing fields, worthy of discussion:

* `publishedAt` - is currently both put into the feeds `pubDate` tag (which is quite unused by clients/directories) and used as a switch to say if a podcast is public. @monkeydom: the removing the `publishedAt` would be prudent, as it is ambiguous, and the mechanism to determine the published state of a podcast should be handled differently.

### Episode 

A **Episode** belongs to exactly one **Podcast**

 Field | Type | Description 
 ----: | :--  | :--
 `guid` | `String` | Globally Unique ID of the episode. Will be prefilled on publish if omitted
`shortId` | `String` | Full short ID of the episode. Defaults to `<shortIDOfPodcast><episodenumberWithLeadingZeros>`, e.g. `FS002`.
 `title` | `String` | The name of the episode. Will be put into `title`, and `itunes:title`. If prefixed with the short ID, the shortID and following whitespace will be stripped for the `itunes:title` to conform with Apple's guidelines there
 `subtitle` | `String` | The subtitle line. Is put in `itunes:subtitle` in the feed. Usually used as one line description display tabular listings (e.g. in the iTunes episode table).
 `summary` | `Text` | Long form description of the episode. Also known as show notes. Is put in `description` in the feed. No HTML or Links allowed, or if present will not be preserved or shown appropriately by clients. Optional, if clear will be filled by the stripped version of `summaryHtml` if that is present.
 `summaryHtml` | `Text` | Long form description of the episode. Also known as show notes. Is put in `content:encoded` in the feed. Clients that are capable will use this, and at least show links, sometimes more. Optional.
 `slug` | `String` | short name that usually looks good in the title of an URL. Defaults to the shortID but can be customized.
 `publishedAt` | `DateTime` | Time of publishing. Currently also used to determine if the episode has been published and is public.
 `number` | `Integer` | "Track" number of the episode in the podcast. aka `episodeNumber` will be put in `itunes:episode` in the feed, and used to generate `shortId` and `guid`
 `publicPage` | String | URL of the public page of the episode. defaults to `<radiator_instance_url>/<podcast_slug>/<episode_slug>` - appears as `link` in the item part of the feed.
 
 
Potential fields open for discussion:  

* `season`
* Contributors
 

### Audio

An **Audio** belongs to at least one **Network** or one **Episode** but can be used in multiple locations.

 Field | Type | Description 
   --: | :--  | :--
 `title` | `String` | The name of the audio. Mostly used internally or when not used in an episode.
 `duration` | `Integer` | Duration of the audio milliseconds, ends up in `itunes:duration` in a feed
 `durationString` | `String` | Duration as normal play time
`image` | `Image` | A cover image for the episode. Optional, if none the one of the podcast will be used.
 `publishedAt` | `DateTime` | Time of publishing. Currently also used to determine if the  audio has been published and is public.
 `audioFiles` | `listOf(AudioFile)` | List of binary files representing this audio

Open for discussion: 

* `renderedAudioFiles` | `listOf(AudioFiles)` | Audio files representing rendered version of the audio.

  Or just some way to store source and rendered files separately to avoid confusion.

### AudioFile

An **AudioFile** belongs to one **Audio**

 Field | Type | Description 
   --: | :--  | :--
 `title` | `String` | The name of the AudioFile. Maybe this should rather be a filename?
 `mimeType` | `String` | mime type of the audio file. Usually `audio/mpeg` for `.mp3` or `audio/mp4` for `.m4a`
 `byteLength` | `Integer` | File size
 
### Chapter

An **Chapter** belongs to one **Audio**

 Field | Type | Description 
   --: | :--  | :--
`start` | `Integer` | Start of chapter in milliseconds
`startString` | `String` | Start as normal play time
`title` | `String` | Title of the chapter
`image` | `Image` | Chapter image (optional)
`link`  | `String` | Chapter URL to link to (optional)

### Person

A **Person** belongs to one network. It can take part in contributions.

Field | Type | Description 
  --: | :--  | :--
`name` | `String` | The full name of the person                                                                  
`nick` | `String` | The nickname of the person                                                                   
`displayName` | `String` | The name that should be used to display this person in public                                
`link` | `String` | A public accessible http URL representing this person (e.g. social media account or homepage)
`image` | `Image`  | Avatar image                                                                                 


### Contribution

A **Contribution** references a Person, a Contribution Role and either one **Audio** or one **Podcast**

Field | Type | Description 
  --: | :--  | :--
`position` | `Float` | Sort position to use when displaying Contributions of the same role

### Contribution Role
Field | Type | Description 
  --: | :--  | :--
`title` | `String` | Title of this role. E.g. `On Air` or `Support`                                                                  
`isPublic` | `boolean` | true if this role will be shown in published information                                                                   
                                                                              


#### Feed Specs

* [Apple podcast requirements](https://help.apple.com/itc/podcasts_connect/#/itcb54353390)
* [Overcast Info for Podcasters](https://overcast.fm/podcasterinfo)
* [Google RSS feed requirements](https://developers.google.com/search/reference/podcast/rss-feed)
