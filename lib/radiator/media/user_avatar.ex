defmodule Radiator.Media.UserAvatar do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :thumbnail]

  def filename(version, {_file, _user}) do
    "avatar_#{version}"
  end

  def storage_dir(_version, {_file, user}) do
    "user/#{user.id}"
  end

  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  def default_url(_, user) do
    "https://robohash.org/#{user.name}?size=200x200"
  end

  def transform(:thumbnail, _) do
    {:convert, "-thumbnail 256x256^ -gravity center -extent 256x256 -format png", :png}
  end
end
