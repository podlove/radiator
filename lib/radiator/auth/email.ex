defmodule Radiator.Auth.Email do
  import Bamboo.Email

  alias Radiator.Auth.Config
  alias Radiator.Auth.User

  def welcome_email(%User{} = user) do
    email_base()
    |> subject(mail_subject("Welcome to Radiator-Spark!"))
    |> text_body("""
    Hi there, #{user.name}!

    Welcome to Radiator spark.

    To activate your account and confirm your email address, simply
    click on the link below or paste it into the url field of your favorite browser:

    https://radiator-spark.local/user/verify?tkn=123123145asdfoaijnewpoinav-asdf

    If you did not ask for this email, you can safely ignore it.

    Yours,
      Radiator-Spark Team
    """)
  end

  def email_base do
    new_email()
    |> from(Config.email_from_email())
  end

  defp mail_subject(subject) do
    "[Radiator] #{subject}"
  end
end
