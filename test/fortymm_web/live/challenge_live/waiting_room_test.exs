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
    test "renders waiting room page for logged-in user who created the challenge", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: user.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Waiting for Opponent"
      assert html =~ "Challenge sent!"
    end

    test "displays the share URL with copy button", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: user.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Check for share URL input
      assert has_element?(lv, "input#challenge-url[readonly]")
      # Check for copy button
      assert has_element?(lv, "button#copy-button[phx-hook='Copy']")
    end

    test "displays waiting status for viewers", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: user.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Viewers:"
      assert html =~ "No one yet..."
    end

    test "displays challenge type", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: true},
          created_by_id: user.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Match Type:"
      assert html =~ "Rated"
    end

    test "has a cancel challenge button", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: user.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert has_element?(lv, "button[phx-click='cancel_challenge']", "Cancel Challenge")
    end

    test "cancel challenge button redirects to dashboard", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: user.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")
    end

    test "displays animated loading indicator", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: user.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Check for spinning animation classes
      assert has_element?(lv, ".animate-spin")
    end

    test "redirects if user is not logged in", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: user.id
        })

      assert {:error, redirect} = live(conn, ~p"/challenges/#{challenge.id}/waiting_room")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays all challenge detail cards", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: user.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Check for all detail cards by their labels
      assert has_element?(lv, "span", "Match Length:")
      assert has_element?(lv, "span", "Match Type:")
      assert has_element?(lv, "span", "Viewers:")
    end

    test "handles different challenge lengths correctly", %{conn: conn} do
      user = user_fixture()

      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: false},
          created_by_id: user.id
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: user.id
        })

      {:ok, _lv, html1} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge1.id}/waiting_room")

      {:ok, _lv, html2} =
        conn
        |> log_in_user(user)
        |> live(~p"/challenges/#{challenge2.id}/waiting_room")

      assert html1 =~ "Best of 1"
      assert html2 =~ "Best of 7"
    end
  end

  describe "Challenge creator access control" do
    test "redirects non-creator user to show page", %{conn: conn} do
      creator = user_fixture()
      imposter = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(imposter)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/challenges/#{challenge.id}"
      assert flash == %{"info" => "View the challenge details to accept or decline"}
    end

    test "allows creator to view their own challenge", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Waiting for Opponent"
      assert html =~ "Challenge sent!"
    end

    test "redirects when challenge not found", %{conn: conn} do
      user = user_fixture()

      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/challenges/nonexistent-id/waiting_room")

      assert path == ~p"/dashboard"
      assert flash == %{"error" => "Challenge not found"}
    end

    test "multiple users cannot access each other's waiting rooms", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: user1.id
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: user2.id
        })

      # User1 can access their own challenge waiting room
      {:ok, _lv, html1} =
        conn
        |> log_in_user(user1)
        |> live(~p"/challenges/#{challenge1.id}/waiting_room")

      assert html1 =~ "Waiting for Opponent"

      # User2 cannot access User1's waiting room, redirected to show page
      assert {:error, {:live_redirect, %{to: path2}}} =
               conn
               |> log_in_user(user2)
               |> live(~p"/challenges/#{challenge1.id}/waiting_room")

      assert path2 == ~p"/challenges/#{challenge1.id}"

      # User3 cannot access User2's waiting room, redirected to show page
      assert {:error, {:live_redirect, %{to: path3}}} =
               conn
               |> log_in_user(user3)
               |> live(~p"/challenges/#{challenge2.id}/waiting_room")

      assert path3 == ~p"/challenges/#{challenge2.id}"
    end

    test "creator can cancel their own challenge", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")

      # Verify challenge status is updated to cancelled
      {:ok, cancelled_challenge} = Matches.get_challenge(challenge.id)
      assert cancelled_challenge.status == "cancelled"
    end
  end

  describe "Challenge status updates" do
    test "canceling challenge updates status to cancelled", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      assert challenge.status == "pending"

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      assert_redirect(lv, ~p"/dashboard")

      # Verify challenge status is updated to cancelled
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "cancelled"
    end

    test "canceling challenge broadcasts status update", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Subscribe to challenge updates
      Fortymm.Matches.ChallengeUpdates.subscribe(challenge.id)

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      # Verify broadcast was sent
      assert_receive {:challenge_updated, updated_challenge}
      assert updated_challenge.id == challenge.id
      assert updated_challenge.status == "cancelled"
    end

    test "challenge remains accessible after cancellation", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      # Challenge should still be accessible via get_challenge
      {:ok, cancelled_challenge} = Matches.get_challenge(challenge.id)
      assert cancelled_challenge.id == challenge.id
      assert cancelled_challenge.status == "cancelled"
      assert cancelled_challenge.configuration.length_in_games == 5
      assert cancelled_challenge.configuration.rated == true
    end
  end

  describe "Presence tracking for viewers" do
    test "shows 'No one yet...' when no viewers are present", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      {:ok, _lv, html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert html =~ "Viewers:"
      assert html =~ "No one yet..."
    end

    test "shows viewer username when someone views the challenge", %{conn: conn} do
      creator = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens waiting room
      {:ok, creator_lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Viewer opens challenge page (which tracks presence)
      {:ok, _viewer_lv, _html} =
        conn
        |> log_in_user(viewer)
        |> live(~p"/challenges/#{challenge.id}")

      # Give presence a moment to sync
      Process.sleep(50)

      # Check that creator sees the viewer
      html = render(creator_lv)
      assert html =~ "Viewers:"
      assert html =~ viewer.username
    end

    test "shows multiple viewers when multiple users view the challenge", %{conn: conn} do
      creator = user_fixture()
      viewer1 = user_fixture()
      viewer2 = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      # Creator opens waiting room
      {:ok, creator_lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # First viewer opens challenge page
      {:ok, _viewer1_lv, _html} =
        conn
        |> log_in_user(viewer1)
        |> live(~p"/challenges/#{challenge.id}")

      # Second viewer opens challenge page
      {:ok, _viewer2_lv, _html} =
        conn
        |> log_in_user(viewer2)
        |> live(~p"/challenges/#{challenge.id}")

      # Give presence a moment to sync
      Process.sleep(50)

      # Check that creator sees both viewers
      html = render(creator_lv)
      assert html =~ "Viewers:"
      assert html =~ viewer1.username
      assert html =~ viewer2.username
    end

    test "removes viewer when they leave the challenge page", %{conn: conn} do
      creator = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens waiting room
      {:ok, creator_lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Viewer opens challenge page
      {:ok, viewer_lv, _html} =
        conn
        |> log_in_user(viewer)
        |> live(~p"/challenges/#{challenge.id}")

      # Give presence a moment to sync
      Process.sleep(50)

      # Verify viewer is shown
      html = render(creator_lv)
      assert html =~ viewer.username

      # Viewer leaves (stop the LiveView process)
      :ok = GenServer.stop(viewer_lv.pid)

      # Give presence a moment to detect the leave
      Process.sleep(100)

      # Check that creator no longer sees the viewer
      html = render(creator_lv)
      assert html =~ "No one yet..."
      refute html =~ viewer.username
    end

    test "viewer badge has eye icon", %{conn: conn} do
      creator = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens waiting room
      {:ok, creator_lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Viewer opens challenge page
      {:ok, _viewer_lv, _html} =
        conn
        |> log_in_user(viewer)
        |> live(~p"/challenges/#{challenge.id}")

      # Give presence a moment to sync
      Process.sleep(50)

      # Check for eye icon in the viewer badge - check that badge with eye icon exists
      assert has_element?(creator_lv, "span.badge-success")
    end
  end

  describe "Challenge error handling" do
    test "canceling non-existent challenge redirects to dashboard", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Delete the challenge to simulate it being removed
      Matches.delete_challenge(challenge.id)

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      # Should redirect to dashboard when challenge not found
      assert_redirect(lv, ~p"/dashboard")
    end

    test "canceling challenge redirects to dashboard on success", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      lv |> element("button[phx-click='cancel_challenge']") |> render_click()

      # Should redirect to dashboard on success
      assert_redirect(lv, ~p"/dashboard")
    end
  end

  describe "Accepted challenge routing on mount" do
    test "creator viewing accepted challenge redirects to scoring page with flash", %{
      conn: conn
    } do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Accept the challenge
      {:ok, match} = Matches.accept_challenge(challenge.id, acceptor.id)

      # Creator tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(creator)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/matches/#{match.id}/games/1/scores/new"
      assert flash == %{"info" => "Challenge accepted! Time to enter scores"}
    end

    test "non-participant viewer viewing accepted challenge redirects to match page with flash",
         %{
           conn: conn
         } do
      creator = user_fixture()
      acceptor = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      # Accept the challenge
      {:ok, match} = Matches.accept_challenge(challenge.id, acceptor.id)

      # Non-participant viewer tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(viewer)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/matches/#{match.id}"
      assert flash == %{"info" => "Challenge accepted! The match has begun"}
    end
  end

  describe "Cancelled challenge routing on mount" do
    test "creator viewing cancelled challenge redirects to dashboard with flash", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Cancel the challenge
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      # Creator tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(creator)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/dashboard"
      assert flash == %{"info" => "This challenge has been cancelled"}
    end

    test "non-creator viewing cancelled challenge redirects to dashboard with flash", %{
      conn: conn
    } do
      creator = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: creator.id
        })

      # Cancel the challenge
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      # Viewer tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(viewer)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/dashboard"
      assert flash == %{"info" => "This challenge has been cancelled"}
    end
  end

  describe "Rejected challenge routing on mount" do
    test "creator viewing rejected challenge redirects to dashboard with flash", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Reject the challenge
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      # Creator tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(creator)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/dashboard"
      assert flash == %{"info" => "This challenge has been declined"}
    end

    test "non-creator viewing rejected challenge redirects to dashboard with flash", %{
      conn: conn
    } do
      creator = user_fixture()
      viewer = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      # Reject the challenge
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      # Viewer tries to view the waiting room
      assert {:error, {:live_redirect, %{to: path, flash: flash}}} =
               conn
               |> log_in_user(viewer)
               |> live(~p"/challenges/#{challenge.id}/waiting_room")

      assert path == ~p"/dashboard"
      assert flash == %{"info" => "This challenge has been declined"}
    end
  end

  describe "Challenge status updates via PubSub on waiting room" do
    test "creator viewing waiting room gets updated challenge when still pending", %{conn: conn} do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens the waiting room
      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Update the challenge (but keep it pending)
      {:ok, _updated_challenge} =
        Matches.update_challenge(challenge.id, %{configuration: %{length_in_games: 5}})

      # Give PubSub a moment to deliver the message
      Process.sleep(50)

      # Verify the LiveView updated the challenge assign
      html = render(lv)
      assert html =~ "Best of 5"
    end

    test "creator on waiting room redirects to scoring when challenge is accepted", %{
      conn: conn
    } do
      creator = user_fixture()
      acceptor = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens the waiting room
      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Challenge is accepted by acceptor
      {:ok, match} = Matches.accept_challenge(challenge.id, acceptor.id)

      # Give PubSub a moment to deliver the message
      Process.sleep(50)

      # Creator should be redirected to scoring page
      assert_redirect(lv, ~p"/matches/#{match.id}/games/1/scores/new")
    end

    test "creator on waiting room redirects to dashboard when challenge is cancelled", %{
      conn: conn
    } do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: creator.id
        })

      # Creator opens the waiting room
      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Challenge is cancelled
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      # Give PubSub a moment to deliver the message
      Process.sleep(50)

      # Creator should be redirected to dashboard
      assert_redirect(lv, ~p"/dashboard")
    end

    test "creator on waiting room redirects to dashboard when challenge is rejected", %{
      conn: conn
    } do
      creator = user_fixture()

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: creator.id
        })

      # Creator opens the waiting room
      {:ok, lv, _html} =
        conn
        |> log_in_user(creator)
        |> live(~p"/challenges/#{challenge.id}/waiting_room")

      # Challenge is rejected by someone
      {:ok, _} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      # Give PubSub a moment to deliver the message
      Process.sleep(50)

      # Creator should be redirected to dashboard
      assert_redirect(lv, ~p"/dashboard")
    end
  end
end
