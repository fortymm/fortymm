defmodule FortymmWeb.DashboardLiveTest do
  use FortymmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures
  import Fortymm.MatchesFixtures

  alias Fortymm.Matches.{Game, Participant, ScoreProposal, Score}

  describe "Dashboard page" do
    test "renders dashboard page for logged-in user", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Dashboard"
    end

    test "displays the user's username in the welcome message", %{conn: conn} do
      user = user_fixture(%{username: "testuser123"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Username is displayed in the navbar user menu
      assert html =~ "testuser123"
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

      # Check for length_in_games radio buttons
      assert has_element?(
               lv,
               "input[name='challenge[configuration][length_in_games]'][value='1']"
             )

      assert has_element?(
               lv,
               "input[name='challenge[configuration][length_in_games]'][value='3']"
             )

      assert has_element?(
               lv,
               "input[name='challenge[configuration][length_in_games]'][value='5']"
             )

      assert has_element?(
               lv,
               "input[name='challenge[configuration][length_in_games]'][value='7']"
             )

      assert has_element?(lv, "legend", "Match Length")

      # Check for rated checkbox
      assert has_element?(lv, "input[name='challenge[configuration][rated]'][type='checkbox']")
      assert has_element?(lv, "label", "Rated")

      # Check for submit button
      assert has_element?(lv, "button[type='submit']", "Create")
    end

    test "challenge form displays match length options", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Just One Game"
      assert html =~ "Best of 3"
      assert html =~ "Best of 5"
      assert html =~ "Best of 7"
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
          "challenge" => %{
            "configuration" => %{
              "length_in_games" => "3",
              "rated" => "true"
            }
          }
        })
        |> render_submit()

      # Should redirect to waiting room with a challenge ID
      assert {:error, {:live_redirect, %{to: path}}} = result
      assert path =~ ~r{^/challenges/.+/waiting_room$}
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
          "challenge" => %{
            "configuration" => %{
              "length_in_games" => "5"
            }
          }
        })
        |> render_submit()

      # Should still redirect even when rated defaults to false
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
        |> form("#challenge-form", %{
          "challenge" => %{"configuration" => %{"length_in_games" => "3"}}
        })
        |> render_submit()

      # Start a new session and submit second challenge
      {:ok, lv2, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      {:error, {:live_redirect, %{to: path2}}} =
        lv2
        |> form("#challenge-form", %{
          "challenge" => %{"configuration" => %{"length_in_games" => "7"}}
        })
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
  end

  describe "Match scoring alerts" do
    test "does not show alert when user has no matches", %{conn: conn} do
      user = user_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      refute html =~ "ready for scoring"
    end

    test "shows alert for pending match with first game needing score", %{conn: conn} do
      user = user_fixture()
      game = %Game{id: "game1", game_number: 1, score_proposals: []}

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      pending_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Game 1 is ready for scoring"
      assert has_element?(lv, "div[role='alert']")
      assert has_element?(lv, "a", "Enter Score")
    end

    test "shows alert for in-progress match when user hasn't scored", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game = %Game{id: "game1", game_number: 2, score_proposals: []}

      in_progress_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Game 2 is ready for scoring"
    end

    test "does not show alert when user has already scored", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      # User has already submitted a score proposal
      score_proposal = %ScoreProposal{
        proposed_by_participant_id: participant1.id,
        scores: [
          %Score{match_participant_id: "p1", score: 11},
          %Score{match_participant_id: "p2", score: 9}
        ]
      }

      game = %Game{id: "game1", game_number: 1, score_proposals: [score_proposal]}

      in_progress_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      refute html =~ "ready for scoring"
    end

    test "does not show alert for complete matches", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game = %Game{id: "game1", game_number: 1, score_proposals: []}

      complete_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      refute html =~ "ready for scoring"
    end

    test "does not show alert for canceled matches", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game = %Game{id: "game1", game_number: 1, score_proposals: []}

      canceled_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      refute html =~ "ready for scoring"
    end

    test "alert contains link to score entry page", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game = %Game{id: "game123", game_number: 1, score_proposals: []}

      match =
        pending_match_fixture(%{
          participants: [participant1, participant2],
          games: [game]
        })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Check that the link points to the correct score entry page
      assert has_element?(
               lv,
               "a[href='/matches/#{match.id}/games/game123/scores/new']",
               "Enter Score"
             )
    end

    test "shows multiple alerts for multiple matches needing scoring", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game1 = %Game{id: "game1", game_number: 1, score_proposals: []}
      game2 = %Game{id: "game2", game_number: 3, score_proposals: []}

      # Create two matches that need scoring
      pending_match_fixture(%{
        participants: [participant1, participant2],
        games: [game1]
      })

      in_progress_match_fixture(%{
        participants: [participant1, participant2],
        games: [game2]
      })

      {:ok, lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      assert html =~ "Game 1 is ready for scoring"
      assert html =~ "Game 3 is ready for scoring"

      # Should have alert elements with role="alert"
      assert has_element?(lv, "div[role='alert']")

      # Both links should be present
      assert has_element?(lv, "a", "Enter Score")
    end

    test "does not show alert for matches where user is not a participant", %{conn: conn} do
      user = user_fixture()
      other_user_id = user.id + 100

      participant1 = %Participant{
        id: "p1",
        user_id: other_user_id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: other_user_id + 1,
        participant_number: 2
      }

      game = %Game{id: "game1", game_number: 1, score_proposals: []}

      pending_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      refute html =~ "ready for scoring"
    end

    test "alert has proper accessibility attributes", %{conn: conn} do
      user = user_fixture()

      participant1 = %Participant{
        id: "p1",
        user_id: user.id,
        participant_number: 1
      }

      participant2 = %Participant{
        id: "p2",
        user_id: user.id + 1,
        participant_number: 2
      }

      game = %Game{id: "game1", game_number: 1, score_proposals: []}

      pending_match_fixture(%{
        participants: [participant1, participant2],
        games: [game]
      })

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/dashboard")

      # Alert should have role="alert" attribute
      assert has_element?(lv, "div[role='alert']")
    end
  end
end
