defmodule RadiatorWeb.GraphQL.Schema.Mutation.UploadTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

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

  @query """
  mutation ($filename: String!) {
    createUpload(filename: $filename) {
      uploadUrl
    }
  }
  """

  test "createUploads returns a URL", %{conn: conn, user: _user} do
    conn =
      post conn, "/api/graphql",
        query: @query,
        variables: %{"filename" => "foobar"}

    assert %{"data" => %{"createUpload" => %{"uploadUrl" => url}}} = json_response(conn, 200)

    refute is_nil(url)
  end

  @upload_episode_audio """
  mutation ($episode_id: ID!) {
    uploadEpisodeAudio(episode_id: $episode_id, audio: "myaudio") {
      mimeType
      byteLength
      title
    }
  }
  """

  test "upload audio file to episode", %{conn: conn, user: user} do
    episode = insert(:episode) |> owned_by(user)

    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    conn =
      post conn, "/api/graphql",
        query: @upload_episode_audio,
        myaudio: upload,
        variables: %{"episode_id" => episode.id}

    assert %{
             "data" => %{
               "uploadEpisodeAudio" => %{
                 "byteLength" => 8476,
                 "mimeType" => "audio/mpeg",
                 "title" => "pling.mp3"
               }
             }
           } = json_response(conn, 200)
  end

  @upload_network_audio """
  mutation ($network_id: ID!) {
    uploadNetworkAudio(network_id: $network_id, audio: "myaudio") {
      mimeType
      byteLength
      title
    }
  }
  """

  test "upload audio file to network", %{conn: conn, user: user} do
    network = insert(:network) |> owned_by(user)

    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    conn =
      post conn, "/api/graphql",
        query: @upload_network_audio,
        myaudio: upload,
        variables: %{"network_id" => network.id}

    assert %{
             "data" => %{
               "uploadNetworkAudio" => %{
                 "byteLength" => 8476,
                 "mimeType" => "audio/mpeg",
                 "title" => "pling.mp3"
               }
             }
           } = json_response(conn, 200)
  end
end
