defmodule Radiator.Feeds.Response do
  @moduledoc """
  The response of a feed fetch.

  `final_url` records the URL after all redirects. Today it is only logged;
  once outside users may enter feed URLs, it becomes the basis for validating
  every redirect target.
  """

  defstruct [:status, :body, :etag, :last_modified, :final_url]

  @type t :: %__MODULE__{
          status: pos_integer() | nil,
          body: binary() | nil,
          etag: String.t() | nil,
          last_modified: String.t() | nil,
          final_url: String.t() | nil
        }
end
