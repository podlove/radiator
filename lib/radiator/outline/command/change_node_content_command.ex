defmodule Radiator.Outline.Command.ChangeNodeContentCommand do
  @moduledoc """
  Command to move a nodeinside the outline to another place.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary(),
          content: String.t() | nil
        }

  defstruct [:event_id, :user_id, :node_id, :content]
end
