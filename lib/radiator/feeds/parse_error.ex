defmodule Radiator.Feeds.ParseError do
  @moduledoc "Why a feed could not be read."

  defexception [:reason, :message]

  @type t :: %__MODULE__{reason: :malformed_xml | :not_a_feed, message: String.t()}
end
