# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Fortymm.Repo.insert!(%Fortymm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

usatt_slug = Fortymm.Leagues.League.usatt_slug()
usatt_attrs = %{name: "USATT"}

try do
  usatt = Fortymm.Leagues.get_league_by_slug!(usatt_slug)
  Fortymm.Leagues.update_league(usatt, usatt_attrs)
rescue
  Ecto.NoResultsError ->
    usatt_attrs
    |> Enum.into(%{slug: usatt_slug})
    |> Fortymm.Leagues.create_league()
end
