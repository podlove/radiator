defmodule RadiatorWeb.GraphQL.Admin.Schema.Query.EpisodesTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  alias Radiator.Directory.Episode

  @doc """
  Generate user and add auth token to connection.
  """
  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_authenticated_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  @single_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      title
      enclosure {
        length
        type
        url
      }
    }
  }
  """

  test "episode returns an episode", %{conn: conn, user: user} do
    podcast = insert(:podcast) |> owned_by(user)
    episode = insert(:unpublished_episode, podcast: podcast)
    enclosure = Episode.enclosure(episode)

    conn = get conn, "/api/graphql", query: @single_query, variables: %{"id" => episode.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "episode" => %{
                 "id" => Integer.to_string(episode.id),
                 "title" => episode.title,
                 "enclosure" => %{
                   "length" => enclosure.length,
                   "type" => enclosure.type,
                   "url" => enclosure.url
                 }
               }
             }
           }
  end

  @is_published_query """
  query ($id: ID!) {
    episode(id: $id) {
      id
      isPublished
    }
  }
  """

  describe "is_published" do
    test "is false for an unpublished episode", %{conn: conn, user: user} do
      episode = insert(:episode) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end

    test "is true for a published episode", %{conn: conn, user: user} do
      episode = insert(:episode, published_at: DateTime.utc_now()) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => true}
               }
             }
    end

    test "is false for published_at dates in the future", %{conn: conn, user: user} do
      in_one_hour = DateTime.utc_now() |> DateTime.add(3600)
      episode = insert(:episode, published_at: in_one_hour) |> owned_by(user)

      conn =
        get conn, "/api/graphql", query: @is_published_query, variables: %{"id" => episode.id}

      assert json_response(conn, 200) == %{
               "data" => %{
                 "episode" => %{"id" => Integer.to_string(episode.id), "isPublished" => false}
               }
             }
    end
  end
end
