defmodule Radiator.Feeds.Feed.Chapter do
  @moduledoc "A chapter mark from `psc:chapter`. `start_ms` is in milliseconds."
  defstruct [:start_ms, :title, :href, :image_url]
end
