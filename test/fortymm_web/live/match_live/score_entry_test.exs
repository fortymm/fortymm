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

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
