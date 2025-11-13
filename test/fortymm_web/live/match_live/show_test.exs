defmodule FortymmWeb.MatchLive.ShowTest do
  use FortymmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  alias Fortymm.Matches

  setup do
    # Clear ETS tables before each test
    Fortymm.Matches.MatchStore.clear()
    Fortymm.Matches.ChallengeStore.clear()
    :ok
  end

  defp create_match(
         user1,
         user2,
         _config \\ %{length_in_games: 3, rated: false},
         _status \\ "pending",
         _games \\ []
       ) do
    # Create a challenge first
    {:ok, challenge} =
      Matches.create_challenge(%{
        configuration: %{length_in_games: 3, rated: false},
        created_by_id: user1.id
      })

    # Accept the challenge to create a match
    {:ok, match} = Matches.accept_challenge(challenge.id, user2.id)
    match
  end

  describe "Match show page rendering" do
    test "renders match details page for logged-in user", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Match"
      assert html =~ "Participants"
      assert html =~ "Games"
    end

    test "displays match not found for non-existent match", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/matches/nonexistent-id")

      assert html =~ "Match Not Found"
    end

    test "displays back to matches link", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Back to Matches"
    end
  end

  describe "Match status display" do
    test "displays match status badge and best of configuration", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Pending"
      assert html =~ "Best of 3"
    end

    test "displays match status badge for pending match", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Pending"
    end
  end

  describe "Participant information" do
    test "displays both participants with usernames", %{conn: conn} do
      user1 = user_fixture(username: "player_one")
      user2 = user_fixture(username: "player_two")
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "player_one"
      assert html =~ "player_two"
      assert html =~ "Player 1"
      assert html =~ "Player 2"
    end

    test "does not display email addresses", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      refute html =~ user1.email
      refute html =~ user2.email
    end
  end

  describe "Match progress indicator" do
    test "displays match progress on match header", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Match Progress"
    end
  end

  describe "Games section" do
    test "displays games section on page", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      # Games section should be present
      assert html =~ "Games"
    end
  end

  describe "Games won calculation" do
    test "displays games won count for each participant", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "games won"
    end
  end

  describe "Match page content" do
    test "renders all major sections", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      # Verify key sections are present
      assert html =~ "Participants"
      assert html =~ "Games"
    end
  end

  describe "Match score summary" do
    test "displays score summary for both players in header", %{conn: conn} do
      user1 = user_fixture(username: "alice")
      user2 = user_fixture(username: "bob")
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "alice"
      assert html =~ "bob"
    end

    test "displays match length in header", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      assert html =~ "Best of 3"
    end
  end

  describe "Page accessibility" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/matches/some-id")
    end
  end
end
