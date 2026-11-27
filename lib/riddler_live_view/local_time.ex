defmodule RiddlerLiveView.LocalTime do
  @moduledoc false

  # The visitor's wall time and riddler's instant, for a text question of
  # the `datetime` format.
  #
  # riddler's datetime is a date and a time joined by `T`, then `Z` or an
  # offset `+HH:MM` or `-HH:MM`: an instant. The browser's
  # `<input type="datetime-local">` takes and submits a wall time with no
  # offset. Given the visitor's time zone, a name the host's configured
  # `Calendar.TimeZoneDatabase` resolves, this module turns one into the
  # other:
  #
  #   * `local/2` reads a presented instant (a bound or a value) as the wall
  #     time it is in the zone, in the shape the browser's input takes;
  #   * `instant/2` reads a submitted wall time in the zone and writes it in
  #     riddler's shape, the wall time as submitted with the offset in force
  #     in the zone at that moment appended, `Z` where the offset is zero.
  #
  # A wall time the zone skips (a gap, when the clocks go forward) is read
  # with the offset in force before the gap, so it names the instant that
  # many minutes after the gap opens; a wall time the zone passes twice (an
  # overlap, when the clocks go back) is read with the offset in force
  # first, the earlier of the two instants.
  #
  # Only the standard library reads them; the zone is resolved through
  # whatever database the host configured, and a zone it cannot resolve is
  # no zone at all: `zone/1` answers nil for it.

  @presented ~r/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?(Z|([+\-])(\d{2}):(\d{2}))\z/
  @submitted ~r/\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?\z/

  # The zone a host passed, where the host's time zone database resolves
  # it; nil for no zone, a zone that is not a string and a zone the
  # database does not know.
  @spec zone(term()) :: String.t() | nil
  def zone(zone) when is_binary(zone) do
    case DateTime.shift_zone(~U[2000-01-01 00:00:00Z], zone) do
      {:ok, _datetime} -> zone
      {:error, _reason} -> nil
    end
  end

  def zone(_zone), do: nil

  # A presented datetime as the wall time it is in the zone,
  # `YYYY-MM-DDTHH:MM`, or `YYYY-MM-DDTHH:MM:SS` where it carries seconds;
  # nil for anything not in riddler's datetime shape, and for a wall time
  # whose year is not four digits, which the browser's input cannot take.
  @spec local(term(), String.t()) :: String.t() | nil
  def local(presented, zone) when is_binary(presented) do
    with [_whole | parts] <- Regex.run(@presented, presented),
         {:ok, utc} <- utc(parts),
         {:ok, %DateTime{year: year} = wall} when year in 0..9999 <-
           DateTime.shift_zone(utc, zone) do
      wall_text(wall, seconds?(parts))
    else
      _not_local -> nil
    end
  end

  def local(_presented, _zone), do: nil

  # A submitted wall time in riddler's shape, read in the zone; anything not
  # a wall time the browser submits, or not a date that exists, is answered
  # unchanged, for riddler to refuse.
  @spec instant(term(), String.t()) :: term()
  def instant(submitted, zone) when is_binary(submitted) do
    with [_whole | parts] <- Regex.run(@submitted, submitted),
         {:ok, naive} <- naive(parts),
         {:ok, offset} <- offset_at(naive, zone),
         {:ok, suffix} <- suffix(offset) do
      submitted <> suffix
    else
      _not_a_wall_time -> submitted
    end
  end

  def instant(submitted, _zone), do: submitted

  defp utc([year, month, day, hour, minute, second, zone | sign_and_offset]) do
    with {:ok, naive} <- naive([year, month, day, hour, minute, second]),
         {:ok, offset} <- presented_offset(zone, sign_and_offset) do
      naive |> NaiveDateTime.add(-offset) |> DateTime.from_naive("Etc/UTC")
    end
  end

  defp presented_offset("Z", _sign_and_offset), do: {:ok, 0}

  defp presented_offset(_zone, [sign, hours, minutes]) do
    with {hours, ""} when hours < 24 <- Integer.parse(hours),
         {minutes, ""} when minutes < 60 <- Integer.parse(minutes) do
      magnitude = hours * 3600 + minutes * 60
      {:ok, if(sign == "-", do: -magnitude, else: magnitude)}
    else
      _not_an_offset -> :error
    end
  end

  defp naive([year, month, day, hour, minute | second]) do
    second = if second in [[], [""]], do: 0, else: String.to_integer(hd(second))

    NaiveDateTime.new(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      second
    )
  end

  defp seconds?([_year, _month, _day, _hour, _minute, second | _zone]), do: second != ""

  defp wall_text(wall, seconds?) do
    text = wall |> DateTime.to_naive() |> NaiveDateTime.to_iso8601()
    if seconds?, do: String.slice(text, 0, 19), else: String.slice(text, 0, 16)
  end

  # The offset in force in the zone at a wall time: before the gap for a
  # wall time the zone skips, the first for one it passes twice.
  defp offset_at(naive, zone) do
    case DateTime.from_naive(naive, zone) do
      {:ok, datetime} -> {:ok, total_offset(datetime)}
      {:gap, before, _after} -> {:ok, total_offset(before)}
      {:ambiguous, first, _second} -> {:ok, total_offset(first)}
      {:error, _reason} -> :error
    end
  end

  defp total_offset(datetime), do: datetime.utc_offset + datetime.std_offset

  # riddler writes an offset in whole minutes, under a day.
  defp suffix(0), do: {:ok, "Z"}

  defp suffix(offset) when rem(offset, 60) == 0 and abs(offset) < 86_400 do
    sign = if offset < 0, do: "-", else: "+"
    minutes = div(abs(offset), 60)
    {:ok, sign <> pad(div(minutes, 60)) <> ":" <> pad(rem(minutes, 60))}
  end

  defp suffix(_offset), do: :error

  defp pad(number), do: number |> Integer.to_string() |> String.pad_leading(2, "0")
end
