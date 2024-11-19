defmodule Radiator.Outline.Command.SplitNodeCommand do
  @moduledoc """
  Command to split a node in two parts.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          node_id: binary(),
          selection: tuple()
        }

  defstruct [:event_id, :user_id, :node_id, :selection]
end
