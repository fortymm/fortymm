defmodule FortymmWeb.ChallengeLive.WaitingRoomTest do
  use FortymmWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  alias Fortymm.Matches

  setup do
    # Clear ETS table before each test
    Fortymm.Matches.ChallengeStore.clear()
    :ok
  end

  describe "Challenge waiting room page" do
    test "renders waiting room page for logged-in user", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 3, rated: false})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Waiting for Opponent"
      assert html =~ "Challenge sent!"
    end

    test "displays the challenge ID in the details", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 5, rated: true})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Challenge ID:"
      # Display first 8 characters of the ID
      assert html =~ String.slice(challenge.id, 0..7)
    end

    test "displays waiting status for opponent", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 7, rated: false})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Opponent:"
      assert html =~ "Waiting..."
    end

    test "displays challenge type", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 3, rated: true})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Match Type:"
      assert html =~ "Rated"
    end

    test "displays info alert with notification message", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 1, rated: false})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Heads up!"
      assert html =~ "Your opponent will receive a notification"
      assert html =~ "automatically redirected when they accept"
    end

    test "has a back to dashboard link", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 5, rated: false})

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert has_element?(lv, "a[href='/dashboard']", "Back to Dashboard")
    end

    test "has a cancel challenge button", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 7, rated: true})

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert has_element?(lv, "button[phx-click='cancel_challenge']", "Cancel Challenge")
    end

    test "cancel challenge button redirects to dashboard", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 3, rated: false})

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")
    end

    test "displays animated loading indicator", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 5, rated: true})

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Check for spinning animation classes
      assert has_element?(lv, ".animate-spin")
    end

    test "redirects if user is not logged in", %{conn: conn} do
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 3, rated: false})

      assert {:error, redirect} = live(conn, ~p"/challenges/#{challenge.id}/waiting_room")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays all challenge detail cards", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge} = Matches.create_challenge(%{length_in_games: 7, rated: false})

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Check for all detail cards by their labels
      assert has_element?(lv, "span", "Challenge ID:")
      assert has_element?(lv, "span", "Match Length:")
      assert has_element?(lv, "span", "Match Type:")
      assert has_element?(lv, "span", "Opponent:")
    end

    test "handles different challenge IDs correctly", %{conn: conn} do
      user = user_fixture()
      {:ok, challenge1} = Matches.create_challenge(%{length_in_games: 1, rated: false})
      {:ok, challenge2} = Matches.create_challenge(%{length_in_games: 7, rated: true})

      {:ok, _lv, html1} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge1.id}/waiting_room")

      {:ok, _lv, html2} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge2.id}/waiting_room")

      assert html1 =~ String.slice(challenge1.id, 0..7)
      assert html2 =~ String.slice(challenge2.id, 0..7)
    end
  end
end
