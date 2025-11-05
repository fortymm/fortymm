defmodule FortymmWeb.DashboardLiveTest do
  use FortymmWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  describe "Dashboard page" do
    test "renders dashboard page for logged-in user", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Dashboard"
      assert html =~ "Welcome back"
    end

    test "displays the user's username in the welcome message", %{conn: conn} do
      user = user_fixture(%{username: "testuser123"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Welcome back, testuser123!"
    end

    test "displays coming soon content", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "🚀 Coming Soon!"
      assert html =~ "We&#39;re cooking up something special"
    end

    test "displays feature preview cards", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "📊 Analytics"
      assert html =~ "Track your progress with beautiful charts"
      assert html =~ "⚡ Quick Actions"
      assert html =~ "Get things done faster"
      assert html =~ "🎯 Personalized"
      assert html =~ "Everything tailored to your unique workflow"
    end

    test "displays stay tuned alert", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "✨"
      assert html =~ "Stay tuned!"
      assert html =~ "We&#39;re working around the clock"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/dashboard")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Challenge creation flow" do
    test "displays challenge a friend card", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Challenge a Friend"
      assert html =~ "Ready to put your skills to the test?"
      assert html =~ "Start Challenge"
    end

    test "displays challenge modal with form", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Modal should be present (even if hidden)
      assert has_element?(lv, "#challenge_modal")
      assert has_element?(lv, "#challenge-form")
    end

    test "challenge form has all required fields", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Check for opponent input
      assert has_element?(lv, "input[name='opponent']")
      assert has_element?(lv, "label", "Friend's Email or Username")

      # Check for challenge type select
      assert has_element?(lv, "select[name='challenge_type']")
      assert has_element?(lv, "label", "Challenge Type")

      # Check for message textarea
      assert has_element?(lv, "textarea[name='message']")
      assert has_element?(lv, "label", "Optional Message")

      # Check for submit button
      assert has_element?(lv, "button[type='submit']", "Send Challenge")
    end

    test "challenge form displays challenge type options", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Quick Match (5 rounds)"
      assert html =~ "Standard (10 rounds)"
      assert html =~ "Marathon (20 rounds)"
    end

    test "submitting challenge form redirects to waiting room", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      result =
        lv
        |> form("#challenge-form", %{
          "opponent" => "friend@example.com",
          "message" => "Let's play!"
        })
        |> render_submit()

      # Should redirect to waiting room with a challenge ID
      assert {:error, {:live_redirect, %{to: path}}} = result
      assert path =~ ~r{^/challenges/.+/waiting_room$}
    end

    test "challenge form requires opponent field", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Opponent field should be required
      assert has_element?(lv, "input[name='opponent'][required]")
    end

    test "submitting challenge with minimal data redirects successfully", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      result =
        lv
        |> form("#challenge-form", %{
          "opponent" => "testuser"
        })
        |> render_submit()

      # Should still redirect even without optional message
      assert {:error, {:live_redirect, %{to: path}}} = result
      assert path =~ ~r{^/challenges/.+/waiting_room$}
    end

    test "each challenge submission generates unique ID", %{conn: conn} do
      user = user_fixture()

      # Submit first challenge
      {:ok, lv1, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      {:error, {:live_redirect, %{to: path1}}} =
        lv1
        |> form("#challenge-form", %{"opponent" => "user1@example.com"})
        |> render_submit()

      # Start a new session and submit second challenge
      {:ok, lv2, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      {:error, {:live_redirect, %{to: path2}}} =
        lv2
        |> form("#challenge-form", %{"opponent" => "user2@example.com"})
        |> render_submit()

      # Challenge IDs should be different
      refute path1 == path2
      # Both should be valid waiting room paths
      assert path1 =~ ~r{^/challenges/.+/waiting_room$}
      assert path2 =~ ~r{^/challenges/.+/waiting_room$}
    end

    test "challenge modal has cancel button", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert has_element?(lv, "button", "Cancel")
    end

    test "challenge modal has close button", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Should have X button in dialog
      assert has_element?(lv, "#challenge_modal form[method='dialog'] button")
    end

    test "challenge form has helper text", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "We&#39;ll send them an invitation to compete"
      assert html =~ "Add a friendly message or trash talk"
    end
  end
end
