defmodule Radiator.Auth.Email do
  use Bamboo.Phoenix, view: RadiatorWeb.EmailView

  alias Radiator.Auth.Config
  alias Radiator.Auth.User

  def welcome_email(%User{} = user, confirmation_url) do
    email_base()
    |> subject(mail_subject("Welcome to Radiator!"))
    |> assign(:username, user.name)
    |> assign(
      :confirmation_url,
      confirmation_url
    )
    |> render("welcome.text")
    |> to(user.email)
  end

  def email_verification_email(%User{} = user, confirmation_url) do
    email_base()
    |> subject(mail_subject("Please verifiy your email address."))
    |> assign(:username, user.name)
    |> assign(
      :confirmation_url,
      confirmation_url
    )
    |> render("email_verification_email.text")
    |> to(user.email)
  end

  def email_reset_password_email(%User{} = user, reset_password_url) do
    email_base()
    |> subject(mail_subject("Password reset."))
    |> assign(:username, user.name)
    |> assign(
      :reset_password_url,
      reset_password_url
    )
    |> render("email_reset_password_email.text")
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
