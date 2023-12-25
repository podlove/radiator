defmodule RadiatorWeb.Api.OutlineController do
  use RadiatorWeb, :controller

  alias Radiator.Accounts
  alias Radiator.Outline

  def create(conn, %{"content" => content, "token" => token}) do
    {status_code, body} =
      token
      |> decode_token()
      |> get_user_by_token()
      # show will be send in request from frontend (show_id)
      # fetch wanted/current episode for show

      |> create_node(content)
      |> get_response()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status_code, Jason.encode!(body))
  end

  def create(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{error: "missing params"}))
  end

  defp decode_token(token), do: Base.url_decode64(token, padding: false)

  defp get_user_by_token({:ok, token}), do: Accounts.get_user_by_api_token(token)
  defp get_user_by_token(:error), do: {:error, :token}

  defp create_node(nil, _), do: {:error, :user}
  defp create_node(user, content), do: Outline.create_node(%{"content" => content}, user)

  defp get_response({:ok, node}), do: {200, %{uuid: node.uuid}}
  defp get_response({:error, _}), do: {400, %{error: "params"}}
end
