# Script for importing Metaebene podcasts from Podlove Publisher sites
#
# This script imports multiple podcasts from the Metaebene network.
# Each podcast is imported with replace: true to update existing data.
#
# Usage:
#   mix run priv/repo/seeds/import_metaebene.exs
#
# Note: This script must be run with `mix run` to load the application.

require Logger

# Ensure the application is loaded
unless Code.ensure_loaded?(Radiator.Import.Podlove) do
  IO.puts("""
  Error: Radiator application not loaded.
  Please run this script with: mix run priv/repo/seeds/import_metaebene.exs
  """)

  System.halt(1)
end

alias Radiator.Import.Podlove

# List of Metaebene podcast sites to import
sites = [
  "https://forschergeist.de/",
  "https://cre.fm/",
  "https://logbuch-netzpolitik.de/",
  "https://ukw.fm/",
  "https://freakshow.fm/",
  "https://raumzeit-podcast.de/"
]

Logger.info("Starting import of #{length(sites)} Metaebene podcasts")

results =
  Enum.map(sites, fn url ->
    Logger.info("Importing: #{url}")

    case Podlove.import_podcast(url, replace: true) do
      {:ok, show} ->
        Logger.info("Successfully imported: #{show.title}")
        {:ok, url, show}

      {:error, reason} ->
        Logger.error("Failed to import #{url}: #{inspect(reason)}")
        {:error, url, reason}
    end
  end)

# Summary
successful = Enum.count(results, fn {status, _, _} -> status == :ok end)
failed = Enum.count(results, fn {status, _, _} -> status == :error end)

Logger.info("Import complete: #{successful} successful, #{failed} failed")

if failed > 0 do
  Logger.warning("Failed imports:")

  results
  |> Enum.filter(fn {status, _, _} -> status == :error end)
  |> Enum.each(fn {:error, url, reason} ->
    Logger.warning("  - #{url}: #{inspect(reason)}")
  end)
end
