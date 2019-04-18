defmodule Radiator.Media.AudioFile do
  use Arc.Definition
  use Arc.Ecto.Definition

  def storage_dir(_version, {_file, episode}) do
    "network-#{episode.podcast.network.id}/podcast-#{episode.podcast.id}/episode-#{episode.id}/"
  end

  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
