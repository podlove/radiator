defmodule Radiator.Media.PersonAvatar do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {_file, _person}) do
    "avatar_#{version}"
  end

  def storage_dir(_version, {_file, person}) do
    "person/#{person.id}"
  end

  def default_url(_, person) do
    "https://robohash.org/#{person.real_name}?size=200x200"
  end
end
