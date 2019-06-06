defmodule Radiator.Support.DateTime do
  def after_utc_now?(date) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :gt -> true
      _ -> false
    end
  end

  def before_utc_now?(date) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :lt -> true
      _ -> false
    end
  end
end
