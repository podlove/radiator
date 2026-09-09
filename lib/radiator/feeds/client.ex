defmodule Radiator.Feeds.Client do
  @moduledoc """
  The port through which `Radiator.Feeds` fetches feeds.

  Modelled as a behaviour so that tests can produce 304 responses, timeouts and
  truncated bodies deterministically, without speaking HTTP.
  """

  alias Radiator.Feeds.Response

  @doc """
  Fetches a feed.

  Options: `:etag` and `:last_modified` for the conditional request,
  `:max_bytes` as an upper bound on the body, `:receive_timeout` in
  milliseconds.
  """
  @callback fetch(url :: String.t(), opts :: keyword()) ::
              {:ok, Response.t()} | {:not_modified, Response.t()} | {:error, term()}

  @doc "The configured implementation."
  def impl, do: Application.get_env(:radiator, :feed_client, Radiator.Feeds.Client.ReqClient)
end
