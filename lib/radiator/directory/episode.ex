defmodule Radiator.Directory.Episode do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias __MODULE__
  alias Radiator.Directory.Podcast
  alias Radiator.Media
  alias Radiator.EpisodeMeta.Chapter

  schema "episodes" do
    field :content, :string
    field :description, :string
    field :duration, :string
    field :guid, :string
    field :image, :string
    field :number, :integer
    field :published_at, :utc_datetime
    field :subtitle, :string
    field :title, :string

    belongs_to :podcast, Podcast
    has_many :chapters, Chapter

    has_many :attachments,
             {"episode_attachments", Media.Attachment},
             foreign_key: :subject_id

    many_to_many :audio_files,
                 Media.AudioFile,
                 join_through: "episode_attachments",
                 join_keys: [subject_id: :id, audio_id: :id]

    # RESEARCH needed
    # Repo.preload(episode, :enclosure) works
    # Ecto.assoc(episode, :enclosure) does not work
    has_one :enclosure, through: [:attachments, :audio]

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
      :image,
      :duration,
      :guid,
      :number,
      :published_at,
      :podcast_id
    ])
    |> validate_required([:title])
    |> set_guid_if_missing()
  end

  @doc """
  Convenience accessor for enclosure URL.
  """
  def enclosure_url(%Episode{enclosure: enclosure}) do
    Media.AudioFile.url({enclosure.file, enclosure})
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
