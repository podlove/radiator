defmodule Radiator.Feeds do
  @moduledoc """
  Fetching and parsing RSS podcast feeds.

  This context is a generic subdomain: it speaks the vocabulary of RSS and
  nothing else, and knows neither podcast nor episode, neither Ash nor
  database. Translation into Radiator's own terms happens in the translator
  inside `Radiator.Podcasts`.
  """

  alias Radiator.Feeds.Client.ReqClient
  alias Radiator.Feeds.Parser

  @doc """
  Fetches a feed and reads it.

  Options: `:etag` and `:last_modified` for the conditional request. For an
  unchanged feed it returns `{:not_modified, response}` without parsing.
  """
  def load(url, opts \\ []) do
    with {:ok, response} <- ReqClient.fetch(url, opts),
         {:ok, feed} <- Parser.parse(response.body) do
      {:ok, feed, response}
    end
  end
end
