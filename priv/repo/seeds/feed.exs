# Podcast Feed Import Script
#
# This script fetches podcast data from a podcast URL using Metalove and imports it
# into the Radiator database using Ash resources.
#
# Usage: mix run priv/repo/seeds/feed.exs <podcast_url>
# Example: mix run priv/repo/seeds/feed.exs "https://freakshow.fm/feed/mp3"
# Example: mix run priv/repo/seeds/feed.exs "https://freakshow.fm"

require Ash.Query
require Ash.Changeset

# ============================================================================
# Helper Functions
# ============================================================================

defmodule FeedImporter do
  @moduledoc """
  Helper functions for importing feed data into Ash resources.
  """

  @doc """
  Converts duration string from "HH:MM:SS" format to milliseconds.
  """
  def parse_duration(duration_string) when is_binary(duration_string) do
    seconds = duration_string
    |> String.split(":")
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {time_part, index}, acc ->
      {time_int, _} = Integer.parse(time_part)
      acc + time_int * :math.pow(60, index)
    end)
    |> trunc()

    # Convert seconds to milliseconds
    seconds * 1000
  end

  def parse_duration(_), do: nil

  @doc """
  Converts chapter start time from "HH:MM:SS.mmm" format to milliseconds.
  """
  def parse_chapter_time(time_string) when is_binary(time_string) do
    # Handle both "HH:MM:SS.mmm" and "HH:MM:SS" formats
    parts = String.split(time_string, ".")
    time_part = hd(parts)

    # Convert time to seconds first
    seconds = time_part
    |> String.split(":")
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {time_part, index}, acc ->
      {time_int, _} = Integer.parse(time_part)
      acc + time_int * :math.pow(60, index)
    end)
    |> trunc()

    # Add milliseconds if present
    milliseconds = case parts do
      [_, ms_part] ->
        # Pad or truncate to 3 digits
        ms_padded = String.pad_trailing(ms_part, 3, "0") |> String.slice(0, 3)
        {ms_int, _} = Integer.parse(ms_padded)
        ms_int
      _ -> 0
    end

    # Convert to total milliseconds
    seconds * 1000 + milliseconds
  end

  def parse_chapter_time(_), do: 0

  @doc """
  Converts Metalove episode type to iTunes episode type atom.
  """
  def convert_episode_type("full"), do: :full
  def convert_episode_type("trailer"), do: :trailer
  def convert_episode_type("bonus"), do: :bonus
  def convert_episode_type(_), do: :full

  @doc """
  Flattens iTunes categories from nested arrays to flat array.
  """
  def flatten_categories(categories) when is_list(categories) do
    categories
    |> Enum.flat_map(&flatten_category/1)
    |> Enum.take(3)  # Max 3 categories allowed
  end

  def flatten_categories(_), do: []

  defp flatten_category(category) when is_list(category), do: category
  defp flatten_category(category) when is_binary(category), do: [category]
  defp flatten_category(_), do: []

  @doc """
  Safely converts episode number from string to integer.
  """
  def parse_episode_number(episode_str) when is_binary(episode_str) do
    case Integer.parse(episode_str) do
      {num, _} -> num
      _ -> 1
    end
  end

  def parse_episode_number(num) when is_integer(num), do: num
  def parse_episode_number(_), do: 1

  @doc """
  Creates a Show from Metalove PodcastFeed data.
  """
  def create_show_from_feed(feed) do
    show_attrs = %{
      guid: feed.guid,
      title: feed.title,
      subtitle: feed.subtitle,
      summary: truncate_summary(feed.summary),
      language: feed.language,
      author: feed.author,
      itunes_category: flatten_categories(feed.categories),
      explicit: feed.explicit || false
    }

    case Radiator.Podcasts.Show
         |> Ash.Changeset.for_create(:import, show_attrs)
         |> Ash.create(authorize?: false) do
      {:ok, show} ->
        IO.puts("✓ Created show: #{show.title}")
        show
      {:error, error} ->
        IO.puts("✗ Failed to create show: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Creates an Episode from Metalove Episode data.
  """
  def create_episode_from_metalove(episode, show) do
    episode_attrs = %{
      guid: episode.guid,
      title: episode.title,
      subtitle: episode.subtitle,
      summary: truncate_summary(episode.summary),
      number: parse_episode_number(episode.episode),
      itunes_type: convert_episode_type(episode.type),
      publication_date: episode.pub_date,
      duration_ms: parse_duration(episode.duration),
      show_id: show.id
    }

    case Radiator.Podcasts.Episode
         |> Ash.Changeset.for_create(:import, episode_attrs)
         |> Ash.create(authorize?: false) do
      {:ok, episode} ->
        IO.puts("  ✓ Created episode #{episode.number}: #{episode.title}")
        episode
      {:error, error} ->
        IO.puts("  ✗ Failed to create episode: #{inspect(error)}")
        nil
    end
  end

  @doc """
  Creates chapters for an episode from Metalove chapter data.
  """
  def create_chapters_for_episode(chapters, episode) when is_list(chapters) do
    chapters
    |> Enum.with_index()
    |> Enum.each(fn {chapter, index} ->
      chapter_attrs = %{
        start_time_ms: parse_chapter_time(chapter.start),
        title: chapter.title,
        episode_id: episode.id
      }

      case Radiator.Podcasts.Chapter
           |> Ash.Changeset.for_create(:create, chapter_attrs)
           |> Ash.create(authorize?: false) do
        {:ok, _chapter} ->
          IO.puts("    ✓ Created chapter #{index + 1}: #{chapter.title}")
        {:error, error} ->
          IO.puts("    ✗ Failed to create chapter #{index + 1}: #{inspect(error)}")
      end
    end)
  end

  def create_chapters_for_episode(_, _), do: :ok

  # Truncates summary to 4000 characters to match constraint.
  defp truncate_summary(summary) when is_binary(summary) do
    if String.length(summary) > 4000 do
      String.slice(summary, 0, 3997) <> "..."
    else
      summary
    end
  end

  defp truncate_summary(_), do: nil
end

# ============================================================================
# Main Script
# ============================================================================

# Check if Metalove is available
unless Code.ensure_loaded?(Metalove) do
  IO.puts("❌ Error: Metalove dependency is not available")
  IO.puts("")
  IO.puts("Please add Metalove to your mix.exs dependencies:")
  IO.puts("  {:metalove, github: \"podlove/metalove\", branch: \"deps-update\"}")
  IO.puts("")
  IO.puts("Then run: mix deps.get")
  System.halt(1)
end

# Get URL from command line arguments
case System.argv() do
  [podcast_url] ->
    IO.puts("🎙️  Importing podcast from: #{podcast_url}")

    try do
      # Step 1: Fetch podcast metadata
      IO.puts("\n📡 Fetching podcast metadata...")
      podcast = Metalove.get_podcast(podcast_url)
      IO.puts("✓ Found podcast: #{podcast.id}")

      # Step 2: Fetch feed data
      IO.puts("\n📄 Fetching feed data...")
      feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)
      IO.puts("✓ Found feed: #{feed.title}")
      IO.puts("  Episodes found: #{length(feed.episodes)}")

      # Step 3: Create show
      IO.puts("\n🎪 Creating show...")
      show = FeedImporter.create_show_from_feed(feed)

      if show do
        # Step 4: Create episodes and chapters
        IO.puts("\n📺 Creating episodes...")
        episode_count = length(feed.episodes)
        IO.puts("   Processing #{episode_count} episodes...")

        feed.episodes
        |> Enum.with_index(1)
        |> Enum.each(fn {episode_ref, index} ->
          IO.puts("   [#{index}/#{episode_count}] Processing episode...")

          # Fetch full episode data
          episode = Metalove.Episode.get_by_episode_id(episode_ref)

          if episode do
            # Create episode
            created_episode = FeedImporter.create_episode_from_metalove(episode, show)

            if created_episode && episode.chapters do
              # Create chapters
              FeedImporter.create_chapters_for_episode(episode.chapters, created_episode)
            end
          end
        end)

        IO.puts("\n✅ Import completed successfully!")
        IO.puts("   Show: #{show.title}")
        IO.puts("   Episodes processed: #{episode_count}")
      else
        IO.puts("\n❌ Failed to create show. Aborting import.")
      end

    rescue
      error ->
        IO.puts("\n❌ Import failed with error: #{inspect(error)}")
        System.halt(1)
    end

  [] ->
    IO.puts("❌ Error: Podcast URL is required")
    IO.puts("Usage: mix run priv/repo/seeds/feed.exs <podcast_url>")
    IO.puts("Example: mix run priv/repo/seeds/feed.exs \"https://freakshow.fm/feed/mp3\"")
    IO.puts("Example: mix run priv/repo/seeds/feed.exs \"https://freakshow.fm\"")
    System.halt(1)

  args ->
    IO.puts("❌ Error: Too many arguments provided")
    IO.puts("Provided: #{inspect(args)}")
    IO.puts("Usage: mix run priv/repo/seeds/feed.exs <podcast_url>")
    System.halt(1)
end
