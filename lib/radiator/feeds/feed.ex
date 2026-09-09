defmodule Radiator.Feeds.Feed do
  @moduledoc """
  The result of parsing: the channel level plus items, in document order.

  This module and everything under `Radiator.Feeds` speaks the vocabulary of
  RSS and nothing else. Translation into Radiator's own terms happens in the
  translator inside `Radiator.Podcasts`.
  """

  alias Radiator.Feeds.Feed.Channel

  defstruct channel: %Channel{}, items: []
end
