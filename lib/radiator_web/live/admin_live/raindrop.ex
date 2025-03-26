defmodule RadiatorWeb.AdminLive.Raindrop do
  @moduledoc """

  """
  alias Radiator.Accounts.RaindropClient
  def user_has_raindrop?(user_id) do
    RaindropClient.access_enabled?(user_id)
  end

  def collections_for_user(user_id) do
    user_id
      |> RaindropClient.get_collections()
      |> Enum.map(fn item -> {item["title"], item["_id"]} end)
  end

  def redirect_url(user_id) do
    "https://raindrop.io/oauth/authorize?client_id=#{RaindropClient.config()[:client_id]}&redirect_uri=#{RaindropClient.redirect_uri_encoded(user_id)}"
  end
end
