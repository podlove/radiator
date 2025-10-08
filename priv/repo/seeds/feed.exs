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

  alias Radiator.Import.Tools

  @doc """
  Creates a Show from Metalove PodcastFeed data.
  """
  def create_show_from_feed(feed) do
    show_attrs = %{
      guid: feed.guid,
      title: feed.title,
      subtitle: feed.subtitle,
      summary: Tools.truncate_summary(feed.summary),
      language: feed.language,
      author: feed.author,
      itunes_category: Tools.flatten_categories(feed.categories),
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
      summary: Tools.truncate_summary(episode.summary),
      number: Tools.parse_episode_number(episode.episode),
      itunes_type: Tools.convert_episode_type(episode.type),
      publication_date: episode.pub_date,
      duration_ms: Tools.parse_duration(episode.duration),
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
        start_time_ms: Tools.parse_chapter_time(chapter.start),
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
