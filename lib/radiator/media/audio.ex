defmodule Radiator.Media.Audio do
  use Ecto.Schema
  use Arc.Ecto.Schema

  import Ecto.Changeset

  schema "audio" do
    field :file, Radiator.Media.AudioFile.Type
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title])
    |> cast_attachments(attrs, [:file])
  end
end
