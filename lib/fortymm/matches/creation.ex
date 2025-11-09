defmodule Fortymm.Matches.Creation do
  @moduledoc """
  Functions for creating matches from challenges.
  """

  alias Fortymm.Matches.{
    ChallengeAcceptance,
    Match,
    MatchStore
  }

  @doc """
  Creates a match from a challenge acceptance.

  Validates the acceptance first, then creates:
  - A pending match with the challenge's configuration
  - Two participants: the challenge creator (participant 1) and the acceptor (participant 2)

  Returns `{:ok, match}` if the acceptance is valid and match is created successfully.
  Returns `{:error, changeset}` if the acceptance is invalid or match creation fails validation.

  ## Examples

      iex> challenge = %Challenge{id: "123", created_by_id: 1, status: "pending", configuration: %Configuration{length_in_games: 3}}
      iex> acceptance_attrs = %{challenge: challenge, acceptor_id: 2}
      iex> acceptance = %ChallengeAcceptance{challenge: challenge, acceptor_id: 2}
      iex> from_challenge(acceptance)
      {:ok, %Match{status: "pending", participants: [...]}}

  """
  def from_challenge(challenge, acceptor_id) do
    acceptance_changeset =
      ChallengeAcceptance.changeset(%ChallengeAcceptance{}, %{
        challenge: challenge,
        acceptor_id: acceptor_id
      })

    if acceptance_changeset.valid? do
      acceptance = Ecto.Changeset.apply_changes(acceptance_changeset)
      create_match_from_acceptance(acceptance)
    else
      {:error, acceptance_changeset}
    end
  end

  defp create_match_from_acceptance(%ChallengeAcceptance{} = acceptance) do
    challenge = acceptance.challenge
    acceptor_id = acceptance.acceptor_id

    # Convert configuration struct to map for changeset casting
    configuration_map =
      challenge.configuration
      |> Map.from_struct()
      |> Map.drop([:id])

    match_attrs = %{
      status: "pending",
      match_configuration: configuration_map,
      participants: [
        %{user_id: challenge.created_by_id, participant_number: 1},
        %{user_id: acceptor_id, participant_number: 2}
      ],
      games: [
        %{game_number: 1}
      ]
    }

    changeset = Match.changeset(%Match{}, match_attrs)

    if changeset.valid? do
      match = Ecto.Changeset.apply_changes(changeset)

      # Assign IDs to match and games
      match_with_id = %{match | id: generate_id()}

      games_with_ids =
        Enum.map(match_with_id.games, fn game ->
          %{game | id: generate_id()}
        end)

      match_with_game_ids = %{match_with_id | games: games_with_ids}

      MatchStore.insert(match_with_game_ids.id, match_with_game_ids)
      {:ok, match_with_game_ids}
    else
      {:error, changeset}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
