defmodule Radiator.Feeds.Response do
  @moduledoc """
  The response of a feed fetch: the body plus the two validators for the
  next conditional request.
  """

  defstruct [:body, :etag, :last_modified]

  @type t :: %__MODULE__{
          body: binary(),
          etag: String.t() | nil,
          last_modified: String.t() | nil
        }
end
