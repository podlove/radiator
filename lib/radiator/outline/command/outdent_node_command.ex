defmodule Radiator.Outline.Command.OutdentNodeCommand do
  @moduledoc """
  Command to indent a node.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary()
        }

  defstruct [:event_id, :user_id, :node_id]
end
