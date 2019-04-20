defmodule Radiator.Media.AudioFile do
  use Arc.Definition
  use Arc.Ecto.Definition

  def storage_dir(_version, {_file, audio}) do
    "audio/#{audio.id}"
  end

  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
