defmodule RadiatorWeb.AdminLive.Raindrop do
  @moduledoc """
    Raindrop.io integration for Radiator in Liveview.
  """
  alias Radiator.Accounts
  alias Radiator.Accounts.RaindropClient
  alias Radiator.Outline.Command
  alias Radiator.Outline.CommandQueue

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

  def save_raindrop(user_id, show, %{"raindrop_collection" => collection_id}) do
    # send command to create node for raindrop in inbox container of show
    Command.build(
      "insert_node",
      %{
        "title" => "raindrop",
        "content" => "raindrop",
        "container_id" => show.inbox_node_container_id,
        "parent_id" => nil
      },
      nil,
      Ecto.UUID.generate()
    )
    |> CommandQueue.enqueue()

    Accounts.Raindrop.connect_show_with_raindrop(user_id, show.id, collection_id)
  end

  def save_raindrop(_user_id, _show_id, _params), do: nil
end
