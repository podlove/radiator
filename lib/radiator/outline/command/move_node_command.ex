defmodule Radiator.Outline.Command.MoveNodeCommand do
  @moduledoc """
  Command to move a nodeinside the outline to another place.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary(),
          parent_node_id: binary() | nil,
          prev_node_id: binary() | nil
        }

  defstruct [:event_id, :user_id, :node_id, :parent_node_id, :prev_node_id]
end
