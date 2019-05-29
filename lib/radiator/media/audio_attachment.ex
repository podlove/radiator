defmodule Radiator.Media.AudioAttachment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Media.AudioFile
  alias Radiator.Directory.Audio

  @primary_key false
  schema "audio_attachments" do
    belongs_to :audio_file, AudioFile, primary_key: true
    belongs_to :audio, Audio, foreign_key: :subject_id

    timestamps()
  end

  def changeset(attachment, params) when is_map(params) do
    attachment
    |> cast(params, [])
    |> foreign_key_constraint(:audio_file_id)
  end
end
