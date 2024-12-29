defmodule Radiator.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Radiator.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Radiator.OutlineFixtures

  alias Ecto.Adapters.SQL.Sandbox
  alias Radiator.PodcastFixtures

  using do
    quote do
      alias Radiator.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Radiator.DataCase
    end
  end

  setup tags do
    Radiator.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Radiator.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def simple_node_fixture(_) do
    episode = PodcastFixtures.episode_fixture()

    attrs = %{
      episode_id: episode.id,
      show_id: episode.show_id,
      outline_node_container_id: episode.outline_node_container_id
    }

    [node_1, node_2] = ["node_1", "node_2"] |> node_tree_fixture(attrs)

    %{
      node_1: node_1,
      node_2: node_2
    }
  end

  def simple_node_fixture_hierachical(_) do
    episode = PodcastFixtures.episode_fixture()

    attrs = %{
      episode_id: episode.id,
      show_id: episode.show_id,
      outline_node_container_id: episode.outline_node_container_id
    }

    nodes =
      [
        "node-1",
        {"node-2", ["node-2_1"]}
      ]
      |> node_tree_fixture(attrs)

    assert [
             %{uuid: uuid_1, content: "node-1", parent_id: nil, prev_id: nil},
             %{uuid: uuid_2, content: "node-2", parent_id: nil, prev_id: uuid_1},
             %{uuid: _uuid_2_1, content: "node-2_1", parent_id: uuid_2, prev_id: nil}
           ] = nodes

    node_1 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: nil,
        prev_id: nil,
        content: "node_1"
      )

    node_2 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: node_1.uuid,
        prev_id: nil,
        content: "node_2"
      )

    %{
      node_1: node_1,
      node_2: node_2
    }
  end

  def complex_node_fixture(_) do
    episode = PodcastFixtures.episode_fixture()

    parent_node =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: nil,
        prev_id: nil,
        content: "root of all evil"
      )

    node_1 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: nil,
        content: "node_1"
      )

    node_2 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: node_1.uuid,
        content: "node_2"
      )

    node_3 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: node_2.uuid,
        content: "node_3"
      )

    node_4 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: node_3.uuid,
        content: "node_4"
      )

    node_5 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: node_4.uuid,
        content: "node_5"
      )

    node_6 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: parent_node.uuid,
        prev_id: node_5.uuid,
        content: "node_6"
      )

    nested_node_1 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: node_3.uuid,
        prev_id: nil,
        content: "nested_node_1"
      )

    nested_node_2 =
      node_fixture(
        episode_id: episode.id,
        show_id: episode.show_id,
        outline_node_container_id: episode.outline_node_container_id,
        parent_id: node_3.uuid,
        prev_id: nested_node_1.uuid,
        content: "nested_node_2"
      )

    assert node_5.prev_id == node_4.uuid
    assert node_4.prev_id == node_3.uuid
    assert node_3.prev_id == node_2.uuid
    assert node_2.prev_id == node_1.uuid
    assert node_1.prev_id == nil

    assert nested_node_1.parent_id == node_3.uuid
    assert nested_node_2.parent_id == node_3.uuid
    assert nested_node_1.prev_id == nil
    assert nested_node_2.prev_id == nested_node_1.uuid

    %{
      episode: episode,
      node_1: node_1,
      node_2: node_2,
      node_3: node_3,
      node_4: node_4,
      node_5: node_5,
      node_6: node_6,
      nested_node_1: nested_node_1,
      nested_node_2: nested_node_2,
      parent_node: parent_node
    }
  end
end
