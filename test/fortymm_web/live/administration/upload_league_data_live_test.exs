defmodule FortymmWeb.Administration.UploadLeagueDataLiveTest do
  use FortymmWeb.ConnCase

  alias Fortymm.Factory
  alias Fortymm.LeagueDataIngestions
  alias Fortymm.LeagueDataIngestions.LeagueDataIngestion
  import Phoenix.LiveViewTest

  @header_selector "#league-data-upload-header"
  @flash_selector ".alert"

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

  test "does not show a flash", %{conn: conn} do
    league = Factory.insert(:league)

    {:ok, _view, html} =
      live(
        conn,
        Routes.administration_upload_league_data_path(conn, :index, league.id)
      )

    assert "" ==
             Floki.find(html, @flash_selector)
             |> Floki.text()
             |> String.trim()
  end

  describe "when data ingestion is queued" do
    test "shows a flash", %{conn: conn} do
      league = Factory.insert(:league)

      {:ok, view, _html} =
        live(
          conn,
          Routes.administration_upload_league_data_path(conn, :index, league.id)
        )

      html =
        view
        |> element("form")
        |> render_submit()

      assert "Ingestion Successfully Queued" ==
               Floki.find(html, @flash_selector)
               |> Floki.text()
               |> String.trim()
    end

    test "creates a data ingestion task", %{conn: conn} do
      league = Factory.insert(:league)

      {:ok, view, _html} =
        live(
          conn,
          Routes.administration_upload_league_data_path(conn, :index, league.id)
        )

      view
      |> element("form")
      |> render_submit()

      assert [data_ingestion] = LeagueDataIngestions.list_league_data_ingestions()

      assert data_ingestion.league_id == league.id
      assert data_ingestion.status == LeagueDataIngestion.pending()
    end
  end
end
