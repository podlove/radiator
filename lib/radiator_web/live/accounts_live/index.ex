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

  @impl true
  def handle_event("refresh_token", %{"id" => id}, socket) do
    id
    |> Accounts.get_user!()
    |> Accounts.refresh_user_api_token()

    socket
    |> stream(:users, Accounts.list_users())
    |> reply(:noreply)
  end

  def handle_event("delete_token", %{"id" => id}, socket) do
    id
    |> Accounts.get_user!()
    |> Accounts.get_api_token_by_user()
    |> Accounts.delete_user_api_token()

    socket
    |> stream(:users, Accounts.list_users())
    |> reply(:noreply)
  end

  defp has_api_token(user) do
    case Accounts.get_api_token_by_user(user) do
      nil -> false
      _ -> true
    end
  end
end
