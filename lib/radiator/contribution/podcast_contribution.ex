defmodule Radiator.Contribution.PodcastContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "podcast_contributions" do
    belongs_to :person, Radiator.Contribution.Person
    belongs_to :podcast, Radiator.Directory.Podcast
    belongs_to :role, Radiator.Contribution.Role

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [])
  end
end
