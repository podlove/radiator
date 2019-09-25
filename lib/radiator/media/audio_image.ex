defmodule Radiator.Media.AudioImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  @versions [:original, :thumbnail]

  def filename(version, {_file, _audio}) do
    "cover_#{version}"
  end

  def storage_dir(_version, {_file, audio}) do
    "audio/#{audio.id}"
  end
end
