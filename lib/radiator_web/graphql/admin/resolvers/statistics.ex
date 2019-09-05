defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Statistics do
  use Radiator.Constants

  import Absinthe.Resolution.Helpers

  alias Radiator.Reporting

  def get_statistics(subject, _, _) do
    {:ok,
     %{
       downloads: {subject, :downloads},
       listeners: {subject, :listeners},
       user_agents: {subject, :user_agents}
     }}
  end

  def get_total_statistics({subject, metric}, _args, _) do
    {:ok,
     Reporting.Statistics.get(%{
       subject: subject,
       metric: metric,
       time_type: :total
     })}
  end

  def get_monthly_statistics({subject, metric}, args, _) do
    {:ok,
     Reporting.Statistics.get(
       %{
         subject: subject,
         metric: metric,
         time_type: :month
       }
       |> Map.merge(args)
     )}
  end

  def get_daily_statistics({subject, metric}, args, _) do
    {:ok,
     Reporting.Statistics.get(
       %{
         subject: subject,
         metric: metric,
         time_type: :day
       }
       |> Map.merge(args)
     )}
  end
end
