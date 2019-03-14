defmodule RadiatorWeb.Admin.EpisodeView do
  use RadiatorWeb, :view

  def format_bytes(number, precision \\ 2)

  def format_bytes(nil, _) do
    "? Bytes"
  end

  def format_bytes(number, _precision) when number < 1_024 do
    "#{number} Bytes"
  end

  def format_bytes(number, precision) when number < 1_048_576 do
    "#{Float.round(number / 1024, precision)} kB"
  end

  def format_bytes(number, precision) do
    "#{Float.round(number / 1024 / 1024, precision)} MB"
  end
end
