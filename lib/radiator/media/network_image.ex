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

  def default_url(_, network) do
    "https://robohash.org/#{network.id}?size=200x200&set=set4"
  end
end
