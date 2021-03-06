defmodule Fortymm.Administration.LeaguesControllerTest do
  use FortymmWeb.ConnCase

  alias Fortymm.Factory

  describe "show" do
    @header_selector "#league-administration-header"
    @upload_data_selector "a#upload_data"

    test "links to the data upload page for the league", %{conn: conn} do
      league = Factory.insert(:league)

      assert [Routes.administration_upload_league_data_path(conn, :index, league.id)] ==
               conn
               |> get(Routes.administration_leagues_path(conn, :show, league.id))
               |> html_response(200)
               |> Floki.find(@upload_data_selector)
               |> Floki.attribute("href")
    end

    test "renders the header", %{conn: conn} do
      league = Factory.insert(:league)

      assert "Administration > Leagues > #{league.name}" ==
               conn
               |> get(Routes.administration_leagues_path(conn, :show, league.id))
               |> html_response(200)
               |> Floki.find(@header_selector)
               |> Floki.text()
               |> String.trim()
    end
  end

  describe "index" do
    @header_selector "#league-administration-header"
    @league_id_selector ".league-id"
    @league_slug_selector ".league-slug"
    @league_name_selector ".league-name"
    @league_inserted_at_selector ".league-inserted-at"
    @league_updated_at_selector ".league-updated-at"
    @empty_state_selector ".no-leagues-found"
    @details_link_selector "a.league-details"

    test "renders the header", %{conn: conn} do
      assert "Administration > Leagues" ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@header_selector)
               |> Floki.text()
               |> String.trim()
    end

    test "links to the leauge details page", %{conn: conn} do
      league = Factory.insert(:league)

      assert [Routes.administration_leagues_path(conn, :show, league.id)] ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@details_link_selector)
               |> Floki.attribute("href")
    end

    test "shows an empty state when there are no leagues", %{conn: conn} do
      refute [] ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@empty_state_selector)
    end

    test "does not show an empty state when there are leagues", %{conn: conn} do
      Factory.insert(:league)

      assert [] ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@empty_state_selector)
    end

    test "shows the league id", %{conn: conn} do
      league = Factory.insert(:league)

      assert "#{league.id}" ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@league_id_selector)
               |> Floki.text()
    end

    test "shows the league slug", %{conn: conn} do
      league = Factory.insert(:league)

      assert league.slug ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@league_slug_selector)
               |> Floki.text()
    end

    test "shows the league name", %{conn: conn} do
      league = Factory.insert(:league)

      assert league.name ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@league_name_selector)
               |> Floki.text()
    end

    test "shows when the league was inserted", %{conn: conn} do
      league = Factory.insert(:league)

      assert NaiveDateTime.to_string(league.inserted_at) ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@league_inserted_at_selector)
               |> Floki.text()
    end

    test "shows when the league was updated", %{conn: conn} do
      league = Factory.insert(:league)

      assert NaiveDateTime.to_string(league.updated_at) ==
               conn
               |> get(Routes.administration_leagues_path(conn, :index))
               |> html_response(200)
               |> Floki.find(@league_updated_at_selector)
               |> Floki.text()
    end
  end
end
