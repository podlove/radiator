defmodule Radiator.Directory.Episode do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false
  alias Radiator.Directory.Podcast
  alias Radiator.EpisodeMeta.Chapter

  schema "episodes" do
    field :content, :string
    field :description, :string
    field :duration, :string
    field :enclosure_length, :integer
    field :enclosure_type, :string
    field :enclosure_url, :string
    field :guid, :string
    field :image, :string
    field :number, :integer
    field :published_at, :utc_datetime
    field :subtitle, :string
    field :title, :string

    belongs_to :podcast, Podcast
    has_many :chapters, Chapter

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
      :enclosure_url,
      :enclosure_length,
      :enclosure_type,
      :duration,
      :guid,
      :number,
      :published_at,
      :podcast_id
    ])
    |> validate_required([:title])
    |> set_guid_if_missing()
  end

  def regenerate_guid(changeset) do
    put_change(changeset, :guid, UUID.uuid4())
  end

  defp set_guid_if_missing(changeset) do
    maybe_regenerate_guid(changeset, get_field(changeset, :guid))
  end

  defp maybe_regenerate_guid(changeset, nil), do: regenerate_guid(changeset)
  defp maybe_regenerate_guid(changeset, _), do: changeset

  def filter_by_published(query, %{"published" => true}) do
    from(e in query, where: e.published_at <= fragment("NOW()"))
  end

  def filter_by_published(query, %{"published" => false}) do
    from(e in query, where: e.published_at > fragment("NOW()") or is_nil(e.published_at))
  end

  def filter_by_published(query, %{"published" => :any}) do
    query
  end

  def filter_by_published(query, _) do
    filter_by_published(query, %{"published" => true})
  end

  def filter_by_podcast(query, %Podcast{} = podcast) do
    from(e in query, where: e.podcast_id == ^podcast.id)
  end

  def order_by(query, %{"order_by" => order_by, "order" => order}) do
    from(p in query, order_by: ^_order_by_params(order_by, order))
  end

  def order_by(query, %{"order_by" => order_by}) do
    __MODULE__.order_by(query, %{"order_by" => order_by, "order" => :asc})
  end

  def order_by(query, %{"order" => order}) do
    __MODULE__.order_by(query, %{"order_by" => "title", "order" => order})
  end

  def order_by(query, _), do: from(e in query, order_by: [desc: e.published_at])

  defp _order_by_params(order_by, :asc) do
    [asc: order_by]
  end

  defp _order_by_params(order_by, :desc) do
    [desc: order_by]
  end
end
