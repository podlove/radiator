defmodule Radiator.Media.EpisodeImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {_file, _episode}) do
    "cover_#{version}"
  end

  def storage_dir(_version, {_file, episode}) do
    "episode/#{episode.id}"
  end
end
