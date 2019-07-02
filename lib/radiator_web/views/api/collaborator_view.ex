defmodule RadiatorWeb.Api.CollaboratorView do
  use RadiatorWeb, :view

  alias HAL.Document

  alias Radiator.Directory.{Network, Podcast}

  def render("show.json", assigns) do
    render(__MODULE__, "collaborator.json", assigns)
  end

  def render("collaborator.json", %{collaborator: collaborator}) do
    %Document{}
    |> Document.add_properties(%{
      username: collaborator.user.name,
      permission: collaborator.permission,
      subject:
        case collaborator.subject do
          %Network{id: id} ->
            %{type: :Network, id: id}

          %Podcast{id: id} ->
            %{type: :Podcast, id: id}
        end
    })
  end
end
