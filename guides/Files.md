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

Images are referenced directly in the schemas they are used, as they are always 1:1 relationships.

They are:

- `Radiator.Auth.User` field `:avatar`
- TODO: network cover
- TODO: podcast cover
- TODO: episode cover

[arc]: https://hex.pm/packages/arc
[arc_ecto]: https://hex.pm/packages/arc_ecto

