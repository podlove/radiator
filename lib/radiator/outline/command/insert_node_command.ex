defmodule Radiator.Outline.Command.InsertNodeCommand do
  @moduledoc """
  Command to insert a node into the outline.
  """
  @type t() :: %__MODULE__{
          event_id: binary(),
          user_id: binary(),
          payload: any()
        }

  defstruct [:event_id, :user_id, :payload]
end
