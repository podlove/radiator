defmodule Radiator.Directory.AudioPublication do
  use Ecto.Schema

  import Ecto.Changeset
  import Radiator.Directory.Publication

  alias Radiator.Directory.{
    Network,
    Audio
  }

  schema "audio_publications" do
    field :publish_state, Radiator.Ecto.AtomType, default: :drafted
    field :published_at, :utc_datetime

    belongs_to :network, Network
    belongs_to :audio, Audio

    has_many :permissions, {"audio_publications_perm", Radiator.Perm.Permission},
      foreign_key: :subject_id

    timestamps()
  end

  def changeset(audio_publication, attrs) do
    audio_publication
    |> cast(attrs, [
      :publish_state,
      :audio_id
    ])
    |> validate_publish_state()
    |> maybe_set_published_at()
  end

  @doc """
  Importer is allowed to set publish date.
  """
  def import_changeset(audio_publication, attrs) do
    audio_publication
    |> cast(attrs, [
      :publish_state,
      :published_at
    ])
    |> validate_publish_state()
  end
end
