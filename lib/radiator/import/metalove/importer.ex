defmodule Radiator.Import.Metalove.Importer do
  @moduledoc """
  Imports podcast data from RSS/Atom feeds using the Metalove library.

  This module handles the complete import process:
  1. Fetches podcast metadata via Metalove
  2. Creates the Show record
  3. Fetches all episodes from the feed
  4. Creates Episode records
  5. Fetches and creates Chapter records for each episode

  All imports are performed within a database transaction to ensure
  data consistency. If any step fails, the entire import is rolled back.

  ## Usage

      iex> Radiator.Import.Metalove.Importer.import_podcast("https://freakshow.fm/feed/mp3")
      {:ok, %Radiator.Podcasts.Show{...}}

      # With options
      iex> Radiator.Import.Metalove.Importer.import_podcast(
      ...>   "https://example.com/feed.xml",
      ...>   replace: true,
      ...>   strict: false
      ...> )
      {:ok, %Radiator.Podcasts.Show{...}}
  """

  require Ash.Query
  require Logger

  alias Radiator.Import.Tools
  alias Radiator.Podcasts.{Show, Episode, Chapter}
  alias Radiator.Repo

  @doc """
  Imports a complete podcast from an RSS/Atom feed URL.

  ## Options

    * `:replace` - If true, replaces existing podcast data; if false, returns error (default: false)
    * `:strict` - If true, fails on any data quality issues; if false, applies fixes where possible (default: true)

  ## Strict Mode

  When `:strict` is `true` (default), the import will fail if:
  - A chapter is missing a title
  - A chapter has an invalid start time
  - A chapter has a duplicate start time (same episode, same timestamp)
  - An episode has a duplicate GUID
  - An episode has a duplicate episode number

  When `:strict` is `false`, the import will:
  - Generate fallback titles for chapters missing titles (e.g., "Chapter at 5:30")
  - Skip chapters with invalid start times and continue importing
  - Skip chapters with duplicate start times and continue importing
  - Generate new UUIDs for episodes with duplicate GUIDs and continue importing
  - Skip episodes with duplicate episode numbers and continue importing

  ## Returns

    * `{:ok, show}` - Successfully imported show with all episodes and chapters
    * `{:error, :already_exists}` - Podcast already exists (use `replace: true` to update)
    * `{:error, reason}` - Import failed, all changes rolled back

  ## Examples

      # Public podcast (strict mode, default)
      Radiator.Import.Metalove.Importer.import_podcast("https://freakshow.fm/feed/mp3")

      # Lenient mode - apply fixes for data quality issues
      Radiator.Import.Metalove.Importer.import_podcast(
        "https://example.com/feed.xml",
        strict: false
      )

      # Re-import and replace existing data
      Radiator.Import.Metalove.Importer.import_podcast(
        "https://example.com/feed.xml",
        replace: true
      )
  """
  def import_podcast(feed_url, opts \\ []) do
    Logger.info("Starting Metalove import from: #{feed_url}")

    # Wrap entire import in a transaction with extended timeout
    # Large podcasts can take a while to import
    Repo.transaction(
      fn ->
        with {:ok, podcast_data} <- fetch_podcast_data(feed_url),
             {:ok, feed_data} <- fetch_feed_data(podcast_data),
             {:ok, show} <- create_show(feed_data, opts),
             {:ok, show} <- import_episodes(feed_data, show, opts) do
          Logger.info("Import completed successfully: #{show.title}")
          show
        else
          {:error, :already_exists} ->
            # Special handling for already exists - don't log as error
            Repo.rollback(:already_exists)

          {:error, reason} ->
            Logger.error("Import failed: #{inspect(reason)}")
            Repo.rollback(reason)
        end
      end,
      timeout: :infinity
    )
  end

  # Private Functions

  defp fetch_podcast_data(feed_url) do
    Logger.debug("Fetching podcast metadata from #{feed_url}")

    try do
      podcast = Metalove.get_podcast(feed_url)
      Logger.info("Found podcast: #{podcast.id}")
      {:ok, podcast}
    rescue
      error ->
        {:error, "Failed to fetch podcast metadata: #{inspect(error)}"}
    end
  end

  defp fetch_feed_data(podcast) do
    Logger.debug("Fetching feed data from #{podcast.main_feed_url}")

    try do
      feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)
      Logger.info("Found feed: #{feed.title} with #{length(feed.episodes)} episodes")
      {:ok, feed}
    rescue
      error ->
        {:error, "Failed to fetch feed data: #{inspect(error)}"}
    end
  end

  defp create_show(feed, opts) do
    Logger.debug("Creating show")

    guid = get_or_generate_guid(feed)

    show_attrs = %{
      title: feed.title,
      subtitle: feed.subtitle,
      summary: Tools.truncate_summary(feed.summary),
      language: feed.language,
      author: feed.author,
      itunes_category: Tools.flatten_categories(feed.categories),
      explicit: feed.explicit || false
    }

    # Remove nil values
    show_attrs = Map.reject(show_attrs, fn {_k, v} -> is_nil(v) end)

    # Try to find existing show by GUID
    case Show
         |> Ash.Query.filter(guid == ^guid)
         |> Ash.read_one() do
      {:ok, nil} ->
        # Create new show
        show_attrs_with_guid = Map.put(show_attrs, :guid, guid)

        case Show
             |> Ash.Changeset.for_create(:import, show_attrs_with_guid)
             |> Ash.create(authorize?: false, return_notifications?: true) do
          {:ok, show, _notifications} ->
            Logger.info("Created show: #{show.title}")
            {:ok, show}

          {:error, error} ->
            {:error, "Failed to create show: #{inspect(error)}"}
        end

      {:ok, existing_show} ->
        # Show already exists
        replace? = Keyword.get(opts, :replace, false)

        if replace? do
          # Delete existing show and all associated data, then create fresh
          Logger.info("Replacing existing show: #{existing_show.title}")

          case existing_show
               |> Ash.Changeset.for_destroy(:destroy)
               |> Ash.destroy(authorize?: false, return_notifications?: true) do
            {:ok, _notifications} ->
              # Now create the show fresh with new data
              show_attrs_with_guid = Map.put(show_attrs, :guid, guid)

              case Show
                   |> Ash.Changeset.for_create(:import, show_attrs_with_guid)
                   |> Ash.create(authorize?: false, return_notifications?: true) do
                {:ok, show, _notifications} ->
                  Logger.info("Created show: #{show.title}")
                  {:ok, show}

                {:error, error} ->
                  {:error, "Failed to create show: #{inspect(error)}"}
              end

            {:error, error} ->
              {:error, "Failed to delete existing show: #{inspect(error)}"}
          end
        else
          # Don't replace - return error
          Logger.warning(
            "Show '#{existing_show.title}' already exists (GUID: #{guid}). " <>
              "Use 'replace: true' option to update existing data."
          )

          {:error, :already_exists}
        end

      {:error, error} ->
        {:error, "Failed to query for existing show: #{inspect(error)}"}
    end
  end

  defp import_episodes(feed, show, opts) do
    Logger.debug("Processing episodes")

    total = length(feed.episodes)
    Logger.info("Found #{total} episodes, starting import")

    feed.episodes
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, show}, fn {episode_ref, index}, {:ok, show} ->
      Logger.debug("Processing episode #{index}/#{total}")

      case import_single_episode(episode_ref, show, opts) do
        {:ok, :skipped} ->
          # Episode was skipped, continue with next episode
          {:cont, {:ok, show}}

        {:ok, _episode} ->
          {:cont, {:ok, show}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp import_single_episode(episode_ref, show, opts) do
    with {:ok, episode_data} <- fetch_episode_data(episode_ref),
         {:ok, episode_or_skipped} <- create_episode(episode_data, show, opts) do
      case episode_or_skipped do
        :skipped ->
          # Episode was skipped due to duplicate in non-strict mode
          {:ok, :skipped}

        episode ->
          Logger.info("Importing episode: #{episode.title}")

          case import_chapters(episode_data, episode, opts) do
            {:ok, _chapters} -> {:ok, episode}
            {:error, reason} -> {:error, reason}
          end
      end
    else
      {:error, reason} ->
        {:error, "Failed to import episode: #{reason}"}
    end
  end

  defp fetch_episode_data(episode_ref) do
    try do
      episode = Metalove.Episode.get_by_episode_id(episode_ref)

      if episode do
        {:ok, episode}
      else
        {:error, "Episode not found"}
      end
    rescue
      error ->
        {:error, "Failed to fetch episode details: #{inspect(error)}"}
    end
  end

  defp create_episode(episode_data, show, opts) do
    strict? = Keyword.get(opts, :strict, true)

    guid = episode_data.guid || generate_episode_guid(episode_data, show)

    episode_attrs = %{
      guid: guid,
      title: episode_data.title,
      subtitle: episode_data.subtitle,
      summary: Tools.truncate_summary(episode_data.summary),
      number: Tools.parse_episode_number(episode_data.episode),
      itunes_type: Tools.convert_episode_type(episode_data.type),
      publication_date: parse_publication_date(episode_data.pub_date),
      duration_ms: Tools.parse_duration(episode_data.duration),
      show_id: show.id
    }

    # Remove nil values
    episode_attrs = Map.reject(episode_attrs, fn {_k, v} -> is_nil(v) end)

    Logger.debug("Creating episode with GUID: #{guid}")

    # With eager_check? true, Ash.create returns {:error, error} for duplicates
    # instead of throwing an exception, keeping the transaction healthy
    case Episode
         |> Ash.Changeset.for_create(:import, episode_attrs)
         |> Ash.create(authorize?: false, return_notifications?: true) do
      {:ok, episode, _notifications} ->
        Logger.debug("Created episode #{episode.number}: #{episode.title}")
        {:ok, episode}

      {:error, error} ->
        # Extract errors - could be Ash.Error.Invalid or Ash.Changeset
        errors =
          case error do
            %Ash.Error.Invalid{errors: errs} -> errs
            %Ash.Changeset{errors: errs} -> errs
            _ -> []
          end

        # Check for ALL duplicate errors (could have both GUID and number duplicates)
        duplicate_types =
          Enum.flat_map(errors, fn error ->
            case error do
              # Match InvalidChanges error with fields list
              %Ash.Error.Changes.InvalidChanges{fields: fields, message: msg}
              when msg == "has already been taken" ->
                cond do
                  :guid in fields and (:number in fields and :show_id in fields) ->
                    [:guid, :number]

                  :guid in fields ->
                    [:guid]

                  :number in fields and :show_id in fields ->
                    [:number]

                  true ->
                    []
                end

              # Also check for InvalidAttribute (older error format)
              %Ash.Error.Changes.InvalidAttribute{field: field, message: msg}
              when msg == "has already been taken" ->
                case field do
                  :guid -> [:guid]
                  :number -> [:number]
                  _ -> []
                end

              _ ->
                []
            end
          end)
          |> Enum.uniq()

        # Handle duplicates based on what we found
        cond do
          # Both GUID and number are duplicates - this is the exact same episode
          :guid in duplicate_types and :number in duplicate_types ->
            if strict? do
              Logger.error(
                "Episode is a complete duplicate (GUID and number). " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              {:error, "Duplicate episode (GUID: #{guid}, number: #{episode_attrs[:number]})"}
            else
              Logger.warning(
                "Episode is a complete duplicate (GUID and number), skipping. " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              {:ok, :skipped}
            end

          # Only GUID is duplicate - generate new UUID and retry
          :guid in duplicate_types ->
            if strict? do
              Logger.error(
                "Episode has duplicate GUID: #{guid}. " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              {:error, "Duplicate GUID: #{guid}"}
            else
              # Generate a new UUID and retry
              new_guid = Ash.UUID.generate()

              Logger.warning(
                "Episode has duplicate GUID: #{guid}, generating new UUID: #{new_guid}. " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              episode_attrs_with_new_guid = Map.put(episode_attrs, :guid, new_guid)

              case Episode
                   |> Ash.Changeset.for_create(:import, episode_attrs_with_new_guid)
                   |> Ash.create(authorize?: false, return_notifications?: true) do
                {:ok, episode, _notifications} ->
                  Logger.debug("Created episode #{episode.number}: #{episode.title}")
                  {:ok, episode}

                {:error, retry_error} ->
                  {:error, "Failed to create episode with new GUID: #{inspect(retry_error)}"}
              end
            end

          # Only number is duplicate - skip the episode
          :number in duplicate_types ->
            if strict? do
              Logger.error(
                "Episode has duplicate number: #{episode_attrs[:number]}. " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              {:error, "Duplicate episode number: #{episode_attrs[:number]}"}
            else
              # Skip this episode in non-strict mode
              Logger.warning(
                "Episode has duplicate number: #{episode_attrs[:number]}, skipping episode. " <>
                  "Episode: #{episode_data.title || "unknown"}"
              )

              {:ok, :skipped}
            end

          # No duplicate errors found - some other error
          true ->
            {:error, "Failed to create episode: #{inspect(error)}"}
        end
    end
  end

  defp import_chapters(episode_data, episode, opts) do
    strict? = Keyword.get(opts, :strict, true)

    chapters = episode_data.chapters || []

    case chapters do
      [] ->
        {:ok, []}

      [_ | _] = chapters ->
        # Delete existing chapters for this episode
        case Chapter
             |> Ash.Query.filter(episode_id == ^episode.id)
             |> Ash.read!() do
          existing_chapters ->
            Enum.each(existing_chapters, fn chapter ->
              chapter
              |> Ash.Changeset.for_destroy(:destroy)
              |> Ash.destroy!(authorize?: false, return_notifications?: true)
            end)
        end

        # Create new chapters
        if strict? do
          # Strict mode: fail on any data quality issue
          chapters
          |> Enum.with_index(1)
          |> Enum.reduce_while({:ok, []}, fn {chapter_data, index}, {:ok, acc} ->
            case create_chapter(chapter_data, episode, opts) do
              {:ok, chapter} ->
                {:cont, {:ok, [chapter | acc]}}

              {:error, reason} ->
                {:halt, {:error, "Chapter #{index} failed validation: #{reason}"}}
            end
          end)
          |> case do
            {:ok, created_chapters} ->
              Logger.debug("Created #{length(created_chapters)} chapters for episode")
              {:ok, created_chapters}

            error ->
              error
          end
        else
          # Lenient mode: skip invalid chapters, continue importing
          {created, skipped} =
            chapters
            |> Enum.reduce({0, 0}, fn chapter_data, {created_count, skipped_count} ->
              case create_chapter(chapter_data, episode, opts) do
                {:ok, _chapter} ->
                  {created_count + 1, skipped_count}

                {:error, _reason} ->
                  # Warning already logged in create_chapter
                  {created_count, skipped_count + 1}
              end
            end)

          if skipped > 0 do
            Logger.warning("Created #{created} chapters, skipped #{skipped} invalid chapters")
          else
            Logger.debug("Created #{created} chapters for episode")
          end

          {:ok, []}
        end
    end
  end

  defp create_chapter(chapter_data, episode, opts) do
    strict? = Keyword.get(opts, :strict, true)

    # Parse start time (required field)
    start_time_ms = Tools.parse_chapter_time(Map.get(chapter_data, :start))

    # Safely get title field
    title = Map.get(chapter_data, :title)

    cond do
      is_nil(start_time_ms) ->
        if strict? do
          Logger.error(
            "Chapter has invalid start time: #{inspect(Map.get(chapter_data, :start))}"
          )

          {:error, "Invalid start time"}
        else
          Logger.warning(
            "Chapter has invalid start time: #{inspect(Map.get(chapter_data, :start))}, skipping chapter"
          )

          {:error, "Invalid chapter start time"}
        end

      is_nil(title) or title == "" ->
        if strict? do
          Logger.error("Chapter missing required title")
          {:error, "Missing title"}
        else
          fallback_title = "Chapter at #{Tools.format_time(start_time_ms)}"
          Logger.warning("Chapter missing title, using fallback: #{fallback_title}")
          create_chapter_record(chapter_data, episode, start_time_ms, fallback_title, opts)
        end

      true ->
        create_chapter_record(chapter_data, episode, start_time_ms, title, opts)
    end
  end

  defp create_chapter_record(chapter_data, episode, start_time_ms, title, opts) do
    strict? = Keyword.get(opts, :strict, true)

    chapter_attrs = %{
      start_time_ms: start_time_ms,
      title: title,
      link: Map.get(chapter_data, :href),
      episode_id: episode.id
    }

    # Remove nil values (but keep required fields)
    chapter_attrs = Map.reject(chapter_attrs, fn {_k, v} -> is_nil(v) end)

    case Chapter
         |> Ash.Changeset.for_create(:create, chapter_attrs)
         |> Ash.create(authorize?: false, return_notifications?: true) do
      {:ok, chapter, _notifications} ->
        {:ok, chapter}

      {:error, error} ->
        # Check if this is a duplicate start_time error
        errors =
          case error do
            %Ash.Error.Invalid{errors: errs} -> errs
            %Ash.Changeset{errors: errs} -> errs
            _ -> []
          end

        is_duplicate_start_time =
          Enum.any?(errors, fn error ->
            case error do
              %Ash.Error.Changes.InvalidAttribute{field: :start_time_ms, message: msg}
              when msg == "has already been taken" ->
                true

              _ ->
                false
            end
          end)

        cond do
          is_duplicate_start_time and strict? ->
            Logger.error(
              "Chapter has duplicate start time: #{start_time_ms}ms (#{Tools.format_time(start_time_ms)})"
            )

            {:error, "Duplicate chapter start time"}

          is_duplicate_start_time ->
            Logger.warning(
              "Chapter has duplicate start time: #{start_time_ms}ms (#{Tools.format_time(start_time_ms)}), skipping chapter"
            )

            {:error, :duplicate_start_time}

          true ->
            {:error, inspect(error)}
        end
    end
  end

  # Helper function to get or generate GUID for a feed
  # Priority:
  # 1. Use feed.guid if present
  # 2. Use feed.link as GUID if present (with warning)
  # 3. Generate a new UUID (with warning)
  defp get_or_generate_guid(feed) do
    cond do
      feed.guid && feed.guid != "" ->
        Logger.debug("Using feed GUID: #{feed.guid}")
        feed.guid

      feed.link && feed.link != "" ->
        Logger.warning(
          "Feed '#{feed.title || "unknown"}' has no GUID, using <link> as GUID: #{feed.link}"
        )

        feed.link

      true ->
        guid = "metalove-#{Ash.UUID.generate()}"

        Logger.warning(
          "Feed '#{feed.title || "unknown"}' has no GUID and no <link>, generating random UUID"
        )

        Logger.debug("Generated GUID: #{guid}")
        guid
    end
  end

  # Helper function to generate episode GUID if not provided
  defp generate_episode_guid(episode_data, show) do
    # Use episode enclosure URL or title to generate a unique GUID
    base = episode_data.enclosure.url || episode_data.title || "unknown"
    "#{show.guid}-episode-#{:crypto.hash(:md5, base) |> Base.encode16(case: :lower)}"
  end

  # Helper function to parse publication date
  defp parse_publication_date(nil), do: nil

  defp parse_publication_date(%DateTime{} = datetime), do: datetime

  defp parse_publication_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_publication_date(_), do: nil
end
