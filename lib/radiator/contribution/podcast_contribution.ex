defmodule Radiator.Contribution.PodcastContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "podcast_contributions" do
    belongs_to :person, Radiator.Contribution.Person
    belongs_to :podcast, Radiator.Directory.Podcast

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [])
  end
end
