defmodule RadiatorWeb.EpisodeControllerTest.Schema.Mutation.PodcastsTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @create_query """
  mutation ($podcast: PodcastInput!) {
    createPodcast(podcast: $podcast) {
      id
      title
    }
  }
  """

  test "createPodcast creates a podcast", %{conn: conn} do
    podcast = params_for(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"podcast" => podcast}

    title = podcast[:title]

    assert %{
             "data" => %{
               "createPodcast" => %{
                 "title" => ^title,
                 "id" => id
               }
             }
           } = json_response(conn, 200)

    refute is_nil(id)
  end

  test "createPodcast returns errors when missing data", %{conn: conn} do
    conn =
      post conn, "/api/graphql",
        query: @create_query,
        variables: %{"podcast" => %{}}

    assert %{
             "errors" => [
               %{"message" => msg}
             ]
           } = json_response(conn, 200)

    assert msg =~ ~r/Argument "podcast" has invalid value \$podcast/
  end

  @update_query """
  mutation ($id: ID!, $podcast: PodcastInput!) {
    updatePodcast(id: $id, podcast: $podcast) {
      id
      title
    }
  }
  """

  test "updatePodcast updates a podcast", %{conn: conn} do
    podcast = insert(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"podcast" => %{title: "Aldebaran"}, "id" => podcast.id}

    id = Integer.to_string(podcast.id)

    assert %{
             "data" => %{
               "updatePodcast" => %{
                 "title" => "Aldebaran",
                 "id" => ^id
               }
             }
           } = json_response(conn, 200)
  end

  test "updatePodcast returns errors on missing values", %{conn: conn} do
    podcast = insert(:podcast)

    conn =
      post conn, "/api/graphql",
        query: @update_query,
        variables: %{"podcast" => %{title: ""}, "id" => podcast.id}

    # TODO we need a way to manage changeset errors
    # id = Integer.to_string(podcast.id)

    # assert %{
    #          "data" => %{
    #            "updatePodcast" => %{
    #              "title" => "Aldebaran",
    #              "id" => ^id
    #            }
    #          }
    #        } = json_response(conn, 200)
  end
end
