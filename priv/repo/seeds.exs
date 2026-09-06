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

password = "9dSeBmBca9fr"
{:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(password)

Ash.Seed.seed!(Radiator.Accounts.User, %{
  email: "alice@example.com",
  hashed_password: hashed_password
})

Ash.Seed.seed!(Radiator.Accounts.User, %{
  email: "bob@example.com",
  hashed_password: hashed_password
})
