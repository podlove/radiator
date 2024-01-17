defmodule RadiatorWeb.AdminLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Accounts
  alias Radiator.Podcast
  alias RadiatorWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Admin Dashboard")
    |> assign(:page_description, "Tools to create and manage your prodcasts")
    |> assign(:networks, Podcast.list_networks(preload: :shows))
    |> assign(:bookmarklet, get_bookmarklet(Endpoint.url() <> "/api/v1/outline", socket))
    |> reply(:ok)
  end

  defp get_bookmarklet(api_uri, socket) do
    token =
      socket.assigns.current_user
      |> Accounts.generate_user_api_token()
      |> Base.url_encode64(padding: false)

    """
    javascript:(function(){
      s=window.getSelection().toString();
      c=s!=""?s:window.location.href;
      xhr=new XMLHttpRequest();
      xhr.open('POST','#{api_uri}',true);
      xhr.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
      xhr.send('content='+encodeURIComponent(c)+'&token=#{token}');
    })()
    """
    |> String.replace(["\n", "  "], "")
  end
end
