defmodule Radiator.Contribution.PodcastContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "podcast_contributions" do
    field :position, :float

    belongs_to :person, Radiator.Contribution.Person
    belongs_to :podcast, Radiator.Directory.Podcast
    belongs_to :role, Radiator.Contribution.Role

    timestamps()
  end

  @doc false
  def changeset(contribution, attrs) do
    contribution
    |> cast(attrs, [:position])
  end
end
