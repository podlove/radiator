defmodule RadiatorWeb.Api.ContributionView do
  use RadiatorWeb, :view
  alias __MODULE__

  alias HAL.{Document, Link, Embed}

  def render("index.json", assigns = %{contributions: contributions}) do
    %Document{}
    # |> Document.add_link(%Link{
    #   rel: "self",
    #   href: Routes.api_podcast_path(assigns.conn, :index)
    # })
    |> Document.add_embed(%Embed{
      resource: "rad:contribution",
      embed: render_many(contributions, ContributionView, "contribution.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(ContributionView, "contribution.json", assigns)
  end

  def render("contribution.json", assigns = %{contribution: contribution}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_contribution_path(assigns.conn, :show, contribution.id)
    })
    # |> Document.add_link(%Link{
    #   rel: "rad:episodes",
    #   href: Routes.api_episode_path(assigns.conn, :index, podcast.id)
    # })
    |> Document.add_properties(
      Map.take(
        contribution,
        [
          :id,
          :person_id,
          :audio_id,
          :podcast_id,
          :position
        ]
      )
    )
    |> Document.add_property(:contribution_role_id, contribution.role_id)
  end
end
