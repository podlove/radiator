defmodule RadiatorWeb.Api.FileSlotView do
  use RadiatorWeb, :view

  alias HAL.{Document, Embed}

  def render("index.json", %{slots: slots}) do
    %Document{}
    |> Document.add_embed(%Embed{
      resource: "rad:file_slot",
      embed:
        slots
        |> Enum.map(fn slot ->
          %Document{}
          |> Document.add_properties(%{
            slot: slot.slot,
            file: render(__MODULE__, "file.json", file: slot.file)
          })
        end)
    })
  end

  # todo: move into own FileView
  def render("file.json", %{file: file = %Radiator.Storage.File{}}) do
    %{
      id: file.id
    }
  end

  def render("file.json", _) do
    "empty"
  end
end
