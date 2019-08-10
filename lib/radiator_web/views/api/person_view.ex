defmodule RadiatorWeb.Api.PersonView do
  use RadiatorWeb, :view
  alias __MODULE__

  alias HAL.{Document, Link, Embed}

  import RadiatorWeb.ContentHelpers

  def render("index.json", assigns = %{people: people}) do
    %Document{}
    # |> Document.add_link(%Link{
    #   rel: "self",
    #   href: Routes.api_podcast_path(assigns.conn, :index)
    # })
    |> Document.add_embed(%Embed{
      resource: "rad:person",
      embed: render_many(people, PersonView, "person.json", assigns)
    })
  end

  def render("show.json", assigns) do
    render(PersonView, "person.json", assigns)
  end

  def render("person.json", assigns = %{person: person}) do
    %Document{}
    |> Document.add_link(%Link{
      rel: "self",
      href: Routes.api_person_path(assigns.conn, :show, person.id)
    })
    # |> Document.add_link(%Link{
    #   rel: "rad:episodes",
    #   href: Routes.api_episode_path(assigns.conn, :index, podcast.id)
    # })
    |> Document.add_properties(
      Map.take(
        person,
        [
          :id,
          :name,
          :display_name,
          :nick,
          :email,
          :link,
          :network_id
        ]
      )
    )
    |> Document.add_property(:image, person_image_url(person))
  end
end
