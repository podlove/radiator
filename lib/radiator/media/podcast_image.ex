defmodule Radiator.Media.PodcastImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {_file, _podcast}) do
    "cover_#{version}"
  end

  def storage_dir(_version, {_file, podcast}) do
    "podcast/#{podcast.id}"
  end
end
