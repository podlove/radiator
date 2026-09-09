defmodule Radiator.Podcasts.Podcast.Changes.ApplyFeed do
  @moduledoc """
  Writes a translated feed onto the podcast and its episodes.

  No network, no XML. Shared by `:apply_feed`, which takes a parsed feed, and
  `:sync`, where `FetchFeed` fills the same arguments from `before_transaction`.
  The work runs in `before_action` because that is after `FetchFeed` has run.

  One timestamp for the entire run: `last_seen_in_feed_at` on every episode
  and `last_imported_at` on the podcast hold the same value, because "missing
  from the feed" is defined as the former being older than the latter.
  """

  use Ash.Resource.Change

  require Ash.Query
  require Logger

  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.FeedSync.Translator
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.Podcast.Changes.RecordSyncError

  @domain Radiator.Podcasts

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &apply_feed/1)
  end

  defp apply_feed(changeset) do
    now = DateTime.utc_now()

    error = Ash.Changeset.get_argument(changeset, :error)
    feed = Ash.Changeset.get_argument(changeset, :feed)

    case {error, feed} do
      {nil, nil} -> mark_checked(changeset, now)
      {nil, feed} -> import_feed(changeset, feed, now)
      {error, _feed} -> RecordSyncError.record(changeset, error, now)
    end
  end

  defp mark_checked(changeset, now) do
    changeset
    |> Ash.Changeset.force_change_attribute(:last_checked_at, now)
    |> Ash.Changeset.force_change_attribute(:sync_status, :succeeded)
    |> Ash.Changeset.force_change_attribute(:last_sync_error, nil)
  end

  defp import_feed(changeset, feed, now) do
    podcast = changeset.data
    translation = Translator.translate(feed)

    episodes = upsert_episodes(podcast, translation.episodes, now)
    persons = upsert_persons(podcast, translation.persons)
    relink_contributors(episodes, persons, translation.contributions)
    warn_about_skipped(podcast, translation.skipped)

    changeset
    |> force_change_attributes(translation.podcast)
    |> Ash.Changeset.force_change_attribute(:last_checked_at, now)
    |> Ash.Changeset.force_change_attribute(:last_imported_at, now)
    |> Ash.Changeset.force_change_attribute(:sync_status, :succeeded)
    |> Ash.Changeset.force_change_attribute(:last_sync_error, nil)
  end

  # Dropped items are invisible otherwise: the import reports success while
  # the episode simply is not there.
  defp warn_about_skipped(_podcast, 0), do: :ok

  defp warn_about_skipped(podcast, count) do
    Logger.warning(
      "Feed sync for podcast #{podcast.id} skipped #{count} item(s) " <>
        "without a usable identity or with one already taken."
    )
  end

  defp force_change_attributes(changeset, attributes) do
    Enum.reduce(attributes, changeset, fn {field, value}, acc ->
      Ash.Changeset.force_change_attribute(acc, field, value)
    end)
  end

  defp upsert_episodes(_podcast, [], _now), do: %{}

  defp upsert_episodes(podcast, episodes, now) do
    episodes
    |> Enum.map(&Map.merge(&1, %{podcast_id: podcast.id, last_seen_in_feed_at: now}))
    |> Ash.bulk_create!(Episode, :upsert_from_feed,
      return_records?: true,
      domain: @domain,
      authorize?: false
    )
    |> Map.fetch!(:records)
    |> Map.new(&{&1.guid, &1.id})
  end

  defp upsert_persons(_podcast, []), do: %{}

  defp upsert_persons(podcast, persons) do
    stored = stored_persons(podcast.user_id, Enum.map(persons, & &1.normalized_name))

    persons
    |> Enum.map(&keep_stored_details(&1, stored))
    # `normalized_name` is derived by the resource, not accepted as input.
    |> Enum.map(
      &(&1
        |> Map.take([:name, :uri, :image_url])
        |> Map.put(:user_id, podcast.user_id))
    )
    |> Ash.bulk_create!(Person, :upsert_from_feed,
      return_records?: true,
      domain: @domain,
      authorize?: false
    )
    |> Map.fetch!(:records)
    |> Map.new(&{&1.normalized_name, &1.id})
  end

  defp stored_persons(_user_id, []), do: %{}

  defp stored_persons(user_id, names) do
    Person
    |> Ash.Query.filter(user_id == ^user_id and normalized_name in ^names)
    |> Ash.read!(domain: @domain, authorize?: false)
    |> Map.new(&{&1.normalized_name, &1})
  end

  # A person is shared across the owner's podcasts and a single feed only knows
  # part of them. The feed wins where it has a value; its nils must not erase
  # what another feed contributed.
  defp keep_stored_details(person, stored) do
    case Map.fetch(stored, person.normalized_name) do
      :error ->
        person

      {:ok, existing} ->
        %{
          person
          | uri: person.uri || existing.uri,
            image_url: person.image_url || existing.image_url
        }
    end
  end

  # Only the links of the episodes this run wrote are replaced. Episodes that
  # vanished from the feed keep theirs.
  defp relink_contributors(episodes, persons, contributions) when map_size(episodes) > 0 do
    EpisodeContributor
    |> Ash.Query.filter(episode_id in ^Map.values(episodes))
    |> Ash.bulk_destroy!(:destroy, %{}, domain: @domain, authorize?: false, strategy: :atomic)

    links =
      contributions
      |> Enum.map(fn contribution ->
        %{
          episode_id: Map.get(episodes, contribution.guid),
          person_id: Map.get(persons, contribution.normalized_name),
          role: contribution.role
        }
      end)
      |> Enum.reject(&(is_nil(&1.episode_id) or is_nil(&1.person_id)))

    if links != [] do
      Ash.bulk_create!(links, EpisodeContributor, :create, domain: @domain, authorize?: false)
    end

    :ok
  end

  defp relink_contributors(_episodes, _persons, _contributions), do: :ok
end
