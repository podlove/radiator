defmodule Radiator.Import.Podlove.Importer do
  @moduledoc """
  Imports podcast data from WordPress sites running Podlove Publisher.

  This module handles the complete import process:
  1. Fetches podcast metadata via the Podlove API
  2. Creates the Podcast record
  3. Fetches all episodes
  4. Creates Episode records
  5. Fetches and creates Chapter records for each episode

  All imports are performed within a database transaction to ensure
  data consistency. If any step fails, the entire import is rolled back.

  ## Usage

      iex> Radiator.Import.Podlove.Importer.import_podcast("https://example.com")
      {:ok, %Radiator.Podcasts.Podcast{...}}

      # With authentication
      iex> Radiator.Import.Podlove.Importer.import_podcast(
      ...>   "https://example.com",
      ...>   auth: {"username", "app_password"}
      ...> )
      {:ok, %Radiator.Podcasts.Podcast{...}}
  """

  require Ash.Query
  require Logger

  alias Radiator.Import.Podlove.ApiClient
  alias Radiator.Import.Tools
  alias Radiator.Podcasts.{Podcast, Episode, Chapter}
  alias Radiator.Repo

  @doc """
  Imports a complete podcast from a Podlove Publisher site.

  ## Options

    * `:auth` - `{username, password}` tuple for Basic Authentication
    * `:timeout` - Request timeout in milliseconds (default: 30000)
    * `:replace` - If true, replaces existing podcast data; if false, returns error (default: false)
    * `:strict` - If true, fails on any data quality issues; if false, applies fixes where possible (default: true)

  ## Strict Mode

  When `:strict` is `true` (default), the import will fail if:
  - A chapter is missing a title
  - A chapter has an invalid start time
  - An episode has a duplicate GUID
  - An episode has a duplicate episode number

  When `:strict` is `false`, the import will:
  - Generate fallback titles for chapters missing titles (e.g., "Chapter at 5:30")
  - Skip chapters with invalid start times and continue importing
  - Generate new UUIDs for episodes with duplicate GUIDs and continue importing
  - Skip episodes with duplicate episode numbers and continue importing

  ## Returns

    * `{:ok, podcast}` - Successfully imported podcast with all episodes and chapters
    * `{:error, :already_exists}` - Podcast already exists (use `replace: true` to update)
    * `{:error, reason}` - Import failed, all changes rolled back

  ## Examples

      # Public podcast (strict mode, default)
      Radiator.Import.Podlove.Importer.import_podcast("https://example.com")

      # Lenient mode - apply fixes for data quality issues
      Radiator.Import.Podlove.Importer.import_podcast(
        "https://example.com",
        strict: false
      )

      # Re-import and replace existing data
      Radiator.Import.Podlove.Importer.import_podcast(
        "https://example.com",
        replace: true
      )

      # Private podcast with authentication
      Radiator.Import.Podlove.Importer.import_podcast(
        "https://example.com",
        auth: {"admin", "xxxx xxxx xxxx xxxx"}
      )
  """
  def import_podcast(base_url, opts \\ []) do
    Logger.info("Starting Podlove import from: #{base_url}")

    # Wrap entire import in a transaction with extended timeout
    # Large podcasts can take a while to import
    Repo.transaction(
      fn ->
        with {:ok, podcast_data} <- fetch_podcast_data(base_url, opts),
             {:ok, podcast} <- create_podcast(podcast_data, opts),
             {:ok, podcast} <- import_episodes(base_url, podcast, opts) do
          Logger.info("Import completed successfully: #{podcast.title}")
          podcast
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

  defp fetch_podcast_data(base_url, opts) do
    Logger.debug("Fetching podcast metadata from #{base_url}")

    case ApiClient.fetch_podcast(base_url, opts) do
      {:ok, podcast} ->
        Logger.info("Found podcast: #{podcast["title"]}")
        {:ok, podcast}

      {:error, reason} ->
        {:error, "Failed to fetch podcast metadata: #{reason}"}
    end
  end

  defp create_podcast(podcast_data, opts) do
    Logger.debug("Creating podcast")

    guid = podcast_data["guid"] || generate_guid_from_url(podcast_data)

    podcast_attrs = %{
      title: Tools.decode_html_entities(podcast_data["title"]),
      subtitle: Tools.decode_html_entities(podcast_data["subtitle"]),
      summary:
        podcast_data["summary"] |> Tools.decode_html_entities() |> Tools.truncate_summary(),
      mnemonic: podcast_data["mnemonic"],
      language: podcast_data["language"],
      author: Tools.decode_html_entities(podcast_data["author_name"]),
      itunes_type: Tools.convert_podcast_type(podcast_data["itunes_type"]),
      itunes_category: Tools.parse_itunes_category(podcast_data["category"]),
      explicit: podcast_data["explicit"] || false,
      funding_url: podcast_data["funding_url"],
      funding_description: Tools.decode_html_entities(podcast_data["funding_label"])
      # TODO: Map these fields when API structure is confirmed:
      # - license_name / license_url (may be in podcast_data["license"])
      # - blocked (probably not in API, defaults to false)
      # - complete (may be in podcast_data["complete"])
    }

    # Remove nil values
    podcast_attrs = Map.reject(podcast_attrs, fn {_k, v} -> is_nil(v) end)

    # Try to find existing podcast by GUID
    case Podcast
         |> Ash.Query.filter(guid == ^guid)
         |> Ash.read_one() do
      {:ok, nil} ->
        # Create new podcast
        podcast_attrs_with_guid = Map.put(podcast_attrs, :guid, guid)

        case Podcast
             |> Ash.Changeset.for_create(:import, podcast_attrs_with_guid)
             |> Ash.create(authorize?: false, return_notifications?: true) do
          {:ok, podcast, _notifications} ->
            Logger.info("Created podcast: #{podcast.title}")
            {:ok, podcast}

          {:error, error} ->
            {:error, "Failed to create podcast: #{inspect(error)}"}
        end

      {:ok, existing_podcast} ->
        # Podcast already exists
        replace? = Keyword.get(opts, :replace, false)

        if replace? do
          # Delete existing podcast and all associated data, then create fresh
          Logger.info("Replacing existing podcast: #{existing_podcast.title}")

          case existing_podcast
               |> Ash.Changeset.for_destroy(:destroy)
               |> Ash.destroy(authorize?: false, return_notifications?: true) do
            {:ok, _notifications} ->
              # Now create the podcast fresh with new data
              podcast_attrs_with_guid = Map.put(podcast_attrs, :guid, guid)

              case Podcast
                   |> Ash.Changeset.for_create(:import, podcast_attrs_with_guid)
                   |> Ash.create(authorize?: false, return_notifications?: true) do
                {:ok, podcast, _notifications} ->
                  Logger.info("Created podcast: #{podcast.title}")
                  {:ok, podcast}

                {:error, error} ->
                  {:error, "Failed to create podcast: #{inspect(error)}"}
              end

            {:error, error} ->
              {:error, "Failed to delete existing podcast: #{inspect(error)}"}
          end
        else
          # Don't replace - return error
          Logger.warning(
            "Podcast '#{existing_podcast.title}' already exists (GUID: #{guid}). " <>
              "Use 'replace: true' option to update existing data."
          )

          {:error, :already_exists}
        end

      {:error, error} ->
        {:error, "Failed to query for existing podcast: #{inspect(error)}"}
    end
  end

  defp import_episodes(base_url, podcast, opts) do
    Logger.debug("Fetching episodes list")

    case ApiClient.fetch_episodes(base_url, opts) do
      {:ok, episodes} ->
        total = length(episodes)
        Logger.info("Found #{total} episodes, starting import")

        episodes
        |> Enum.with_index(1)
        |> Enum.reduce_while({:ok, podcast}, fn {episode_summary, index}, {:ok, podcast} ->
          Logger.debug("Processing episode #{index}/#{total}")

          case import_single_episode(base_url, podcast, episode_summary, opts) do
            {:ok, :skipped} ->
              # Episode was skipped, continue with next episode
              {:cont, {:ok, podcast}}

            {:ok, _episode} ->
              {:cont, {:ok, podcast}}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
        end)

      {:error, reason} ->
        {:error, "Failed to fetch episodes: #{reason}"}
    end
  end

  defp import_single_episode(base_url, podcast, episode_summary, opts) do
    episode_id = episode_summary["id"]

    with {:ok, episode_data} <- fetch_episode_data(base_url, episode_id, opts),
         {:ok, episode_or_skipped} <- create_episode(episode_data, podcast, opts) do
      case episode_or_skipped do
        :skipped ->
          # Episode was skipped due to duplicate in non-strict mode
          {:ok, :skipped}

        episode ->
          Logger.info("Importing episode: #{episode.title}")

          case import_chapters(base_url, episode, episode_id, opts) do
            {:ok, _chapters} -> {:ok, episode}
            {:error, reason} -> {:error, reason}
          end
      end
    else
      {:error, reason} ->
        {:error, "Failed to import episode #{episode_id}: #{reason}"}
    end
  end

  defp fetch_episode_data(base_url, episode_id, opts) do
    case ApiClient.fetch_episode(base_url, episode_id, opts) do
      {:ok, episode} -> {:ok, episode}
      {:error, reason} -> {:error, "Failed to fetch episode details: #{reason}"}
    end
  end

  defp create_episode(episode_data, podcast, opts) do
    strict? = Keyword.get(opts, :strict, true)

    guid = episode_data["guid"] || generate_episode_guid(episode_data, podcast)

    episode_attrs = %{
      guid: guid,
      title: Tools.decode_html_entities(episode_data["title"]),
      subtitle: Tools.decode_html_entities(episode_data["subtitle"]),
      summary:
        episode_data["summary"] |> Tools.decode_html_entities() |> Tools.truncate_summary(),
      number: Tools.parse_episode_number(episode_data["number"]),
      itunes_type: Tools.convert_episode_type(episode_data["type"]),
      publication_date: parse_publication_date(episode_data["publicationDate"]),
      duration_ms: Tools.parse_duration(episode_data["duration"]),
      podcast_id: podcast.id
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
                  :guid in fields and (:number in fields and :podcast_id in fields) ->
                    [:guid, :number]

                  :guid in fields ->
                    [:guid]

                  :number in fields and :podcast_id in fields ->
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
                  "Episode: #{episode_data["title"] || "unknown"}"
              )

              {:error, "Duplicate episode (GUID: #{guid}, number: #{episode_attrs[:number]})"}
            else
              Logger.warning(
                "Episode is a complete duplicate (GUID and number), skipping. " <>
                  "Episode: #{episode_data["title"] || "unknown"}"
              )

              {:ok, :skipped}
            end

          # Only GUID is duplicate - generate new UUID and retry
          :guid in duplicate_types ->
            if strict? do
              Logger.error(
                "Episode has duplicate GUID: #{guid}. " <>
                  "Episode: #{episode_data["title"] || "unknown"}"
              )

              {:error, "Duplicate GUID: #{guid}"}
            else
              # Generate a new UUID and retry
              new_guid = Ash.UUID.generate()

              Logger.warning(
                "Episode has duplicate GUID: #{guid}, generating new UUID: #{new_guid}. " <>
                  "Episode: #{episode_data["title"] || "unknown"}"
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
                  "Episode: #{episode_data["title"] || "unknown"}"
              )

              {:error, "Duplicate episode number: #{episode_attrs[:number]}"}
            else
              # Skip this episode in non-strict mode
              Logger.warning(
                "Episode has duplicate number: #{episode_attrs[:number]}, skipping episode. " <>
                  "Episode: #{episode_data["title"] || "unknown"}"
              )

              {:ok, :skipped}
            end

          # No duplicate errors found - some other error
          true ->
            {:error, "Failed to create episode: #{inspect(error)}"}
        end
    end
  end

  defp import_chapters(base_url, episode, episode_id, opts) do
    strict? = Keyword.get(opts, :strict, true)

    # Note: fetch_chapters returns {:ok, []} for missing chapters, never {:error, _}
    case ApiClient.fetch_chapters(base_url, episode_id, opts) do
      {:ok, []} ->
        {:ok, []}

      {:ok, [_ | _] = chapters} ->
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
    start_time_ms = Tools.parse_chapter_time(chapter_data["start"])

    cond do
      is_nil(start_time_ms) ->
        if strict? do
          Logger.error("Chapter has invalid start time: #{inspect(chapter_data["start"])}")
          {:error, "Invalid start time"}
        else
          Logger.warning(
            "Chapter has invalid start time: #{inspect(chapter_data["start"])}, skipping chapter"
          )

          {:error, "Invalid chapter start time"}
        end

      is_nil(chapter_data["title"]) or chapter_data["title"] == "" ->
        if strict? do
          Logger.error("Chapter missing required title")
          {:error, "Missing title"}
        else
          fallback_title = "Chapter at #{Tools.format_time(start_time_ms)}"
          Logger.warning("Chapter missing title, using fallback: #{fallback_title}")
          create_chapter_record(chapter_data, episode, start_time_ms, fallback_title)
        end

      true ->
        create_chapter_record(chapter_data, episode, start_time_ms, chapter_data["title"])
    end
  end

  defp create_chapter_record(chapter_data, episode, start_time_ms, title) do
    chapter_attrs = %{
      start_time_ms: start_time_ms,
      title: title,
      link: chapter_data["href"],
      episode_id: episode.id
    }

    # Remove nil values (but keep required fields)
    chapter_attrs = Map.reject(chapter_attrs, fn {_k, v} -> is_nil(v) end)

    case Chapter
         |> Ash.Changeset.for_create(:create, chapter_attrs)
         |> Ash.create(authorize?: false, return_notifications?: true) do
      {:ok, chapter, _notifications} -> {:ok, chapter}
      {:error, error} -> {:error, inspect(error)}
    end
  end

  # Helper function to generate GUID from podcast data if not provided
  defp generate_guid_from_url(podcast_data) do
    # Use link or title as fallback for GUID generation
    base = podcast_data["link"] || podcast_data["title"] || "unknown"
    "podlove-#{:crypto.hash(:md5, base) |> Base.encode16(case: :lower)}"
  end

  # Helper function to generate episode GUID if not provided
  defp generate_episode_guid(episode_data, podcast) do
    # Use episode ID and podcast GUID to generate a unique GUID
    episode_id = episode_data["id"] || episode_data["title"]
    "#{podcast.guid}-episode-#{episode_id}"
  end

  # Helper function to parse publication date
  defp parse_publication_date(nil), do: nil

  defp parse_publication_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_publication_date(_), do: nil
end
