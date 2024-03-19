defmodule Radiator.Outline.DispatchTest do
  use Radiator.DataCase

  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures

  # alias Radiator.Outline
  alias Radiator.Outline.Dispatch
  alias Radiator.Outline.Node

  describe "outline dispatch" do
    setup do
      %{episode: episode_fixture()}
    end

    test "insert_node does WHAT?", %{episode: episode} do
      user = user_fixture()

      node = %Node{episode_id: episode.id, content: "something very special 1!1"}
      attributes = Map.from_struct(node)

      event_id = Ecto.UUID.generate()

      Dispatch.insert_node(attributes, user.id, event_id)

      # _inserted_node =
      #  Outline.list_nodes()
      # |> Enum.find(&(&1.content == "something very special 1!1"))

      # assert inserted_node.episode_id == node.episode_id
      # assert inserted_node.content == node.content
    end
  end
end
