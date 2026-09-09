defmodule Radiator.Feeds.Feed.Person do
  @moduledoc """
  A person credited on the podcast or on an episode.

  Merged from `podcast:person` (name, image, role) and `atom:contributor`
  (name, URI). In a feed the two elements carry complementary fields.
  """
  defstruct [:name, :role, :image_url, :uri]
end
