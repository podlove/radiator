defmodule Radiator.Outline.Event.NodeContentChangedEvent do
  @moduledoc false

  defstruct [:uuid, :node_id, :content, :user_id]
end
