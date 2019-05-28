defmodule Mix.Tasks.Radiator.AddUser do
  use Mix.Task

  @shortdoc "Add a user."

  @moduledoc """
  Add a user. Use `-a` to pre-confirm the email address.

      mix radiator.adduser username email password

  ## Options

    * `-a/--activate` - activates the newly created user so no more email verification is necessary.
    * `-d/--debug` - output more information for debugging.

  """

  @switches [debug: :boolean, activate: :boolean]
  @aliases [d: :debug, a: :activate]

  alias Radiator.Auth

  defmacrop with_services(_opts \\ [], do: block) do
    quote do
      start_services()
      unquote(block)
      stop_services()
    end
  end

  @impl true
  @doc false
  def run(argv) do
    case parse_opts(argv) do
      {opts, [name, email, password]} ->
        opts = Map.new(opts)

        unless opts[:debug], do: Logger.configure(level: :info)

        with_services do
          case Auth.Register.create_user(%{
                 name: name,
                 email: email,
                 password: password
               }) do
            {:ok, user} ->
              Mix.Shell.IO.info([
                "Created user ",
                :bright,
                "#{name} <#{email}>",
                :reset,
                " with id ",
                :bright,
                "#{user.id}"
              ])

              if opts[:activate] do
                case Auth.Register.activate_user(user) do
                  {:ok, user} ->
                    Mix.Shell.IO.info(["Activated user ", :bright, "#{user.name} <#{user.email}>"])

                  _ ->
                    Mix.Shell.IO.error(["error: ", :reset, "could not activate user"])
                end
              end

            {:error, changeset} ->
              Mix.Shell.IO.error(["error: ", :reset, "Failed to create #{name} <#{email}>"])

              changeset.errors
              |> Enum.each(fn {key, {msg, opts}} ->
                Mix.Shell.IO.error([
                  :cyan,
                  "       ",
                  "#{key}",
                  :reset,
                  " ",
                  Enum.reduce(opts, msg, fn {key, value}, acc ->
                    String.replace(acc, "%{#{key}}", to_string(value))
                  end),
                  " ",
                  :light_black,
                  "(",
                  inspect(opts),
                  ")"
                ])
              end)
          end
        end

      _ ->
        Mix.Tasks.Help.run(["radiator.add_user"])
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches, aliases: @aliases) do
      {opts, argv, []} ->
        {opts, argv}

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  @start_apps [:metalove, :postgrex, :ecto, :ecto_sql]
  @repos Application.get_env(:radiator, :ecto_repos, [])

  defp start_services do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    :init.stop()
  end
end
