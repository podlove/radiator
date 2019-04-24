defmodule RadiatorWeb.Plug.ValidateAPIUser do
  @moduledoc """
  Put `:authenticated_user` into the `:context` map for GraphQL absinth if a valid bearer token is present.
  """
  @behaviour Plug

  import Plug.Conn

  alias Radiator.Auth

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _) do
    conn
    |> Absinthe.Plug.put_options(context: build_context(conn))
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Auth.Guardian.decode_and_verify(token),
         {:ok, valid_user} <- Auth.Guardian.resource_from_claims(claims) do
      %{authenticated_user: valid_user}
    else
      _ -> %{}
    end
  end
end
