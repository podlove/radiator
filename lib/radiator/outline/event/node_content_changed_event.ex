defmodule Radiator.Outline.Event.NodeContentChangedEvent do
  @moduledoc false

  defstruct [:event_id, :node_id, :content, :user_id, :container_id]
end
