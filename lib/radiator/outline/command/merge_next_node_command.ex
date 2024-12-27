defmodule Radiator.Outline.Command.MergeNextNodeCommand do
  @moduledoc """
  Command to merge a node with the next node.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary()
        }

  defstruct [:event_id, :user_id, :node_id]
end
