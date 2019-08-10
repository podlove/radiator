defmodule Radiator.Directory.TitleSlug do
  use EctoAutoslugField.Slug, to: :slug
  import Ecto.Changeset

  alias Radiator.Directory
  alias Radiator.Directory.{Episode, Network, Podcast, AudioPublication}

  # for Network Changesets just get the title
  def get_sources(%Ecto.Changeset{data: %Network{}} = changeset, _opts) do
    title = get_field(changeset, :title)

    [title]
  end

  # for Podcast Changesets get the short_id if present, otherwise the title
  def get_sources(%Ecto.Changeset{data: %Podcast{}} = changeset, _opts) do
    [
      case get_field(changeset, :short_id) do
        nil -> get_field(changeset, :title)
        short_id -> short_id
      end
    ]
  end

  # for other Changesets only get the title when a `published_at` is set
  def get_sources(changeset, _opts) do
    case get_change(changeset, :publish_state) do
      :published ->
        title = get_field(changeset, :title)

        [title]

      _ ->
        nil
    end
  end

  def build_slug(sources, changeset) do
    lookup_fn =
      case changeset.data do
        %AudioPublication{} ->
          &Directory.get_audio_publication_by_slug/1

        %Podcast{} ->
          &Directory.get_podcast_by_slug/1

        %Episode{} ->
          {_change_or_data, podcast_id} = Ecto.Changeset.fetch_field(changeset, :podcast_id)

          fn slug ->
            Directory.get_episode_by_slug(podcast_id, slug)
          end

        %Network{} ->
          &Directory.get_network_by_slug/1
      end

    sources
    |> super(changeset)
    |> build_sequential(lookup_fn)
  end

  defp build_sequential(base_slug, lookup_fn, sequence_number \\ 0) do
    potential_slug =
      case sequence_number do
        0 -> base_slug
        _ -> base_slug <> "-#{sequence_number}"
      end

    case lookup_fn.(potential_slug) do
      nil ->
        potential_slug

      _existing ->
        build_sequential(base_slug, lookup_fn, sequence_number + 1)
    end
  end
end
