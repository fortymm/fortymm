defmodule FortymmWeb.Administration.LeaguesController do
  use FortymmWeb, :controller

  alias Fortymm.Leagues

  def index(conn, _params) do
    render(conn, "index.html", leagues: load_leagues())
  end

  defp load_leagues, do: Leagues.list_leagues()
end
