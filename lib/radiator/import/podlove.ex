defmodule Radiator.Import.Podlove do
  @moduledoc """
  Public API for importing podcasts from WordPress sites running Podlove Publisher.

  This module serves as a facade for `Radiator.Import.Podlove.Importer`.
  See `Radiator.Import.Podlove.Importer` for detailed documentation.

  ## Quick Example

      iex> Radiator.Import.Podlove.import_podcast("https://example.com")
      {:ok, %Radiator.Podcasts.Podcast{...}}

  ## API Documentation

  For more information about the Podlove Publisher API, see:
  https://docs.podlove.org/podlove-publisher/api/
  """

  @doc """
  Imports a complete podcast from a WordPress site running Podlove Publisher.

  See `Radiator.Import.Podlove.Importer.import_podcast/2` for detailed documentation.
  """
  defdelegate import_podcast(base_url, opts \\ []), to: Radiator.Import.Podlove.Importer
end
