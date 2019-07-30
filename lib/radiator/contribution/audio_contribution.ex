defmodule Radiator.Contribution.AudioContribution do
  use Ecto.Schema
  import Ecto.Changeset
  alias Radiator.Repo

  schema "audio_contributions" do
    field :position, :float

    belongs_to :person, Radiator.Contribution.Person
    belongs_to :audio, Radiator.Directory.Audio
    belongs_to :role, Radiator.Contribution.Role

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:position, :person_id, :role_id, :audio_id])
    |> foreign_key_constraint(:person)
    |> foreign_key_constraint(:role)
    |> foreign_key_constraint(:audio)
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
