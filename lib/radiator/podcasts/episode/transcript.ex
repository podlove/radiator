defmodule Radiator.Podcasts.Episode.Transcript do
  @moduledoc """
  A transcript of an episode. A value object, see
  `Radiator.Podcasts.Episode.Chapter`.
  """

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :url, :string, allow_nil?: false, public?: true
    attribute :type, :string, public?: true
    attribute :language, :string, public?: true
    attribute :rel, :string, public?: true
  end
end
