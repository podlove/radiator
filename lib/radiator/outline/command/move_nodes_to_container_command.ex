defmodule Radiator.Outline.Command.MoveNodesToContainerCommand do
  @moduledoc """
  Command to move multiple nodes to a different container.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          container_id: binary(),
          node_ids: list(binary())
        }

  defstruct [:event_id, :user_id, :container_id, :node_ids]
end
