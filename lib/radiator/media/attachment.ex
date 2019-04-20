defmodule Radiator.Media.Attachment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Media.Audio

  @primary_key false
  schema "abstract table: attachment" do
    belongs_to :audio, Audio, primary_key: true

    field :subject_id, :integer, primary_key: true

    timestamps()
  end

  def changeset(attachment, params) when is_map(params) do
    attachment
    |> cast(params, [])
    |> foreign_key_constraint(:audio_id)
  end
end
