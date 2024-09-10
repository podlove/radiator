defmodule Radiator.Outline.Command.DeleteNodeCommand do
  @moduledoc """
  Command to remove a node from the outline and delete it permantly.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary()
        }

  defstruct [:event_id, :user_id, :node_id]
end
