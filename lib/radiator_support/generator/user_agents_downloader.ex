defmodule RadiatorSupport.UserAgentsDownloader do
  @moduledoc """
  Downloads file with 10.000 user agents for RadiatorSupport.TrackingGenerator
  because keeping a 1MB file with noncritical data versioned here feels wrong.
  """

  @user_agents_remote "https://gist.githubusercontent.com/eteubert/1dd9692d4dfa2548fbfb550782daa95e/raw/988af488af6994a309756927ac3a380c66e4badf/user_agents.csv"
  @user_agents_file "lib/radiator_support/generator/data/user_agents.txt"

  def download do
    user_agents =
      HTTPoison.get!(@user_agents_remote)
      |> case do
        %HTTPoison.Response{status_code: 200, body: body} ->
          body

        response ->
          raise "unexpected response when downloading user_agents.txt: #{inspect(response)}"
      end
      # fix escaping mistake in file
      |> String.replace("\\;", ";")

    File.write!(@user_agents_file, user_agents)
  end
end
