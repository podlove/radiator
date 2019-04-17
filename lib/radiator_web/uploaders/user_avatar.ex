defmodule Radiator.UserAvatar do
  use Arc.Definition

  def storage_dir(_version, {_file, user}) do
    "user/avatars/#{user.id}"
  end

  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
