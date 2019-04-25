# Files

Files are managed by [arc] with [arc_ecto].

## Audio Files

The `Radiator.Media.AudioFile` schema represents a single audio file. It is attached to either an episode or network via `Radiator.Media.Attachment`.

### Access

Currently it can be assumed that each episode only has one audio attachment. For convenience, this is a dedicated association called `:enclosure`. You can preload it with `Repo.preload(episode, :enclosure)`.

### Upload

Use `Radiator.Media.AudioFileUpload` to upload audio files. It is meant for controllers as it takes a `Plug.Upload` struct, but that can be constructed manually as well if required.

```elixir
upload = %Plug.Upload{
  content_type: "audio/mpeg",
  filename: "ls013-ultraschall.mp3",
  path: "/tmp/ls013-ultraschall.mp3"
}
{:ok, audio, attachment} = Radiator.Media.AudioFileUpload.upload(upload, episode)
```

See `Radiator.Media.AudioFileUpload.upload/2` for details.

## Cover Images & User Avatars

Images are referenced in the schemas they are used as they are 1:1 relationships.

They are:

- `Radiator.Auth.User` field `:avatar`
- `Radiator.Directory.Network` field `:image`
- `Radiator.Directory.Podcast` field `:image`
- `Radiator.Directory.Episode` field `:image`

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

[arc]: https://hex.pm/packages/arc
[arc_ecto]: https://hex.pm/packages/arc_ecto

