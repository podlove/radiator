defmodule Radiator.Contribution.PodcastContribution do
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Repo

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
    |> cast(attrs, [:position, :person_id, :role_id, :podcast_id])
    |> foreign_key_constraint(:person)
    |> foreign_key_constraint(:role)
    |> foreign_key_constraint(:podcast)
    |> ensure_position()
  end

  def ensure_position(changeset) do
    case fetch_field(changeset, :position) do
      {:data, nil} -> change(changeset, %{position: next_position_value()})
      _ -> changeset
    end
  end

  def next_position_value() do
    {:ok, %Postgrex.Result{rows: [[value]]}} =
      Repo.query("select max(position) from #{__schema__(:source)}")

    # the fraction is important to satisfy the :float type
    (value || 0) + 1.0
  end
end
