defmodule Radiator.Podcasts.Podcast.Calculations do
  @moduledoc false

  use Spark.Dsl.Fragment, of: Ash.Resource

  calculations do
    calculate :display_title, :string, expr(if is_nil(title), do: feed_url, else: title)
  end
end
