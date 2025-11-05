defmodule FortymmWeb.ChallengeLive.WaitingRoomTest do
  use FortymmWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  describe "Challenge waiting room page" do
    test "renders waiting room page for logged-in user", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123def456"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert html =~ "Waiting for Opponent"
      assert html =~ "Challenge sent!"
    end

    test "displays the challenge ID in the details", %{conn: conn} do
      user = user_fixture()
      challenge_id = "test123"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert html =~ "Challenge ID:"
      assert html =~ challenge_id
    end

    test "displays waiting status for opponent", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert html =~ "Opponent:"
      assert html =~ "Waiting..."
    end

    test "displays challenge type", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert html =~ "Challenge Type:"
      assert html =~ "Quick Match"
    end

    test "displays info alert with notification message", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert html =~ "Heads up!"
      assert html =~ "Your opponent will receive a notification"
      assert html =~ "automatically redirected when they accept"
    end

    test "has a back to dashboard link", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert has_element?(lv, "a[href='/dashboard']", "Back to Dashboard")
    end

    test "has a cancel challenge button", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      assert has_element?(lv, "button[phx-click='cancel_challenge']", "Cancel Challenge")
    end

    test "cancel challenge button redirects to dashboard", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")
    end

    test "displays animated loading indicator", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      # Check for spinning animation classes
      assert has_element?(lv, ".animate-spin")
    end

    test "redirects if user is not logged in", %{conn: conn} do
      challenge_id = "abc123"

      assert {:error, redirect} = live(conn, ~p"/challenges/#{challenge_id}/waiting_room")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays all three challenge detail cards", %{conn: conn} do
      user = user_fixture()
      challenge_id = "abc123"

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id}/waiting_room")

      # Check for all three detail cards by their labels
      assert has_element?(lv, "span", "Challenge ID:")
      assert has_element?(lv, "span", "Opponent:")
      assert has_element?(lv, "span", "Challenge Type:")
    end

    test "handles different challenge IDs correctly", %{conn: conn} do
      user = user_fixture()
      challenge_id_1 = "short123"
      challenge_id_2 = "verylongchallengeidentifier987654321"

      {:ok, _lv, html1} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id_1}/waiting_room")

      {:ok, _lv, html2} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge_id_2}/waiting_room")

      assert html1 =~ challenge_id_1
      assert html2 =~ challenge_id_2
    end
  end
end
