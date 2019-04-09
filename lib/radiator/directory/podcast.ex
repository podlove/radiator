defmodule Radiator.Directory.Podcast do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Directory.{Episode, Podcast}

  schema "podcasts" do
    field :author, :string
    field :description, :string
    field :image, :string
    field :language, :string
    field :last_built_at, :utc_datetime
    field :owner_email, :string
    field :owner_name, :string
    field :published_at, :utc_datetime
    field :subtitle, :string
    field :title, :string

    field :episode_count, :integer, virtual: true

    has_many(:episodes, Episode)

    has_many(:podcast_permissions, Radiator.Directory.PodcastPermission)

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [
      :title,
      :subtitle,
      :description,
      :image,
      :author,
      :owner_name,
      :owner_email,
      :language,
      :published_at,
      :last_built_at
    ])
    |> validate_required([:title])
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
end
