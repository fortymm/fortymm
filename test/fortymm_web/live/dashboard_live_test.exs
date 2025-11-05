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
end
