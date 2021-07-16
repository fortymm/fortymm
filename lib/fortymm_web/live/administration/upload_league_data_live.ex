defmodule FortymmWeb.Administration.UploadLeagueDataLive do
  use FortymmWeb, :live_view

  alias Fortymm.Leagues

  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, query: "", league: load_league(id))}
  end

  defp load_league(id), do: Leagues.get_league!(id)
end
