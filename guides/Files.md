# Files

Files are managed by [arc] with [arc_ecto].

## Audio Files

            +---------+
         +--+ Network +-+
         |  +---------+ |
         |              |
    +----+----+         |
    | Podcast |         |
    +----+----+         |
         |              |
         |              |
         |              |
    +----+----+    +----+--+    +-----------+
    | Episode +----+ Audio +----+ AudioFile |
    +---------+    +----+--+    +-----------+
                        |
                        +------------+
                        |            |
                  +-----+----+ +-----+------+
                  | Chapters | | Transcript |
                  +----------+ +------------+

`Radiator.Directory.Audio` is the central container. It can stand on its own and supply a web player with metadata. An `Audio` exists either in a `Radiator.Directory.Network`, or attached to one or more `Radiator.Directory.Episode`s. `Audio` contains one or more `AudioFile`s. If there is more than one `Radiator.Media.AudioFile`, each file is a different file format of the same audio track. Complex audio metadata like chapters and transcripts (tbd) belong to `Audio`. `Episode` represents the connection between `Audio` and `Radiator.Directory.Podcast`, while enriching it with episode-specific metadata (e.g. episode number).

The reason for this abstraction is that it allows audios to exist outside of an episode. That enables the user to add an audio to Radiator and generate an embeddable web player, even if it does not belong to a podcast. Furthermore it enables reuse of the same audio in multiple podcasts or even republication of the same audio within the same podcast without duplicating the audio object and metadata.

### Upload

Use `Radiator.Media.AudioFileUpload` to upload audio files. It is meant for controllers as it takes a `Plug.Upload` struct, but that can be constructed manually as well if required.

```elixir
upload = %Plug.Upload{
  content_type: "audio/mpeg",
  filename: "ls013-ultraschall.mp3",
  path: "/tmp/ls013-ultraschall.mp3"
}
{:ok, audio_file} = Radiator.Media.AudioFileUpload.upload(upload, audio)
```

See `Radiator.Media.AudioFileUpload.upload/2` for details.

It works with external URLs as well, using `Radiator.Media.AudioFileUpload.sideload/2`.

```elixir
{:ok, audio_file} = Radiator.Media.AudioFileUpload.sideload(upload, audio)
```

## Cover Images & User Avatars

Images are referenced in the schemas they are used as they are 1:1 relationships.

They are:

- `Radiator.Auth.User` field `:image`
- `Radiator.Directory.Network` field `:image`
- `Radiator.Directory.Podcast` field `:image`
- `Radiator.Directory.Episode` field `:image`
- `Radiator.Directory.Audio` field `:image`

### Access

Available versions are `:original` and `:thumbnail` (256x256).

```elixir
alias Radiator.Media.PodcastImage

# get podcast image URL
PodcastImage.url({podcast.image, podcast})

# get podcast image thumbnail URL
PodcastImage.url({podcast.image, podcast}, :thumbnail)
```

### Upload

Via schema/arc_ecto:

```elixir
podcast
|> Podcast.changeset(%{
  image: %Plug.Upload{path: "/tmp/image.jpg", filename: "image.jpg"}
})
|> Repo.update
```

## GraphQL

Send POST request with content type `multipart/form-data`. Using curl, `-F` is key.

### Example: Upload episode audio with curl

```bash
curl -X POST -F query='mutation { uploadAudioFile(episode_id: 1, file: "myupload") {mimeType byteLength title } }'  -F myupload=@test/fixtures/pling.mp3 localhost:4000/api/graphql
# {
#   "data": {
#     "uploadAudioFile": {
#       "title": "pling.mp3",
#       "mimeType": "application/octet-stream",
#       "byteLength": 8476
#     }
#   }
# }
```

### Example: Upload network image with curl

```bash
curl -X POST -F query='mutation { updateNetwork(id: 1, network: {title: "updated title", image: "myupload"}) { id title image }}'  -F myupload=@test/fixtures/image.jpg localhost:4000/api/graphql
# {
#   "data": {
#     "updateNetwork": {
#       "title": "updated title",
#       "image": "http://localhost:9000/radiator/network/1/cover_original.jpg?v=63723926016",
#       "id": "1"
#     }
#   }
# }
```

Setting the image for podcasts and episodes works in the same way.

[arc]: https://hex.pm/packages/arc
[arc_ecto]: https://hex.pm/packages/arc_ecto
