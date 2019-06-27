defmodule Radiator.Contribution.AudioContribution do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> cast(attrs, [:position])
  end
end
