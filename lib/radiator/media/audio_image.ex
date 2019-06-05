defmodule Radiator.Media.AudioImage do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :thumbnail]

  def filename(version, {_file, _episode}) do
    "cover_#{version}"
  end

  def storage_dir(_version, {_file, audio}) do
    "audio/#{audio.id}"
  end

  def s3_object_headers(_version, {file, _audio}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  def transform(:thumbnail, _) do
    {:convert, "-thumbnail 256x256^ -gravity center -extent 256x256 -format png", :png}
  end
end
