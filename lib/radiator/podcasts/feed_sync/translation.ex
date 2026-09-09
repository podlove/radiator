defmodule Radiator.Podcasts.FeedSync.Translation do
  @moduledoc """
  The output of `Radiator.Podcasts.FeedSync.Translator`.

  Everything in here already speaks Radiator's vocabulary. Episodes and
  persons are still linked by their natural keys — episodes by `guid`, persons
  by `normalized_name` — because neither has a database id yet at this point.
  `Radiator.Podcasts.Podcast.Changes.ApplyFeed` resolves them after upserting.

  `skipped` counts the items that produced no episode at all — those without
  any usable identity, and the later occurrences of an identity already taken.
  """

  defstruct podcast: %{}, episodes: [], persons: [], contributions: [], skipped: 0
end
