defmodule Radiator.Directory.Episode do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false

  alias __MODULE__
  alias Radiator.Media
  alias Radiator.Directory.{Episode, Podcast, Audio, TitleSlug}

  schema "episodes" do
    field :content, :string
    field :description, :string
    field :guid, :string
    field :image, Media.EpisodeImage.Type
    field :number, :integer
    field :published_at, :utc_datetime
    field :subtitle, :string
    field :title, :string
    field :slug, TitleSlug.Type

    belongs_to :podcast, Podcast
    belongs_to :audio, Audio

    has_many :permissions, {"episodes_perm", Radiator.Perm.Permission}, foreign_key: :subject_id

    timestamps()
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [
      :title,
      :subtitle,
      :description,
      :content,
      :guid,
      :number,
      :published_at,
      :slug,
      :podcast_id
    ])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
    |> validate_required([:title])
    |> set_guid_if_missing()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()

    # todo: episode cannot be published without audio
  end

  @doc """
  Convenience accessor for enclosure URL.
  """
  def enclosure_url(%Episode{audio: %Audio{audio_files: [enclosure]}}) do
    Media.AudioFile.url({enclosure.file, enclosure})
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%Episode{} = episode) do
    Media.EpisodeImage.url({episode.image, episode})
  end

  def regenerate_guid(changeset) do
    put_change(changeset, :guid, UUID.uuid4())
  end

  defp set_guid_if_missing(changeset) do
    maybe_regenerate_guid(changeset, get_field(changeset, :guid))
  end

  defp maybe_regenerate_guid(changeset, nil), do: regenerate_guid(changeset)
  defp maybe_regenerate_guid(changeset, _), do: changeset
end
