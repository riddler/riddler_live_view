defmodule RiddlerLiveView.TestZones do
  @moduledoc """
  A time zone database for the suite, so that no dependency is added for
  one: `"Etc/UTC"`, `"Asia/Kolkata"` at a fixed `+05:30`, and
  `"America/Denver"` with the two changes of 2026 only, standard time
  (`-07:00`) before 2026-03-08 02:00 and from 2026-11-01 02:00 local, and
  daylight time (`-06:00`) between them. Any other name is not found.
  """

  @behaviour Calendar.TimeZoneDatabase

  @utc %{utc_offset: 0, std_offset: 0, zone_abbr: "UTC"}
  @ist %{utc_offset: 19_800, std_offset: 0, zone_abbr: "IST"}
  @mst %{utc_offset: -25_200, std_offset: 0, zone_abbr: "MST"}
  @mdt %{utc_offset: -25_200, std_offset: 3600, zone_abbr: "MDT"}

  # The two changes, in UTC and on the wall.
  @spring_utc ~N[2026-03-08 09:00:00]
  @fall_utc ~N[2026-11-01 08:00:00]
  @gap_from ~N[2026-03-08 02:00:00]
  @gap_to ~N[2026-03-08 03:00:00]
  @overlap_from ~N[2026-11-01 01:00:00]
  @overlap_to ~N[2026-11-01 02:00:00]

  @impl true
  def time_zone_period_from_utc_iso_days(_iso_days, "Etc/UTC"), do: {:ok, @utc}
  def time_zone_period_from_utc_iso_days(_iso_days, "Asia/Kolkata"), do: {:ok, @ist}

  def time_zone_period_from_utc_iso_days(iso_days, "America/Denver") do
    {year, month, day, hour, minute, second, _micro} =
      Calendar.ISO.naive_datetime_from_iso_days(iso_days)

    {:ok, utc} = NaiveDateTime.new(year, month, day, hour, minute, second)

    if before?(utc, @spring_utc) or not before?(utc, @fall_utc),
      do: {:ok, @mst},
      else: {:ok, @mdt}
  end

  def time_zone_period_from_utc_iso_days(_iso_days, _zone), do: {:error, :time_zone_not_found}

  @impl true
  def time_zone_periods_from_wall_datetime(_naive, "Etc/UTC"), do: {:ok, @utc}
  def time_zone_periods_from_wall_datetime(_naive, "Asia/Kolkata"), do: {:ok, @ist}

  def time_zone_periods_from_wall_datetime(naive, "America/Denver") do
    cond do
      before?(naive, @gap_from) ->
        {:ok, @mst}

      before?(naive, @gap_to) ->
        {:gap, {@mst, @gap_from}, {@mdt, @gap_to}}

      before?(naive, @overlap_from) ->
        {:ok, @mdt}

      before?(naive, @overlap_to) ->
        {:ambiguous, @mdt, @mst}

      true ->
        {:ok, @mst}
    end
  end

  def time_zone_periods_from_wall_datetime(_naive, _zone), do: {:error, :time_zone_not_found}

  defp before?(one, other), do: NaiveDateTime.compare(one, other) == :lt
end

Calendar.put_time_zone_database(RiddlerLiveView.TestZones)

ExUnit.start()
