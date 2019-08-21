defmodule Radiator.Media.UserAvatar do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  alias Radiator.Directory.UserProfile

  def filename(version, {_file, _person}) do
    "avatar_#{version}"
  end

  def storage_dir(_version, {_file, %UserProfile{id: id}}) when not is_nil(id) do
    "user/#{id}"
  end

  def default_url(_, profile) do
    "https://robohash.org/#{profile.id}?size=200x200"
  end
end
