defmodule Radiator.Directory.Podcast do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false
  import Radiator.Directory.Publication

  alias Radiator.Directory.{Episode, Podcast, Network, TitleSlug}
  alias Radiator.Media.PodcastImage
  alias Radiator.Contribution

  alias RadiatorWeb.Router.Helpers, as: Routes

  schema "podcasts" do
    field :short_id, :string
    field :title, :string
    field :subtitle, :string
    field :summary, :string

    field :author, :string
    field :image, PodcastImage.Type

    field :language, :string
    field :last_built_at, :utc_datetime
    field :owner_email, :string
    field :owner_name, :string

    field :use_short_id?, :boolean, source: :is_using_short_id, default: true
    field :main_color, :string, default: "#1a202d"

    field :slug, TitleSlug.Type

    field :episode_count, :integer, virtual: true

    field :hostname, :string

    belongs_to :network, Network
    has_many :episodes, Episode

    has_many :contributions, Contribution.PodcastContribution
    has_many :contributors, through: [:contributions, :person]

    has_many :permissions, {"podcasts_perm", Radiator.Perm.Permission}, foreign_key: :subject_id

    field :publish_state, Radiator.Ecto.AtomType, default: :drafted
    field :published_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [
      :short_id,
      :title,
      :subtitle,
      :summary,
      :author,
      :owner_name,
      :owner_email,
      :language,
      :last_built_at,
      :slug,
      :main_color,
      :use_short_id?,
      :hostname
    ])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
    |> validate_required([:title])
    |> validate_color(:main_color)
    |> postprocess_short_id()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  def publication_changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [
      :publish_state,
      :published_at
    ])
    |> validate_publish_state()
    |> maybe_set_published_at()
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  @doc """
  Use on podcast queries to fill :episode_count attribute.

  NOTE: Is this the right approach? The initial idea to preload like this is to
  avoid n+1 issues in podcast lists. However this is not a "real" preload as it
  does make some assumptions on the general query, for example it already uses the
  :select key.

  ## Example

      iex> from(p in Podcast) |> Podcast.preload_episode_counts() |> Repo.all()

  """
  def preload_episode_counts(query) do
    from(p in query,
      left_join: e in assoc(p, :episodes),
      group_by: p.id,
      select: %Podcast{p | episode_count: count(e.id)}
    )
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%Podcast{} = podcast) do
    PodcastImage.url({podcast.image, podcast})
  end

  def public_url(%Podcast{slug: pod_slug, hostname: nil}) when is_binary(pod_slug) do
    Routes.episode_url(RadiatorWeb.Endpoint, :index, pod_slug)
  end

  def public_url(%Podcast{hostname: hostname}) do
    hostname
    |> URI.parse()
    |> Map.put(:path, Routes.custom_hostname_episode_path(RadiatorWeb.Endpoint, :index))
    |> URI.to_string()
  end

  def public_url(%Podcast{}), do: nil

  # TODO: more than one feed per podcast
  def feed_url(%Podcast{slug: pod_slug, hostname: nil}) when is_binary(pod_slug) do
    Routes.feed_url(RadiatorWeb.Endpoint, :show, pod_slug)
  end

  def feed_url(%Podcast{hostname: hostname}) do
    hostname
    |> URI.parse()
    |> Map.put(:path, Routes.custom_hostname_feed_path(RadiatorWeb.Endpoint, :show))
    |> URI.to_string()
  end

  def feed_url(%Podcast{}), do: nil

  defp validate_color(changeset, field) do
    changeset
    |> update_change(field, fn value ->
      String.downcase(value)
    end)
    |> validate_change(field, fn field, color ->
      with "#" <> hex_color when byte_size(hex_color) == 6 <- color do
        String.to_charlist(hex_color)
        |> Enum.all?(fn
          char
          when char >= ?a and char <= ?f
          when char >= ?0 and char <= ?9 ->
            true

          _ ->
            false
        end)
        |> case do
          true -> []
          _ -> [{field, "Color must only consist of hex numbers"}]
        end

        []
      else
        _ ->
          [{field, "Color must be of shape #0ab71a."}]
      end
    end)
  end

  defp postprocess_short_id(changeset) do
    case fetch_change(changeset, :short_id) do
      {:ok, short_id} ->
        change(changeset, %{slug: String.downcase(short_id)})

      _ ->
        changeset
    end
  end
end
