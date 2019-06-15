defmodule Radiator.Contribution.AudioContribution do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audio_contributions" do
    belongs_to :person, Radiator.Contribution.Person
    belongs_to :audio, Radiator.Directory.Audio

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [])
  end
end
