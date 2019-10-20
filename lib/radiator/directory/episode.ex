defmodule Radiator.Directory.Episode do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Radiator.Directory.Publication

  alias __MODULE__
  alias Radiator.Media
  alias Radiator.Directory.{Episode, Podcast, Audio, TitleSlug}

  alias RadiatorWeb.Router.Helpers, as: Routes
  alias Radiator.Media.AudioFileUpload

  schema "episodes" do
    field :guid, :string
    field :short_id, :string

    field :title, :string
    field :slug, TitleSlug.Type

    field :subtitle, :string
    field :summary, :string
    field :summary_html, :string
    field :summary_source, :string

    field :number, :integer

    field :publish_state, Radiator.Ecto.AtomType, default: :drafted
    field :published_at, :utc_datetime

    # use enclosure form field to upload audio file
    field :enclosure, :map, virtual: true

    field :downloads_total, :integer, virtual: true

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
      :summary,
      :summary_html,
      :summary_source,
      :guid,
      :number,
      :publish_state,
      :published_at,
      :slug,
      :short_id,
      :podcast_id,
      :enclosure
    ])
    |> validate_required([:title])
    |> set_guid_if_missing()
    |> create_audio_from_enclosure()
    |> validate_publish_state()
    |> maybe_set_published_at()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  def public_url(%Episode{} = episode), do: public_url(episode, episode.podcast)

  def public_url(%Episode{slug: ep_slug}, %Podcast{slug: pod_slug, hostname: nil})
      when is_binary(ep_slug) and is_binary(pod_slug) do
    Routes.episode_url(RadiatorWeb.Endpoint, :show, pod_slug, ep_slug)
  end

  def public_url(%Episode{slug: ep_slug}, %Podcast{hostname: hostname})
      when is_binary(ep_slug) do
    hostname
    |> URI.parse()
    |> Map.put(:path, Routes.custom_hostname_episode_path(RadiatorWeb.Endpoint, :show, ep_slug))
    |> URI.to_string()
  end

  def public_url(_, _), do: nil

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
  Convenience accessor for image URL.
  Use `podcast: podcast` to get podcast image if there is no episode audio image
  """
  def image_url(episode, opts \\ [])

  def image_url(nil, opts) do
    with podcast = %Podcast{} <- opts[:podcast] do
      Podcast.image_url(podcast)
    else
      _ -> nil
    end
  end

  def image_url(%Episode{audio: audio}, opts) do
    if not is_nil(audio) and Ecto.assoc_loaded?(audio) do
      Audio.image_url(audio, opts)
    else
      image_url(nil, opts)
    end
  end

  def generate_short_id(short_id_base, number) when is_integer(number) do
    generate_short_id(short_id_base, to_string(number))
  end

  def generate_short_id(short_id_base, number) when is_binary(number) do
    "#{short_id_base}#{String.pad_leading(number, 3, "0")}"
  end

  def generate_short_id(short_id_base, _) do
    generate_short_id("#{short_id_base}_t", :rand.uniform(1000))
  end

  def regenerate_guid(changeset) do
    put_change(changeset, :guid, UUID.uuid4())
  end

  defp set_guid_if_missing(changeset) do
    maybe_regenerate_guid(changeset, get_field(changeset, :guid))
  end

  @doc """
  Create Audio for Episode from enclosure upload.

  FIXME: creates new audio even if there was one before, leaving audio orphans on multiple uploads
  TODO: actually inserting db data in a changeset feels icky (side effects), not sure there's a way around it
  """
  def create_audio_from_enclosure(changeset) do
    if get_field(changeset, :enclosure) do
      episode = changeset.data
      audio = %Audio{} |> change(%{episodes: [episode]}) |> Radiator.Repo.insert!()
      {:ok, _audio} = AudioFileUpload.upload(get_field(changeset, :enclosure), audio)
      changeset
    else
      changeset
    end
  end

  defp maybe_regenerate_guid(changeset, nil), do: regenerate_guid(changeset)
  defp maybe_regenerate_guid(changeset, _), do: changeset
end
