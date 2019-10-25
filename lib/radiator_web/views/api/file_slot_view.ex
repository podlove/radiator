defmodule RadiatorWeb.Api.FileSlotView do
  use RadiatorWeb, :view

  alias HAL.{Document, Embed}
  alias Radiator.Directory.Audio

  def render("index.json", _assigns) do
    %Document{}
    |> Document.add_embed(%Embed{
      resource: "rad:file_slot",
      embed:
        Audio.slots()
        |> Enum.map(fn slot ->
          %Document{} |> Document.add_properties(%{slot: slot, file: :empty})
        end)
    })
  end
end
