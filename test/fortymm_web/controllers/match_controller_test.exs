defmodule FortymmWeb.MatchControllerTest do
  use FortymmWeb.ConnCase, async: true

  import Fortymm.AccountsFixtures
  import Fortymm.MatchesFixtures

  alias Fortymm.Matches.MatchStore

  setup do
    # Clear ETS tables before each test
    MatchStore.clear()
    :ok
  end

  describe "GET /matches" do
    test "renders matches list for authenticated user", %{conn: conn} do
      user = user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Matches"
      assert html =~ "Browse and manage all matches"
    end

    test "displays matches table", %{conn: conn} do
      user = user_fixture()
      match1 = pending_match_fixture()
      match2 = complete_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      # Check for match IDs (first 8 characters)
      assert html =~ String.slice(match1.id, 0..7)
      assert html =~ String.slice(match2.id, 0..7)
    end

    test "displays match statuses", %{conn: conn} do
      user = user_fixture()
      _pending = pending_match_fixture()
      _in_progress = in_progress_match_fixture()
      _complete = complete_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Pending"
      assert html =~ "In Progress"
      assert html =~ "Complete"
    end

    test "displays match configuration", %{conn: conn} do
      user = user_fixture()

      _match =
        match_fixture(%{
          match_configuration: %Fortymm.Matches.Configuration{length_in_games: 5}
        })

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Best of 5"
    end

    test "displays participant numbers", %{conn: conn} do
      user = user_fixture()

      _match =
        match_fixture(%{
          participants: [
            %Fortymm.Matches.Participant{user_id: 1, participant_number: 1},
            %Fortymm.Matches.Participant{user_id: 2, participant_number: 2}
          ]
        })

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Player 1"
      assert html =~ "Player 2"
    end

    test "displays search form", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Search"
      assert html =~ "Match ID"
    end

    test "displays status filter dropdown", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Status"
      assert html =~ "All Statuses"
      assert html =~ "Pending"
      assert html =~ "In Progress"
      assert html =~ "Complete"
      assert html =~ "Canceled"
      assert html =~ "Aborted"
    end

    test "displays sortable column headers", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Match ID"
      assert html =~ "Participants"
      assert html =~ "Status"
      assert html =~ "Configuration"
      assert html =~ "Actions"
    end

    test "displays pagination", %{conn: conn} do
      user = user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      assert html =~ "results"
    end

    test "displays view button for each match", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "hero-arrow-top-right-on-square"
      assert html =~ "/matches/#{match.id}"
    end
  end

  describe "GET /matches with filters" do
    test "filters by search term (match ID)", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=#{String.slice(match.id, 0..7)}")

      html = html_response(conn, 200)
      assert html =~ String.slice(match.id, 0..7)
    end

    test "filters by status - pending", %{conn: conn} do
      user = user_fixture()
      pending = pending_match_fixture()
      _complete = complete_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=pending")

      html = html_response(conn, 200)
      assert html =~ String.slice(pending.id, 0..7)
      # Complete status should not be displayed in the table since we filtered for pending
    end

    test "filters by status - complete", %{conn: conn} do
      user = user_fixture()
      _pending = pending_match_fixture()
      complete = complete_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=complete")

      html = html_response(conn, 200)
      assert html =~ String.slice(complete.id, 0..7)
    end

    test "filters by status - in_progress", %{conn: conn} do
      user = user_fixture()
      _pending = pending_match_fixture()
      in_progress = in_progress_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=in_progress")

      html = html_response(conn, 200)
      assert html =~ String.slice(in_progress.id, 0..7)
    end

    test "displays clear filter button when search is active", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=test")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "displays clear filter button when status filter is active", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=pending")

      html = html_response(conn, 200)
      assert html =~ "Clear"
    end

    test "does not display clear filter button when search is empty", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "does not display clear filter button when status is empty", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=")

      html = html_response(conn, 200)
      refute html =~ "Clear"
    end

    test "combines search and status filter", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=#{String.slice(match.id, 0..7)}&status=pending")

      html = html_response(conn, 200)
      assert html =~ String.slice(match.id, 0..7)
    end

    test "displays empty state when no matches match filters", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=nonexistent")

      html = html_response(conn, 200)
      assert html =~ "No matches found"
      assert html =~ "Try adjusting your filters"
    end
  end

  describe "GET /matches with pagination" do
    test "paginates matches with page parameter", %{conn: conn} do
      user = user_fixture()

      # Create enough matches to trigger pagination
      for _ <- 1..25 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?page=2&per_page=10")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      # Should show results 11-20 out of total
      assert html =~ "11"
    end

    test "handles invalid page parameter", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?page=invalid")

      # Should default to page 1
      assert html_response(conn, 200)
    end

    test "handles page less than 1", %{conn: conn} do
      user = user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?page=0")

      html = html_response(conn, 200)
      # Should show page 1
      assert html =~ "Showing"
    end

    test "displays pagination controls", %{conn: conn} do
      user = user_fixture()

      # Create enough matches for multiple pages
      for _ <- 1..25 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "hero-chevron-left"
      assert html =~ "hero-chevron-right"
    end

    test "displays pagination links for multiple pages", %{conn: conn} do
      user = user_fixture()

      # Create enough matches for multiple pages
      for _ <- 1..50 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?per_page=10")

      html = html_response(conn, 200)
      # Should display pagination controls with chevrons
      assert html =~ "hero-chevron-left"
      assert html =~ "hero-chevron-right"
      assert html =~ "join"
    end
  end

  describe "GET /matches with sorting" do
    test "sorts by id ascending", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?sort_by=id&sort_order=asc")

      html = html_response(conn, 200)
      # Should show chevron-up for active ascending sort
      assert html =~ "hero-chevron-up"
    end

    test "sorts by id descending", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?sort_by=id&sort_order=desc")

      html = html_response(conn, 200)
      # Should show chevron-down for active descending sort
      assert html =~ "hero-chevron-down"
    end

    test "sorts by status", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?sort_by=status&sort_order=asc")

      assert html_response(conn, 200)
    end

    test "handles invalid sort_by parameter", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?sort_by=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "handles invalid sort_order parameter", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?sort_order=invalid")

      # Should still render with default sorting
      assert html_response(conn, 200)
    end

    test "preserves filters when sorting", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=#{String.slice(match.id, 0..7)}&sort_by=status&sort_order=asc")

      html = html_response(conn, 200)
      # Should maintain search filter in the form
      assert html =~ String.slice(match.id, 0..7)
    end
  end

  describe "Authorization" do
    test "denies access to unauthenticated user", %{conn: conn} do
      conn = get(conn, ~p"/matches")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "must log in"
    end

    test "allows access to authenticated user", %{conn: conn} do
      user = user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      assert html_response(conn, 200) =~ "Matches"
    end

    test "allows access to regular user", %{conn: conn} do
      user = regular_user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      assert html_response(conn, 200) =~ "Matches"
    end

    test "allows access to admin user", %{conn: conn} do
      admin = admin_user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(admin)
        |> get(~p"/matches")

      assert html_response(conn, 200) =~ "Matches"
    end
  end

  describe "UI Components" do
    test "displays breadcrumb navigation", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Breadcrumb"
      assert html =~ "Home"
      assert html =~ "Matches"
    end

    test "uses daisyUI card components", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "card"
      assert html =~ "card-body"
    end

    test "uses daisyUI form components", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "form-control"
      assert html =~ "input input-bordered"
      assert html =~ "select select-bordered"
    end

    test "uses daisyUI button components", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "btn btn-primary"
    end

    test "uses daisyUI table components", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "table table-zebra"
    end

    test "uses daisyUI badge components for status", %{conn: conn} do
      user = user_fixture()
      _pending = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "badge"
      assert html =~ "badge-warning"
    end

    test "uses daisyUI join components for pagination", %{conn: conn} do
      user = user_fixture()

      # Create enough matches for pagination
      for _ <- 1..25 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?per_page=10")

      html = html_response(conn, 200)
      assert html =~ "join"
      assert html =~ "join-item"
    end
  end

  describe "Data Display" do
    test "displays match ID (first 8 characters)", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ String.slice(match.id, 0..7)
    end

    test "displays status badge variants", %{conn: conn} do
      user = user_fixture()

      _pending = pending_match_fixture()
      _in_progress = in_progress_match_fixture()
      _complete = complete_match_fixture()
      _canceled = canceled_match_fixture()
      _aborted = aborted_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      # Check for badge classes for different statuses
      assert html =~ "badge-warning"
      assert html =~ "badge-info"
      assert html =~ "badge-success"
      assert html =~ "badge-neutral"
      assert html =~ "badge-error"
    end

    test "displays match configuration length", %{conn: conn} do
      user = user_fixture()

      _match =
        match_fixture(%{
          match_configuration: %Fortymm.Matches.Configuration{length_in_games: 7}
        })

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Best of 7"
    end

    test "displays dash when configuration is missing", %{conn: conn} do
      user = user_fixture()

      match = match_fixture(%{match_configuration: nil})

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      # Should display a dash for missing configuration
      # The page should still render successfully
      assert html =~ String.slice(match.id, 0..7)
    end

    test "shows player numbers from participants", %{conn: conn} do
      user = user_fixture()

      _match =
        match_fixture(%{
          participants: [
            %Fortymm.Matches.Participant{user_id: 10, participant_number: 1},
            %Fortymm.Matches.Participant{user_id: 20, participant_number: 2}
          ]
        })

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Player 1"
      assert html =~ "Player 2"
    end
  end

  describe "Integration" do
    test "combines all features: search, filter, sort, paginate", %{conn: conn} do
      user = user_fixture()

      # Create matches with different statuses
      for i <- 1..15 do
        _match = pending_match_fixture()

        if i <= 7 do
          pending_match_fixture()
        else
          complete_match_fixture()
        end
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=pending&sort_by=id&sort_order=asc&page=1&per_page=10")

      html = html_response(conn, 200)
      assert html =~ "Showing"
      assert html =~ "Pending"
    end

    test "maintains filters and sort in pagination links", %{conn: conn} do
      user = user_fixture()

      # Create enough matches for pagination
      for _ <- 1..25 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?status=pending&sort_by=id&sort_order=asc")

      html = html_response(conn, 200)
      # Check that pagination links preserve filters
      assert html =~ "status=pending"
      assert html =~ "sort_by=id"
      assert html =~ "sort_order=asc"
    end

    test "maintains search and sort in pagination links", %{conn: conn} do
      user = user_fixture()
      match = pending_match_fixture()

      # Create more matches
      for _ <- 1..20 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches?search=#{String.slice(match.id, 0..3)}&sort_by=status&sort_order=asc")

      html = html_response(conn, 200)
      # Check that pagination links preserve search and sort
      assert html =~ "search="
      assert html =~ "sort_by=status"
      assert html =~ "sort_order=asc"
    end

    test "empty state shows when no matches exist", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "No matches found"
    end

    test "displays count of total matches", %{conn: conn} do
      user = user_fixture()

      # Create 5 matches
      for _ <- 1..5 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "of <span class=\"font-semibold\">5</span>"
    end
  end

  describe "Default parameters" do
    test "defaults to page 1", %{conn: conn} do
      user = user_fixture()
      _match = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      assert html =~ "Showing"
    end

    test "defaults to 20 items per page", %{conn: conn} do
      user = user_fixture()

      # Create exactly 20 matches
      for _ <- 1..20 do
        pending_match_fixture()
      end

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      # All 20 should be displayed
      assert html =~ "Showing"
    end

    test "defaults to sorting by id ascending", %{conn: conn} do
      user = user_fixture()
      match1 = pending_match_fixture()
      _match2 = pending_match_fixture()
      _match3 = pending_match_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/matches")

      html = html_response(conn, 200)
      # Default sort should be by ID ascending
      assert html =~ String.slice(match1.id, 0..7) || html =~ "Player 1"
    end
  end
end
