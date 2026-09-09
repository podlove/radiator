defmodule Radiator.Feeds.Parser do
  @moduledoc """
  Turns the XML of a podcast feed into `Radiator.Feeds.Feed`.

  `Saxy.parse_string/4` is enough for the document sizes involved here; a 5 MB
  feed fits in memory whole. Should that grow, `Saxy.parse_stream/4` is the way
  out — the handler works with either.
  """

  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.ParseError
  alias Radiator.Feeds.Parser.Handler

  @doc """
  Reads a feed.

  Returns `{:error, %ParseError{reason: :not_a_feed}}` when the document is
  well-formed but holds no channel — the usual case when a server answers with
  an HTML error page under status 200 instead of the feed.
  """
  def parse(xml) when is_binary(xml) do
    case Saxy.parse_string(xml, Handler, Handler.initial_state()) do
      {:ok, state} -> validate(Handler.to_feed(state))
      {:error, exception} -> {:error, malformed(exception)}
    end
  end

  defp validate(%Feed{channel: %{title: nil}, items: []}) do
    {:error,
     %ParseError{
       reason: :not_a_feed,
       message: "The document contains neither a channel title nor any episodes."
     }}
  end

  defp validate(%Feed{} = feed), do: {:ok, feed}

  defp malformed(exception) do
    %ParseError{reason: :malformed_xml, message: Exception.message(exception)}
  end
end
