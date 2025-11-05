defmodule FortymmWeb.ChallengeLive.ShowTest do
  use FortymmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  alias Fortymm.Matches

  setup do
    # Clear ETS table before each test
    Fortymm.Matches.ChallengeStore.clear()
    :ok
  end

  describe "Challenge show page for accepting" do
    test "renders challenge details for logged-in user who did NOT create it", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Challenge Details"
      assert html =~ "Best of 3"
    end

    test "displays challenge ID", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Challenge ID:"
      assert html =~ String.slice(challenge.id, 0..7)
    end

    test "displays match length correctly", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 7, rated: false, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Match Length:"
      assert html =~ "Best of 7"
    end

    test "displays rated badge for rated matches", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: true, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Match Type:"
      assert html =~ "Rated"
    end

    test "displays unrated badge for unrated matches", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 1, rated: false, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Match Type:"
      assert html =~ "Unrated"
    end

    test "has accept challenge button", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert has_element?(lv, "button[phx-click='accept_challenge']")
    end

    test "has decline challenge button", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert has_element?(lv, "button[phx-click='decline_challenge']")
    end

    test "has back to dashboard link", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 7, rated: true, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert has_element?(lv, "a[href='/dashboard']")
    end

    test "redirects if user is not logged in", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      assert {:error, redirect} = live(conn, ~p"/challenges/#{challenge.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects when challenge not found", %{conn: conn} do
      user = user_fixture()

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/challenges/nonexistent-id")

      assert path == ~p"/dashboard"
      assert flash == %{"error" => "Challenge not found"}
    end
  end

  describe "Challenge creator redirect" do
    test "redirects creator to waiting room when they visit accept page", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      assert {:error, {:live_redirect, %{to: path}}} =
               conn
               |> log_in_user(creator)
               |> live(~p"/challenges/#{challenge.id}")

      assert path == ~p"/challenges/#{challenge.id}/waiting_room"
    end

    test "does not redirect non-creator to waiting room", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      {:ok, _lv, html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      assert html =~ "Challenge Details"
      refute html =~ "Waiting for Opponent"
    end

    test "multiple non-creators can view challenge", %{conn: conn} do
      creator = user_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, _lv, html1} =
        conn
        |> log_in_user(user1)
        |> live(~p"/challenges/#{challenge.id}")

      {:ok, _lv, html2} =
        conn
        |> log_in_user(user2)
        |> live(~p"/challenges/#{challenge.id}")

      assert html1 =~ "Challenge Details"
      assert html2 =~ "Challenge Details"
    end
  end

  describe "Challenge interaction" do
    test "accept challenge button shows confirmation prompt", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      # For now we'll just test that the button exists
      # In the future we'll implement actual accept logic
      assert has_element?(lv, "button[phx-click='accept_challenge']")
    end

    test "decline challenge redirects to dashboard with message", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")
    end
  end
end
