defmodule FortymmWeb.Administration.UploadLeagueDataLiveTest do
  use FortymmWeb.ConnCase

  alias Fortymm.Factory
  import Phoenix.LiveViewTest

  @header_selector "#league-data-upload-header"

  test "shows the header", %{conn: conn} do
    league = Factory.insert(:league)

    {:ok, _view, html} =
      live(
        conn,
        Routes.administration_upload_league_data_path(conn, :index, league.id)
      )

    assert "Administration > Leagues > #{league.name} > Upload Data" ==
             html
             |> Floki.find(@header_selector)
             |> Floki.text()
             |> String.trim()
  end
end
