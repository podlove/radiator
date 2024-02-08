defmodule Extension.Phoenix.Socket do
  @moduledoc """
  Instead of {:ok, socket} or {:noreply, socket}
  you can now write socket |> reply(:ok)
  e.g.
  socket
  |> assign(a: "1")
  |> assign(b: "2")
  |> reply(:ok)
  """

  def reply(socket, reply) when is_atom(reply), do: {reply, socket}
  def reply(socket, reply, data) when is_atom(reply) and is_map(data), do: {reply, data, socket}
end
