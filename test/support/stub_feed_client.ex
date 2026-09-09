defmodule Radiator.StubFeedClient do
  @moduledoc """
  A `Radiator.Feeds.Client` for tests.

  The canned response and the recorded calls live in the process dictionary so
  that `async: true` keeps working.
  """

  @behaviour Radiator.Feeds.Client

  @response_key {__MODULE__, :response}
  @calls_key {__MODULE__, :calls}

  @doc "Sets the response the next fetch will return."
  def put(response), do: Process.put(@response_key, response)

  @doc "The calls recorded so far, as `{url, opts}` in order."
  def calls, do: Enum.reverse(Process.get(@calls_key, []))

  @doc "Clears the response and the recording."
  def reset do
    Process.delete(@response_key)
    Process.delete(@calls_key)
    :ok
  end

  @impl Radiator.Feeds.Client
  def fetch(url, opts \\ []) do
    Process.put(@calls_key, [{url, opts} | Process.get(@calls_key, [])])
    Process.get(@response_key) || {:error, :no_stub_response}
  end
end
