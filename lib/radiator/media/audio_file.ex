defmodule Radiator.Media.AudioFile do
  use Ecto.Schema

  use Arc.Definition
  use Arc.Ecto.Definition

  import Ecto.Changeset
  import Arc.Ecto.Changeset

  alias Radiator.Media
  alias Radiator.Media.AudioFile

  alias Radiator.Directory.{
    Episode,
    AudioPublication,
    Audio,
    Publication
  }

  schema "audio_files" do
    field :file, Media.AudioFile.Type
    field :title, :string
    field :mime_type, :string
    field :byte_length, :integer
    field :duration, :integer
    field :audio_format, :string

    belongs_to(:audio, Audio)

    timestamps()
  end

  @doc false
  def changeset(audio_file = %__MODULE__{}, attrs) do
    audio_file
    |> cast(attrs, [:title, :mime_type, :byte_length, :audio_id, :duration, :audio_format])
    |> cast_attachments(attrs, [:file], allow_paths: true, allow_urls: false)

    # todo: determine byte length and mime type on file change, don't take them as attrs
  end

  @doc false
  def metadata_update_changeset(audio_file = %__MODULE__{}, attrs) do
    audio_file
    |> cast(attrs, [:title])
  end

  @doc """
  Public URL

  Prefer public_url/2 whenever possible. However there are cases where
  an audio file is viewed without context, then a "healthy guess" is made
  which episode or audio publication the file is accessed with.
  """
  def public_url(audio_file = %AudioFile{}) do
    audio_file
    |> Radiator.Repo.preload(audio: [audio_publication: :network, episodes: :podcast])
    |> case do
      %AudioFile{audio: %Audio{episodes: [episode | _]}} ->
        public_url(audio_file, episode)

      %AudioFile{audio: %Audio{audio_publication: audio_publication}} ->
        public_url(audio_file, audio_publication)
    end
  end

  # tracking URL can only be generated once publications is published
  # (before publication the slug may be missing)
  def public_url(audio_file = %AudioFile{}, episode = %Episode{}) do
    if Publication.published?(episode) do
      tracking_url(audio_file, episode)
    else
      ""
    end
  end

  # tracking URL can only be generated once publications is published
  # (before publication the slug may be missing)
  def public_url(audio_file = %AudioFile{}, audio_publication = %AudioPublication{}) do
    if Publication.published?(audio_publication) do
      tracking_url(audio_file, audio_publication)
    else
      ""
    end
  end

  def tracking_url(audio_file = %AudioFile{}, episode = %Episode{}) do
    RadiatorWeb.Router.Helpers.tracking_url(
      RadiatorWeb.Endpoint,
      :track_episode_file,
      episode.podcast.slug,
      episode.slug,
      audio_file.id
    )
  end

  def tracking_url(
        audio_file = %__MODULE__{},
        audio_publication = %AudioPublication{network: network}
      ) do
    RadiatorWeb.Router.Helpers.tracking_url(
      RadiatorWeb.Endpoint,
      :track_audio_publication_file,
      network.slug,
      audio_publication.slug,
      audio_file.id
    )
  end

  def internal_url(audio_file = %__MODULE__{}) do
    __MODULE__.url({audio_file.file, audio_file})
  end

  # arc override
  def storage_dir(_version, {_file, audio_file}) do
    "audio/#{audio_file.audio_id}"
  end

  # arc override
  def s3_object_headers(_version, {file, _user}) do
    [content_type: MIME.from_path(file.file_name)]
  end
end
