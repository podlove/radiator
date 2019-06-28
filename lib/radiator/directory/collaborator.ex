defmodule Radiator.Directory.Collaborator do
  alias Radiator.Auth
  alias Radiator.Directory.{Network, Podcast, Episode, Audio}

  use Radiator.Constants, :permissions

  @type t :: %__MODULE__{
          user: Auth.User.t(),
          subject: Network.t() | Podcast.t() | Episode.t() | Audio.t(),
          permission: permission()
        }
  defstruct [:user, :subject, :permission]
end
