defmodule Radiator.Accounts.RaindropClient do
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

  @doc """
  Check if the user has access to Raindrop API
  """
  def access_enabled?(user_id) do
    not_enabled =
      user_id
      |> Accounts.get_raindrop_tokens()
      |> is_nil()

    !not_enabled
  end

  @doc """
  Get all collections for a user
  """
  def get_collections(user_id) do
    service =
      user_id
      |> Accounts.get_raindrop_tokens()

    if is_nil(service) do
      {:error, :unauthorized}
    else
      [
        method: :get,
        url: "https://api.raindrop.io/rest/v1/collections",
        headers: [
          {"Authorization", "Bearer #{service.data.access_token}"}
        ]
      ]
      |> Req.request()
      |> parse_collection_response()
    end
  end

  defp parse_collection_response({:ok, %Req.Response{status: 401}}) do
    {:error, :unauthorized}
  end

  defp parse_collection_response({:ok, %Req.Response{body: body}}) do
    body
    |> Map.get("items")
    |> Enum.map(&Map.take(&1, ["_id", "title"]))
  end
end
