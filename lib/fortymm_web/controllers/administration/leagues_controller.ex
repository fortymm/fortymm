defmodule FortymmWeb.Administration.LeaguesController do
  use FortymmWeb, :controller

  alias Fortymm.Leagues

  def index(conn, _params) do
    render(conn, "index.html", leagues: load_leagues())
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", league: load_league!(id))
  end

  defp load_leagues, do: Leagues.list_leagues()

  defp load_league!(id), do: Leagues.get_league!(id)
end
