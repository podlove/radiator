defmodule Radiator.Directory.Podcast.TitleSlug do
  use EctoAutoslugField.Slug, to: :slug
  import Ecto.Changeset

  alias Radiator.Directory

  require Logger

  def get_sources(changeset, _opts) do
    title = get_field(changeset, :title)

    [title]
  end

  def build_slug(sources, changeset) do
    case get_change(changeset, :published_at) do
      nil ->
        nil

      _published_at ->
        sources
        |> super(changeset)
        |> build_sequential()
    end
  end

  defp build_sequential(base_slug, sequence_number \\ 0) do
    potential_slug =
      case sequence_number do
        0 -> base_slug
        _ -> base_slug <> "-#{sequence_number}"
      end

    case Directory.get_podcast_by_slug(potential_slug) do
      nil ->
        potential_slug

      _podcast ->
        build_sequential(base_slug, sequence_number + 1)
    end
  end
end
