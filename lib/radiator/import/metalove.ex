defmodule Radiator.Import.Metalove do
  @moduledoc """
  Public API for importing podcasts from RSS/Atom feeds using Metalove.

  This module serves as a facade for `Radiator.Import.Metalove.Importer`.
  See `Radiator.Import.Metalove.Importer` for detailed documentation.

  ## Quick Example

      iex> Radiator.Import.Metalove.import_podcast("https://freakshow.fm/feed/mp3")
      {:ok, %Radiator.Podcasts.Podcast{...}}

  ## About Metalove

  Metalove is a podcast feed parser that supports RSS 2.0, Atom, and various
  podcast-specific extensions like iTunes, Podlove Simple Chapters, and more.

  For more information, see: https://github.com/podlove/metalove
  """

  @doc """
  Imports a complete podcast from an RSS/Atom feed URL.

  See `Radiator.Import.Metalove.Importer.import_podcast/2` for detailed documentation.
  """
  defdelegate import_podcast(feed_url, opts \\ []), to: Radiator.Import.Metalove.Importer
end
