defmodule Radiator.RaindropClient do
  @moduledoc """
    Client for Raindrop API
  """
  alias Radiator.Accounts

  def config, do: Application.fetch_env!(:radiator, :raindrop)

  def redirect_uri_encoded(user_id) do
    user_id
    |> redirect_uri()
    |> URI.encode()
  end

  def redirect_uri(user_id) do
    config()[:redirect_url]
    |> URI.parse()
    |> URI.append_query("user_id=#{user_id}")
    |> URI.to_string()
  end

  def redirect_uri do
    config()[:redirect_url]
    |> URI.parse()
    |> URI.to_string()
  end

  def access_enabled?(user_id) do
    not_enabled =
      user_id
      |> Accounts.get_user!()
      |> Map.get(:raindrop_access_token)
      |> is_nil()

    !not_enabled
  end

  # Authorization: Bearer ae261404-11r4-47c0-bce3-e18a423da828
  def get_collections(user_id) do
    user = Accounts.get_user!(user_id)

    {:ok, response} =
      [
        method: :get,
        url: "https://api.raindrop.io/rest/v1/collections",
        headers: [
          {"Authorization", "Bearer #{user.raindrop_access_token}"}
        ]
      ]
      |> Req.request()

    response.body
    |> Map.get("items")
    |> Enum.map(&Map.take(&1, ["_id", "title"]))
  end
end
