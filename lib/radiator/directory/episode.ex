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
    field :short_id, :string

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
      :short_id,
      :podcast_id
    ])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
    |> validate_required([:title])
    |> set_guid_if_missing()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()

    # todo: episode cannot be published without audio
  end

  def construct_short_id(%Episode{} = episode, %Podcast{} = podcast) do
    podcast.short_id <>
      (episode.number
       |> Integer.to_string()
       |> String.pad_leading(3, "0"))
  end

  @doc """
  Get enclosure data for episode.
  """
  @spec enclosure(Episode.t()) :: %{url: binary(), type: binary(), length: integer()}
  def enclosure(%Episode{} = episode) do
    %{
      url: enclosure_url(episode),
      type: enclosure_mime_type(episode),
      length: enclosure_byte_length(episode)
    }
  end

  @doc """
  Convenience accessor for enclosure URL.
  """
  def enclosure_url(%Episode{audio: %Audio{audio_files: [enclosure]}}) do
    Media.AudioFile.url({enclosure.file, enclosure})
  end

  def enclosure_url(%Episode{audio: %Audio{audio_files: []}}) do
    raise ArgumentError, "Audio without attached files"
  end

  def enclosure_url(%Episode{audio: %Audio{audio_files: [_enclosure | _more]}}) do
    raise ArgumentError, "Audio without unexpected number of attached files (> 1)"
  end

  def enclosure_url(%Episode{audio: %Audio{audio_files: _}}) do
    raise ArgumentError, "Audio needs preloaded audio_files"
  end

  @doc """
  Convenience accessor for enclosure MIME type.
  """
  def enclosure_mime_type(%Episode{audio: %Audio{audio_files: [enclosure]}}) do
    enclosure.mime_type
  end

  @doc """
  Convenience accessor for enclosure byte length.
  """
  def enclosure_byte_length(%Episode{audio: %Audio{audio_files: [enclosure]}}) do
    enclosure.byte_length
  end

  @doc """
  Convenience accessor for image URL. Use `fallback: true` to get podcast image if ther is no special episode image
  """
  def image_url(%Episode{} = episode, opts \\ []) do
    case Media.EpisodeImage.url({episode.image, episode}) do
      nil ->
        case opts[:podcast] do
          podcast = %Podcast{} ->
            Podcast.image_url(podcast)

          _ ->
            nil
        end

      url ->
        url
    end
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
