defmodule Radiator.AudioMeta.ChapterImport do
  @spec import_chapters(binary()) :: {:ok, [Chapters.Chapter.t()]} | {:error, any()}
  def import_chapters(data) do
    format = guess_format(data)
    {:ok, Chapters.decode(data, format)}
  end

  @spec guess_format(binary()) :: :psc | :json | :mp4chaps
  defp guess_format(data) do
    cond do
      looks_like_xml?(data) -> :psc
      looks_like_json_list?(data) -> :json
      true -> :mp4chaps
    end
  end

  defp looks_like_xml?(data) do
    data
    |> String.slice(0..10)
    |> String.contains?("<?xml")
  end

  defp looks_like_json_list?(data) do
    first_line = data |> String.split("\n", trim: true, parts: 2) |> List.first()
    String.contains?(first_line, "[")
  end
end
