defmodule Radiator.Auth.Email do
  use Bamboo.Phoenix, view: RadiatorWeb.EmailView

  alias Radiator.Auth.Config
  alias Radiator.Auth.User

  def welcome_email(%User{} = user) do
    email_base()
    |> subject(mail_subject("Welcome to Radiator-Spark!"))
    |> assign(:username, user.name)
    |> assign(
      :confirmation_url,
      "https://radiator-spark.local/user/verify?tkn=123123145asdfoaijnewpoinav-asdf"
    )
    |> render("welcome.text")
    |> to(user.email)
  end

  def email_base do
    new_email()
    |> from({Config.email_from_name(), Config.email_from_email()})
    |> put_text_layout({RadiatorWeb.LayoutView, "email.text"})
  end

  defp mail_subject(subject) do
    "[Radiator] #{subject}"
  end
end
