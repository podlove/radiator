defmodule Radiator.Media.Audio do
  use Ecto.Schema
  use Arc.Ecto.Schema

  import Ecto.Changeset

  schema "audios" do
    field :file, Radiator.Media.AudioFile.Type
    field :title, :string
    field :mime_type, :string
    field :byte_length, :integer

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :mime_type, :byte_length])
    |> cast_attachments(attrs, [:file])
  end
end
