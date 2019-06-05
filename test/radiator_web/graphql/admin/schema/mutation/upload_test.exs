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

  @upload_audio_file """
  mutation ($audio_id: ID!) {
    uploadAudioFile(audio_id: $audio_id, file: "myfile") {
      mimeType
      byteLength
      title
    }
  }
  """

  test "upload audio file to audio", %{conn: conn, user: user} do
    episode = insert(:episode, audio: build(:audio)) |> owned_by(user)
    audio = episode.audio

    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    conn =
      post conn, "/api/graphql",
        query: @upload_audio_file,
        myfile: upload,
        variables: %{"audio_id" => audio.id}

    assert %{
             "data" => %{
               "uploadAudioFile" => %{
                 "byteLength" => 8476,
                 "mimeType" => "audio/mpeg",
                 "title" => "pling.mp3"
               }
             }
           } = json_response(conn, 200)
  end
end
