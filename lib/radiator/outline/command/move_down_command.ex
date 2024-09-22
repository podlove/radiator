defmodule Radiator.Outline.Command.MoveDownCommand do
  @moduledoc """
  Command to move a node down inside one level of the outline.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary()
        }

  defstruct [:event_id, :user_id, :node_id]
end
