# Script for importing podcasts from RSS/Atom feeds using Metalove
#
# This script imports podcasts from RSS/Atom feed URLs.
# It can import a single feed or multiple feeds.
#
# Usage:
#   mix run priv/repo/seeds/import_feed.exs <feed_url> [options]
#   mix run priv/repo/seeds/import_feed.exs --replace <feed_url>
#   mix run priv/repo/seeds/import_feed.exs --lenient <feed_url>
#
# Options:
#   --replace  Replace existing podcast data if it already exists
#   --lenient  Use lenient mode (skip invalid data instead of failing)
#
# Examples:
#   mix run priv/repo/seeds/import_feed.exs "https://freakshow.fm/feed/mp3"
#   mix run priv/repo/seeds/import_feed.exs --replace "https://freakshow.fm/feed/mp3"
#   mix run priv/repo/seeds/import_feed.exs --lenient "https://example.com/feed.xml"
#
# Note: This script must be run with `mix run` to load the application.

require Logger

# Ensure the application is loaded
unless Code.ensure_loaded?(Radiator.Import.Metalove) do
  IO.puts("""
  Error: Radiator application not loaded.
  Please run this script with: mix run priv/repo/seeds/import_feed.exs <feed_url>
  """)

  System.halt(1)
end

alias Radiator.Import.Metalove

# Parse command line arguments
{opts, args, _invalid} =
  OptionParser.parse(System.argv(), switches: [replace: :boolean, lenient: :boolean])

replace? = Keyword.get(opts, :replace, false)
strict? = not Keyword.get(opts, :lenient, false)

case args do
  [feed_url] ->
    Logger.info("Importing podcast from: #{feed_url}")

    if replace? do
      Logger.info("Replace mode enabled - will update existing podcast if found")
    end

    if not strict? do
      Logger.info("Lenient mode enabled - will skip invalid data instead of failing")
    end

    import_opts = [replace: replace?, strict: strict?]

    case Metalove.import_podcast(feed_url, import_opts) do
      {:ok, show} ->
        Logger.info("Successfully imported: #{show.title}")
        Logger.info("Show ID: #{show.id}")
        Logger.info("GUID: #{show.guid}")

      {:error, :already_exists} ->
        Logger.error("""
        Podcast already exists. Use --replace option to update existing data:
          mix run priv/repo/seeds/import_feed.exs --replace "#{feed_url}"
        """)

        System.halt(1)

      {:error, reason} ->
        Logger.error("Failed to import podcast: #{inspect(reason)}")
        System.halt(1)
    end

  [] ->
    IO.puts("""
    Error: Feed URL is required

    Usage:
      mix run priv/repo/seeds/import_feed.exs <feed_url> [options]

    Options:
      --replace  Replace existing podcast data if it already exists
      --lenient  Use lenient mode (skip invalid data instead of failing)

    Examples:
      mix run priv/repo/seeds/import_feed.exs "https://freakshow.fm/feed/mp3"
      mix run priv/repo/seeds/import_feed.exs --replace "https://freakshow.fm/feed/mp3"
      mix run priv/repo/seeds/import_feed.exs --lenient "https://example.com/feed.xml"
    """)

    System.halt(1)

  _multiple ->
    IO.puts("""
    Error: Only one feed URL can be imported at a time

    Usage:
      mix run priv/repo/seeds/import_feed.exs <feed_url> [options]

    To import multiple feeds, run the script multiple times or create a custom script.
    """)

    System.halt(1)
end
