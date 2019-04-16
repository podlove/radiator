# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Radiator.Repo.insert!(%Radiator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Radiator.Directory
alias Radiator.Auth.Register

if Mix.env() != :test do
  Directory.create_network(%{
    title: "ACME"
  })

  Register.create_user(%{
    name: "admin",
    email: "admin@example.com",
    display_name: "admin",
    password: "password",
    status: :active
  })
end
