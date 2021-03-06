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

  def default_url(_, _profile) do
    RadiatorWeb.Endpoint.static_url()
    |> URI.parse()
    |> Map.put(:path, "/images/placeholder_female_avatar.png")
    |> URI.to_string()
  end
end
