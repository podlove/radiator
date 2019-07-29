defmodule Radiator.Media.PersonAvatar do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  alias Radiator.Contribution.Person

  def filename(version, {_file, _person}) do
    "avatar_#{version}"
  end

  def storage_dir(_version, {_file, %Person{id: id}}) when not is_nil(id) do
    "person/#{id}"
  end

  def default_url(_, person) do
    "https://robohash.org/#{URI.encode(person.display_name)}?size=200x200"
  end
end
