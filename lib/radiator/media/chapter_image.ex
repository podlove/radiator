defmodule Radiator.Media.ChapterImage do
  use Arc.Definition
  use Arc.Ecto.Definition
  use Radiator.Media.CoverImageBase

  def filename(version, {file, _chapter}) do
    basename = Path.basename(file.file_name, Path.extname(file.file_name))
    "#{basename}_#{version}"
  end

  def storage_dir(_version, {_file, chapter}) do
    "chapter/#{chapter.id}"
  end
end
