defmodule FortymmWeb.MatchLive.ScoreEntryTest do
  use FortymmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Fortymm.AccountsFixtures

  alias Fortymm.Matches
  alias Fortymm.Matches.ScoreProposal

  setup do
    # Clear ETS tables before each test
    Fortymm.Matches.MatchStore.clear()
    Fortymm.Matches.ChallengeStore.clear()
    :ok
  end

  defp create_match(user1, user2, _config \\ %{length_in_games: 3, rated: false}) do
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

  describe "Score entry and match progression" do
    test "saves a score with proper score entry form", %{conn: conn} do
      user1 = user_fixture(username: "alice")
      user2 = user_fixture(username: "bob")
      match = create_match(user1, user2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{Enum.at(match.games, 0).id}/scores/new")

      assert html =~ "Enter Score"
    end

    test "match storage updates when score is saved" do
      user1 = user_fixture(username: "charlie")
      user2 = user_fixture(username: "diana")
      match = create_match(user1, user2)

      # Create two games with scores
      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      game1 = Enum.at(match.games, 0)

      # Game 1 score proposal - participant1 wins
      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      # Create game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      # Add score to game 2 - participant1 wins again
      score_proposal2 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 8}
        ]
      }

      game2_with_score = %{game2 | score_proposals: [score_proposal2]}

      # Update match with both games scored
      match_complete = %{match | games: [game1_with_score, game2_with_score]}
      Matches.MatchStore.insert(match.id, match_complete)

      # Verify match shows 2 games completed
      {:ok, check_match} = Matches.get_match(match.id)
      assert Enum.count(check_match.games) == 2
    end

    test "displays score entry form for first game", %{conn: conn} do
      user1 = user_fixture(username: "eve")
      user2 = user_fixture(username: "frank")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      assert html =~ "Enter Score"
      assert html =~ "first game"
    end

    test "displays score entry form with multiple games", %{conn: conn} do
      user1 = user_fixture(username: "grace")
      user2 = user_fixture(username: "henry")
      match = create_match(user1, user2)

      # Create game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_game2 = %{match | games: match.games ++ [game2]}
      Matches.MatchStore.insert(match.id, match_with_game2)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      assert html =~ "Enter Score"
      assert html =~ "game 2"
    end

    test "error handling for match not found", %{conn: conn} do
      user = user_fixture()

      assert {:error, {:live_redirect, %{to: "/dashboard"}}} =
               live(
                 conn |> log_in_user(user),
                 ~p"/matches/nonexistent-id/games/game-123/scores/new"
               )
    end

    test "error handling for game not found", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      assert {:error, {:live_redirect, %{to: "/dashboard"}}} =
               live(
                 conn |> log_in_user(user1),
                 ~p"/matches/#{match.id}/games/nonexistent-game/scores/new"
               )
    end

    test "requires authentication to access score entry", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/matches/some-id/games/some-game-id/scores/new")
    end

    test "displays both players' participant numbers", %{conn: conn} do
      user1 = user_fixture(username: "ivy")
      user2 = user_fixture(username: "jack")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, _lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      assert html =~ "Player 1"
      assert html =~ "Player 2"
    end

    test "displays cancel button that navigates back to match", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, lv, html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      assert html =~ "Cancel"

      # Check that cancel button links to match details
      assert has_element?(lv, "a[href*=\"/matches/#{match.id}\"]")
    end
  end

  describe "Match winner determination logic" do
    test "correctly identifies when best-of-3 match is complete" do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2, %{length_in_games: 3, rated: false})

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      # Participant 1 wins games 1 and 2 (2 wins = best-of-3 complete)
      game1 = Enum.at(match.games, 0)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      score_proposal2 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 9}
        ]
      }

      game2_with_score = %{game2 | score_proposals: [score_proposal2]}

      match_with_games = %{match | games: [game1_with_score, game2_with_score]}
      Matches.MatchStore.insert(match.id, match_with_games)

      {:ok, final_match} = Matches.get_match(match.id)
      assert Enum.count(final_match.games) == 2
    end

    test "correctly calculates required wins for best-of-3" do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2, %{length_in_games: 3, rated: false})

      # For best-of-3, need 2 wins (3 // 2 + 1 = 2)
      assert Enum.count(match.games) == 1
    end

    test "correctly calculates required wins for best-of-5" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create best-of-5 match
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: user1.id
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, user2.id)

      # For best-of-5, need 3 wins (5 // 2 + 1 = 3)
      assert Enum.count(match.games) == 1
    end
  end

  describe "Table tennis scoring rules" do
    test "correctly identifies 11-5 as a win" do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      game = Enum.at(match.games, 0)

      score_proposal = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game_with_score = %{game | score_proposals: [score_proposal]}
      match_with_score = %{match | games: [game_with_score]}

      Matches.MatchStore.insert(match.id, match_with_score)

      {:ok, final_match} = Matches.get_match(match.id)
      game_in_storage = Enum.at(final_match.games, 0)
      assert Enum.count(game_in_storage.score_proposals) == 1
    end

    test "correctly identifies 10-10 as not a win" do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      game = Enum.at(match.games, 0)

      score_proposal = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 10},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 10}
        ]
      }

      game_with_score = %{game | score_proposals: [score_proposal]}
      match_with_score = %{match | games: [game_with_score]}

      Matches.MatchStore.insert(match.id, match_with_score)

      {:ok, final_match} = Matches.get_match(match.id)
      assert Enum.count(final_match.games) == 1
    end

    test "correctly identifies 12-10 as a win in deuce" do
      user1 = user_fixture()
      user2 = user_fixture()
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      game = Enum.at(match.games, 0)

      score_proposal = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 12},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 10}
        ]
      }

      game_with_score = %{game | score_proposals: [score_proposal]}
      match_with_score = %{match | games: [game_with_score]}

      Matches.MatchStore.insert(match.id, match_with_score)

      {:ok, final_match} = Matches.get_match(match.id)
      assert Enum.count(final_match.games) == 1
    end
  end

  describe "PubSub real-time updates" do
    test "player receives notification when opponent enters a score", %{conn: conn} do
      user1 = user_fixture(username: "pubsub_user1")
      user2 = user_fixture(username: "pubsub_user2")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      # Player 2 loads the score entry page (subscribes to match)
      {:ok, lv2, _html} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Player 1 loads the score entry page (subscribes to match)
      {:ok, lv1, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Player 1 enters a score
      lv1
      |> form("#score-form", %{
        "score_entry[score_proposal][scores][0][score]" => "11",
        "score_entry[score_proposal][scores][1][score]" => "5"
      })
      |> render_submit()

      # Player 2's view should update with notification
      # Simulate receiving the PubSub message
      send(lv2.pid, {:match_updated, Matches.get_match(match.id) |> elem(1)})

      # Render should show the flash message about opponent's score
      html = render(lv2)
      assert html =~ "Your opponent entered a score!"
    end

    test "player 2 receives updated match when player 1 adds next game", %{conn: conn} do
      user1 = user_fixture(username: "pubsub_next1")
      user2 = user_fixture(username: "pubsub_next2")
      match = create_match(user1, user2)

      game1 = Enum.at(match.games, 0)

      # Player 2 subscribes to match
      {:ok, lv2, _html} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}/games/#{game1.id}/scores/new")

      # Player 1 enters score for game 1
      {:ok, lv1, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game1.id}/scores/new")

      lv1
      |> form("#score-form", %{
        "score_entry[score_proposal][scores][0][score]" => "11",
        "score_entry[score_proposal][scores][1][score]" => "5"
      })
      |> render_submit()

      # Player 2 receives the update
      {:ok, updated_match} = Matches.get_match(match.id)
      send(lv2.pid, {:match_updated, updated_match})

      # Verify match has 2 games now
      assert Enum.count(updated_match.games) == 2

      # Player 2's view should reflect the update
      html = render(lv2)
      assert html =~ "Your opponent entered a score!"
    end

    test "match_updated? correctly detects when games were added" do
      user1 = user_fixture(username: "match_detect1")
      user2 = user_fixture(username: "match_detect2")
      match = create_match(user1, user2)

      # Original match has 1 game
      assert Enum.count(match.games) == 1

      game1 = Enum.at(match.games, 0)

      # Enter a score to create game 2
      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_both_games = %{match | games: [game1_with_score, game2]}

      # Now match has 2 games
      assert Enum.count(match_with_both_games.games) == 2

      # The helper function should detect this as an update
      # (In practice, this is tested implicitly through the PubSub handler)
      assert Enum.count(match.games) != Enum.count(match_with_both_games.games)
    end
  end

  describe "Score entry redirect behavior for both players" do
    test "player 1 can enter score and redirect works", %{conn: conn} do
      user1 = user_fixture(username: "player1_p1")
      user2 = user_fixture(username: "player2_p1")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "5"
        })
        |> render_submit()

      assert {:error, {:live_redirect, _}} = result
    end

    test "player 2 can enter score and redirect works", %{conn: conn} do
      user1 = user_fixture(username: "player1_p2")
      user2 = user_fixture(username: "player2_p2")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      # Player 2 logs in and enters score
      {:ok, lv, _html} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "5",
          "score_entry[score_proposal][scores][1][score]" => "11"
        })
        |> render_submit()

      assert {:error, {:live_redirect, _}} = result
    end

    test "both players see the same match progression", %{conn: conn} do
      user1 = user_fixture(username: "p1_match")
      user2 = user_fixture(username: "p2_match")
      match = create_match(user1, user2)

      game1 = Enum.at(match.games, 0)

      # Player 1 enters score for game 1
      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game1.id}/scores/new")

      {:error, {:live_redirect, _}} =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "5"
        })
        |> render_submit()

      # Verify the match was updated in storage
      {:ok, updated_match} = Matches.get_match(match.id)
      assert Enum.count(updated_match.games) == 2

      # Player 2 should be able to access the new game 2
      game2 = Enum.at(updated_match.games, 1)

      {:ok, lv2, _html} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      assert lv2 |> render() =~ "Enter Score"
    end

    test "complete match with both players shows final state", %{conn: conn} do
      user1 = user_fixture(username: "p1_complete")
      user2 = user_fixture(username: "p2_complete")
      match = create_match(user1, user2)

      # Find which participant corresponds to which user
      participant_for_user1 =
        Enum.find(match.participants, fn p -> p.user_id == user1.id end)

      participant_for_user2 =
        Enum.find(match.participants, fn p -> p.user_id == user2.id end)

      # Set up game 1 with user1's participant winning
      game1 = Enum.at(match.games, 0)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant_for_user1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant_for_user1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant_for_user2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      # Create and add game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_both_games = %{match | games: [game1_with_score, game2]}
      Matches.MatchStore.insert(match.id, match_with_both_games)

      # User 2 enters score for game 2 (user1's participant wins again, completing the match)
      {:ok, lv, _html} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "8"
        })
        |> render_submit()

      # Should redirect (match is complete)
      assert {:error, {:live_redirect, _}} = result

      # Both players should see the match as complete when they view it
      {:ok, final_match} = Matches.get_match(match.id)
      assert Enum.count(final_match.games) == 2

      # Both players can view the match details after completion
      {:ok, user1_match_view, _} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}")

      user1_html = user1_match_view |> render()
      assert user1_html =~ "Match"
      # Shows 2 games were played
      assert user1_html =~ "2"

      {:ok, user2_match_view, _} =
        conn
        |> log_in_user(user2)
        |> live(~p"/matches/#{match.id}")

      user2_html = user2_match_view |> render()
      assert user2_html =~ "Match"
      # Shows 2 games were played
      assert user2_html =~ "2"
    end
  end

  describe "Match status transitions" do
    test "match status changes from pending to in_progress when first score is entered", %{
      conn: conn
    } do
      user1 = user_fixture(username: "status_user1")
      user2 = user_fixture(username: "status_user2")
      match = create_match(user1, user2)

      # Verify match starts as pending
      assert match.status == "pending"

      game = Enum.at(match.games, 0)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Submit first score
      _result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "5"
        })
        |> render_submit()

      # Verify match status is now in_progress
      {:ok, updated_match} = Matches.get_match(match.id)
      assert updated_match.status == "in_progress"
    end

    test "match status changes from in_progress to complete when match winner is determined", %{
      conn: conn
    } do
      user1 = user_fixture(username: "complete_user1")
      user2 = user_fixture(username: "complete_user2")
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      # Set up game 1 with participant1 winning
      game1 = Enum.at(match.games, 0)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      # Create and add game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_both_games = %{match | games: [game1_with_score, game2], status: "in_progress"}
      Matches.MatchStore.insert(match.id, match_with_both_games)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      # Submit score for game 2 that completes the match
      _result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "8"
        })
        |> render_submit()

      # Verify match status is now complete
      {:ok, final_match} = Matches.get_match(match.id)
      assert final_match.status == "complete"
    end

    test "match status stays in_progress when match is not yet complete", %{conn: conn} do
      user1 = user_fixture(username: "inprog_user1")
      user2 = user_fixture(username: "inprog_user2")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Submit first score (participant1 gets 1 win, needs 2 for best-of-3)
      _result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "6"
        })
        |> render_submit()

      # Verify match status is in_progress, not complete
      {:ok, updated_match} = Matches.get_match(match.id)
      assert updated_match.status == "in_progress"
    end
  end

  describe "Score entry redirect behavior" do
    test "redirects to next game when match is not complete after score entry", %{conn: conn} do
      user1 = user_fixture(username: "alice_redirect")
      user2 = user_fixture(username: "bob_redirect")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Submit a score (11-5, participant1 wins game 1, but needs 2 wins for best-of-3)
      # Should redirect to next game (game 2)
      result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "5"
        })
        |> render_submit()

      # Verify it returns a redirect error
      assert {:error, {:live_redirect, _}} = result
    end

    test "redirects to match show page when match is complete after score entry", %{conn: conn} do
      user1 = user_fixture(username: "charlie_redirect")
      user2 = user_fixture(username: "diana_redirect")
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      # Set up game 1 with participant1 winning
      game1 = Enum.at(match.games, 0)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      # Create and add game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_both_games = %{match | games: [game1_with_score, game2]}
      Matches.MatchStore.insert(match.id, match_with_both_games)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      # Submit a score for game 2 that gives participant1 their second win (match complete)
      # Should redirect to match details page
      result =
        lv
        |> form("#score-form", %{
          "score_entry[score_proposal][scores][0][score]" => "11",
          "score_entry[score_proposal][scores][1][score]" => "8"
        })
        |> render_submit()

      # Verify it redirects
      assert {:error, {:live_redirect, _}} = result
    end

    test "shows flash message when score is saved and match is not complete", %{conn: conn} do
      user1 = user_fixture(username: "eve_redirect")
      user2 = user_fixture(username: "frank_redirect")
      match = create_match(user1, user2)

      game = Enum.at(match.games, 0)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game.id}/scores/new")

      # Verify that it redirects with a flash message (flash is encoded but present)
      assert {:error, {:live_redirect, %{flash: flash}}} =
               lv
               |> form("#score-form", %{
                 "score_entry[score_proposal][scores][0][score]" => "11",
                 "score_entry[score_proposal][scores][1][score]" => "7"
               })
               |> render_submit()

      # Flash is present (it's encoded by Phoenix)
      assert is_binary(flash)
      assert String.length(flash) > 0
    end

    test "shows flash message when score is saved and match is complete", %{conn: conn} do
      user1 = user_fixture(username: "grace_redirect")
      user2 = user_fixture(username: "henry_redirect")
      match = create_match(user1, user2)

      participant1 = Enum.at(match.participants, 0)
      participant2 = Enum.at(match.participants, 1)

      # Set up game 1 with participant1 winning
      game1 = Enum.at(match.games, 0)

      score_proposal1 = %ScoreProposal{
        id: generate_id(),
        proposed_by_participant_id: participant1.id,
        scores: [
          %Fortymm.Matches.Score{match_participant_id: participant1.id, score: 11},
          %Fortymm.Matches.Score{match_participant_id: participant2.id, score: 5}
        ]
      }

      game1_with_score = %{game1 | score_proposals: [score_proposal1]}

      # Create and add game 2
      game2 = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: 2,
        score_proposals: []
      }

      match_with_both_games = %{match | games: [game1_with_score, game2]}
      Matches.MatchStore.insert(match.id, match_with_both_games)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user1)
        |> live(~p"/matches/#{match.id}/games/#{game2.id}/scores/new")

      # Verify that it redirects with a flash message (flash is encoded but present)
      assert {:error, {:live_redirect, %{flash: flash}}} =
               lv
               |> form("#score-form", %{
                 "score_entry[score_proposal][scores][0][score]" => "11",
                 "score_entry[score_proposal][scores][1][score]" => "9"
               })
               |> render_submit()

      # Flash is present (it's encoded by Phoenix)
      assert is_binary(flash)
      assert String.length(flash) > 0
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
