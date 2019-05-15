defmodule Radiator.Media.EpisodeAttachment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Media.AudioFile
  alias Radiator.Directory.Episode

  @primary_key false
  schema "episode_attachments" do
    belongs_to :audio, AudioFile, primary_key: true
    belongs_to :episode, Episode, foreign_key: :subject_id

    timestamps()
  end

  def changeset(attachment, params) when is_map(params) do
    attachment
    |> cast(params, [])
    |> foreign_key_constraint(:audio_id)
  end
end
