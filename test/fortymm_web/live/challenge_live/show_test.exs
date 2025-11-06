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

  describe "Challenge status updates" do
    test "accepting challenge updates status to accepted", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      assert challenge.status == "pending"

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")

      # Verify challenge status is updated to accepted
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "accepted"
    end

    test "declining challenge updates status to rejected", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      assert challenge.status == "pending"

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")

      # Verify challenge status is updated to rejected
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "rejected"
    end

    test "accepting challenge broadcasts status update", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      # Subscribe to challenge updates
      Fortymm.Matches.ChallengeUpdates.subscribe(challenge.id)

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      # Verify broadcast was sent
      assert_receive {:challenge_updated, updated_challenge}
      assert updated_challenge.id == challenge.id
      assert updated_challenge.status == "accepted"
    end

    test "declining challenge broadcasts status update", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: false, created_by_id: creator.id})

      # Subscribe to challenge updates
      Fortymm.Matches.ChallengeUpdates.subscribe(challenge.id)

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      # Verify broadcast was sent
      assert_receive {:challenge_updated, updated_challenge}
      assert updated_challenge.id == challenge.id
      assert updated_challenge.status == "rejected"
    end

    test "challenge remains accessible after acceptance", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 7, rated: true, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      # Challenge should still be accessible via get_challenge
      {:ok, accepted_challenge} = Matches.get_challenge(challenge.id)
      assert accepted_challenge.id == challenge.id
      assert accepted_challenge.status == "accepted"
      assert accepted_challenge.length_in_games == 7
      assert accepted_challenge.rated == true
    end

    test "challenge remains accessible after rejection", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 1, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      # Challenge should still be accessible via get_challenge
      {:ok, rejected_challenge} = Matches.get_challenge(challenge.id)
      assert rejected_challenge.id == challenge.id
      assert rejected_challenge.status == "rejected"
      assert rejected_challenge.length_in_games == 1
      assert rejected_challenge.rated == false
    end

    test "only status field is updated on acceptance", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 5, rated: true, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "accepted"
      assert updated_challenge.length_in_games == challenge.length_in_games
      assert updated_challenge.rated == challenge.rated
      assert updated_challenge.created_by_id == challenge.created_by_id
    end

    test "only status field is updated on rejection", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "rejected"
      assert updated_challenge.length_in_games == challenge.length_in_games
      assert updated_challenge.rated == challenge.rated
      assert updated_challenge.created_by_id == challenge.created_by_id
    end
  end

  describe "Challenge error handling" do
    test "accepting non-existent challenge redirects to dashboard", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      # Delete the challenge to simulate it being removed
      Matches.delete_challenge(challenge.id)

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      # Should redirect to dashboard when challenge not found
      assert_redirect(lv, ~p"/dashboard")
    end

    test "declining non-existent challenge redirects to dashboard", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      # Delete the challenge to simulate it being removed
      Matches.delete_challenge(challenge.id)

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      # Should redirect to dashboard when challenge not found
      assert_redirect(lv, ~p"/dashboard")
    end

    test "accepting challenge redirects to dashboard on success", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='accept_challenge']") |> render_click()

      # Should redirect to dashboard on success
      assert_redirect(lv, ~p"/dashboard")
    end

    test "declining challenge redirects to dashboard on success", %{conn: conn} do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{length_in_games: 3, rated: false, created_by_id: creator.id})

      {:ok, lv, _html} =
        conn
        |> log_in_user(acceptor)
        |> live(~p"/challenges/#{challenge.id}")

      lv |> element("button[phx-click='decline_challenge']") |> render_click()

      # Should redirect to dashboard on success
      assert_redirect(lv, ~p"/dashboard")
    end
  end
end
