defmodule FortymmWeb.Administration.UploadLeagueDataLive do
  use FortymmWeb, :live_view

  alias Fortymm.Leagues
  alias Fortymm.LeagueDataIngestions
  alias Fortymm.LeagueDataIngestions.LeagueDataIngestion

  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:league, load_league(id))
    }
  end

  def handle_event("save", _params, socket) do
    league = socket.assigns[:league]

    {:ok, _ingestion} =
      LeagueDataIngestions.create_league_data_ingestion(%{
        league_id: league.id,
        status: LeagueDataIngestion.pending()
      })

    {:noreply,
     socket
     |> put_flash(:info, gettext("Ingestion Successfully Queued"))}
  end

  def handle_event("validate", _params, socket) do
    {:reply, socket}
  end

  defp load_league(id), do: Leagues.get_league!(id)
end
