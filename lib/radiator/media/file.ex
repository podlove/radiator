defmodule Radiator.Media.File do
  use Arc.Definition
  use Arc.Ecto.Definition

  def filename(_version, {%{file_name: file_name}, _f}) do
    file_name |> Path.rootname()
  end

  def storage_dir(_version, {_, file}) do
    "file/#{file.id}"
  end
end
