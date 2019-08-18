defmodule Radiator.Directory.AudioPublication do
  use Ecto.Schema

  import Ecto.Changeset
  import Radiator.Directory.Publication

  alias Radiator.Directory.{
    Network,
    Audio,
    TitleSlug
  }

  schema "audio_publications" do
    field :title, :string
    field :slug, TitleSlug.Type

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
      :title,
      :publish_state,
      :audio_id,
      :title,
      :slug
    ])
    |> validate_publish_state()
    |> maybe_set_published_at()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  @doc """
  Importer is allowed to set publish date.
  """
  def import_changeset(audio_publication, attrs) do
    audio_publication
    |> cast(attrs, [
      :title,
      :publish_state,
      :published_at
    ])
    |> validate_publish_state()
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%__MODULE__{audio: audio}) do
    if Ecto.assoc_loaded?(audio) do
      Audio.image_url(audio)
    else
      nil
    end
  end
end
