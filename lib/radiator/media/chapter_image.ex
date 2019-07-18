defmodule Radiator.Media.ChapterImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {file, _chapter}) do
    basename = Path.basename(file.file_name, Path.extname(file.file_name))
    "#{basename}_#{version}"
  end

  # fixme: when the start is changed after the image is uploaded the connection to the image is probably lost?
  # reintroduce a stable internal id just for this, or find another solution
  def storage_dir(_version, {_file, chapter}) do
    "chapter/#{chapter.audio_id}_#{chapter.start}"
  end
end
