defmodule Plug.MemorizeHead do
  @moduledoc """
  A Plug to add private key `is_head: true|false` depending on request type.

  Reason: `Plug.Head` changes HEAD to GET requests.

  ## Examples

      Plug.MemorizeHead.call(conn, [])
  """

  @behaviour Plug

  alias Plug.Conn

  def init([]), do: []

  def call(%Conn{method: "HEAD"} = conn, []), do: Conn.put_private(conn, :is_head, true)
  def call(conn, []), do: Conn.put_private(conn, :is_head, false)
end
