defmodule RadiatorWeb.EpisodeControllerTest.Schema.Mutation.UploadTest do
  use RadiatorWeb.ConnCase, async: true

  import Radiator.Factory

  @query """
  mutation ($filename: String!) {
    createUpload(filename: $filename) {
      uploadUrl
    }
  }
  """

  test "createUploads returns a URL", %{conn: conn} do
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

  test "upload audio file to episode", %{conn: conn} do
    episode = insert(:episode)

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
end
