defmodule Radiator.Outline.Command.MoveNodeToContainerCommand do
  @moduledoc false
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          container_id: binary(),
          node_id: binary(),
          parent_id: binary() | nil,
          prev_id: binary() | nil
        }

  defstruct [:event_id, :user_id, :node_id, :container_id, :parent_id, :prev_id]
end
