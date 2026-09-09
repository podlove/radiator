defmodule Radiator.Feeds do
  @moduledoc """
  Fetching and parsing RSS podcast feeds.

  This context is a generic subdomain: it speaks the vocabulary of RSS and
  nothing else, and knows neither podcast nor episode, neither Ash nor
  database. Translation into Radiator's own terms happens in the translator
  inside `Radiator.Podcasts`.
  """

  alias Radiator.Feeds.Client
  alias Radiator.Feeds.Parser

  @doc "Fetches a feed through the configured client."
  def fetch(url, opts \\ []), do: Client.impl().fetch(url, opts)

  @doc "Reads a feed document."
  defdelegate parse(xml), to: Parser

  @doc """
  Fetches a feed and reads it.

  For an unchanged feed it returns `{:not_modified, response}` without
  parsing.
  """
  def load(url, opts \\ []) do
    case fetch(url, opts) do
      {:ok, response} -> parse_response(response)
      {:not_modified, response} -> {:not_modified, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_response(response) do
    case parse(response.body || "") do
      {:ok, feed} -> {:ok, feed, response}
      {:error, error} -> {:error, error}
    end
  end
end
