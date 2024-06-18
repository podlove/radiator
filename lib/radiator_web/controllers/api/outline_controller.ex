defmodule RadiatorWeb.Api.OutlineController do
  use RadiatorWeb, :controller

  alias Radiator.{Accounts, Outline, Podcast}

  def create(conn, %{"content" => content, "show_id" => show_id, "token" => token}) do
    episode = Podcast.get_current_episode_for_show(show_id)

    {status_code, body} =
      token
      |> decode_token()
      |> get_user_by_token()
      |> create_node(content, episode.id)
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

  defp create_node(nil, _, _), do: {:error, :user}
  defp create_node(_, _, nil), do: {:error, :episode}

  defp create_node(user, content, episode_id) do
    Outline.insert_node(%{
      "content" => content,
      "creator_id" => user.id,
      "episode_id" => episode_id
    })
  end

  defp get_response({:ok, %{node: node}}), do: {200, %{uuid: node.uuid}}
  defp get_response({:error, _}), do: {400, %{error: "params"}}
end
