defmodule Radiator.Feeds.Feed.Category do
  @moduledoc "An `itunes:category`, optionally with a subcategory."
  defstruct [:text, :subcategory]
end
