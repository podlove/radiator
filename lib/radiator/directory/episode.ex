defmodule Radiator.Directory.Episode do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query, warn: false
  alias Radiator.Directory.Podcast

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

  def filter_by_podcast(query, %Podcast{} = podcast) do
    from(e in query, where: e.podcast_id == ^podcast.id)
  end

  def order_by(query, _) do
    from(e in query, order_by: [desc: e.published_at])
  end
end
