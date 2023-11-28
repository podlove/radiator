defmodule RadiatorWeb.AccountsLive.Index do
  use RadiatorWeb, :live_view

  alias Radiator.Accounts

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Accounts")
    |> stream(:users, Accounts.list_users())
    |> reply(:ok)
  end
end
