defmodule Radiator.Media.NetworkImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {_file, _network}) do
    "cover_#{version}"
  end

  def storage_dir(_version, {_file, network}) do
    "network/#{network.id}"
  end

  def default_url(_, _network) do
    RadiatorWeb.Endpoint.static_url()
    |> URI.parse()
    |> Map.put(:path, "/images/placeholder_icecream.png")
    |> URI.to_string()
  end
end
