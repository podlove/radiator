defmodule Radiator.Podcasts.Episode.Chapter do
  @moduledoc """
  A chapter mark of an episode.

  A value object: chapters carry no identity in the feed, are only ever read
  together with their episode, and are replaced wholesale on every sync. Hence
  embedded rather than a table of their own.
  """

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :start_ms, :integer, allow_nil?: false, public?: true
    attribute :title, :string, public?: true
    attribute :href, :string, public?: true
    attribute :image_url, :string, public?: true
  end
end
