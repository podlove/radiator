defmodule Radiator.Podcasts.Podcast.Category do
  @moduledoc """
  An iTunes category of the podcast, optionally with a subcategory.
  A value object, see `Radiator.Podcasts.Episode.Chapter`.
  """

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :text, :string, allow_nil?: false, public?: true
    attribute :subcategory, :string, public?: true
  end
end
