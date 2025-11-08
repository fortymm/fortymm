defmodule Fortymm.Matches do
  @moduledoc """
  The Matches context.
  """

  alias Fortymm.Matches.{
    Challenge,
    ChallengeCancellation,
    ChallengeRejection,
    ChallengeStore,
    ChallengeUpdates,
    Creation,
    Status
  }

  @doc """
  Creates a changeset for a Challenge.

  ## Examples

      iex> challenge_changeset(%{configuration: %{length_in_games: 3}})
      %Ecto.Changeset{valid?: true}

      iex> challenge_changeset(%{configuration: %{length_in_games: 2}})
      %Ecto.Changeset{valid?: false}

  """
  def challenge_changeset(attrs \\ %{}) do
    Challenge.changeset(%Challenge{}, attrs)
  end

  @doc """
  Creates a challenge and stores it in ETS.

  Returns `{:ok, challenge}` if the challenge is valid and stored successfully.
  Returns `{:error, changeset}` if the challenge is invalid.

  ## Examples

      iex> create_challenge(%{configuration: %{length_in_games: 3}})
      {:ok, %Challenge{id: "...", configuration: %{length_in_games: 3}}}

      iex> create_challenge(%{configuration: %{length_in_games: 2}})
      {:error, %Ecto.Changeset{}}

  """
  def create_challenge(attrs) do
    changeset = challenge_changeset(attrs)

    if changeset.valid? do
      challenge = Ecto.Changeset.apply_changes(changeset)
      challenge_with_id = %{challenge | id: generate_id()}

      ChallengeStore.insert(challenge_with_id.id, challenge_with_id)
      ChallengeUpdates.broadcast(challenge_with_id)
      {:ok, challenge_with_id}
    else
      {:error, changeset}
    end
  end

  @doc """
  Gets a challenge by ID from ETS.

  Returns `{:ok, challenge}` if found.
  Returns `{:error, :not_found}` if not found.

  ## Examples

      iex> get_challenge("valid-id")
      {:ok, %Challenge{}}

      iex> get_challenge("invalid-id")
      {:error, :not_found}

  """
  def get_challenge(id) do
    ChallengeStore.get(id)
  end

  @doc """
  Lists all challenges from ETS.

  ## Examples

      iex> list_challenges()
      [%Challenge{}, ...]

  """
  def list_challenges do
    ChallengeStore.list_all()
  end

  @doc """
  Updates a challenge by ID in ETS.

  Returns `{:ok, challenge}` if the challenge exists and update is valid.
  Returns `{:error, :not_found}` if the challenge doesn't exist.
  Returns `{:error, changeset}` if the update is invalid.

  ## Examples

      iex> update_challenge("valid-id", %{status: "accepted"})
      {:ok, %Challenge{}}

      iex> update_challenge("invalid-id", %{status: "accepted"})
      {:error, :not_found}

  """
  def update_challenge(id, attrs) do
    case get_challenge(id) do
      {:ok, challenge} ->
        changeset = Challenge.changeset(challenge, attrs)

        if changeset.valid? do
          updated_challenge = Ecto.Changeset.apply_changes(changeset)
          ChallengeStore.insert(id, updated_challenge)
          ChallengeUpdates.broadcast(updated_challenge)
          {:ok, updated_challenge}
        else
          {:error, changeset}
        end

      {:error, :not_found} = error ->
        error
    end
  end

  @doc """
  Deletes a challenge by ID from ETS.

  ## Examples

      iex> delete_challenge("valid-id")
      :ok

  """
  def delete_challenge(id) do
    ChallengeStore.delete(id)
  end

  @doc """
  Returns the status of a challenge.

  ## Examples

      iex> {:ok, challenge} = get_challenge("valid-id")
      iex> status(challenge)
      :challenge_pending

  """
  def status(%Challenge{} = challenge) do
    Status.for_challenge(challenge)
  end

  @doc """
  Accepts a challenge after validating acceptance rules and creates a match.

  Validates that:
  - The challenge exists
  - The challenge is in "pending" status
  - The acceptor is different from the challenge creator

  Creates a pending match with:
  - The challenge's configuration
  - Two participants: the challenge creator and the acceptor

  Marks the challenge as accepted.

  Returns `{:ok, match}` if validation passes, the match is created, and the challenge is accepted.
  Returns `{:error, :not_found}` if the challenge doesn't exist.
  Returns `{:error, changeset}` if validation fails.

  ## Examples

      iex> accept_challenge("challenge-id", 2)
      {:ok, %Match{status: "pending", participants: [...]}}

      iex> accept_challenge("challenge-id", 1) # same as creator
      {:error, %Ecto.Changeset{}}

  """
  def accept_challenge(challenge_id, acceptor_id) do
    case get_challenge(challenge_id) do
      {:ok, challenge} ->
        case Creation.from_challenge(challenge, acceptor_id) do
          {:ok, match} ->
            case update_challenge(challenge_id, %{status: "accepted"}) do
              {:ok, _updated_challenge} ->
                {:ok, match}

              {:error, _reason} = error ->
                # Match was created but challenge update failed
                # This could happen due to concurrent modifications
                error
            end

          {:error, _changeset} = error ->
            error
        end

      {:error, :not_found} = error ->
        error
    end
  end

  @doc """
  Rejects a challenge after validating rejection rules.

  Validates that:
  - The challenge exists
  - The challenge is in "pending" status
  - The rejector is different from the challenge creator

  Returns `{:ok, challenge}` if validation passes and the challenge is rejected.
  Returns `{:error, :not_found}` if the challenge doesn't exist.
  Returns `{:error, changeset}` if validation fails.

  ## Examples

      iex> reject_challenge("challenge-id", 2)
      {:ok, %Challenge{status: "rejected"}}

      iex> reject_challenge("challenge-id", 1) # same as creator
      {:error, %Ecto.Changeset{}}

  """
  def reject_challenge(challenge_id, rejector_id) do
    case get_challenge(challenge_id) do
      {:ok, challenge} ->
        rejection_changeset =
          ChallengeRejection.changeset(%ChallengeRejection{}, %{
            challenge: challenge,
            rejector_id: rejector_id
          })

        if rejection_changeset.valid? do
          update_challenge(challenge_id, %{status: "rejected"})
        else
          {:error, rejection_changeset}
        end

      {:error, :not_found} = error ->
        error
    end
  end

  @doc """
  Cancels a challenge after validating cancellation rules.

  Validates that:
  - The challenge exists
  - The challenge is in "pending" status
  - The cancellor is the same as the challenge creator

  Returns `{:ok, challenge}` if validation passes and the challenge is cancelled.
  Returns `{:error, :not_found}` if the challenge doesn't exist.
  Returns `{:error, changeset}` if validation fails.

  ## Examples

      iex> cancel_challenge("challenge-id", 1)
      {:ok, %Challenge{status: "cancelled"}}

      iex> cancel_challenge("challenge-id", 2) # different from creator
      {:error, %Ecto.Changeset{}}

  """
  def cancel_challenge(challenge_id, cancellor_id) do
    case get_challenge(challenge_id) do
      {:ok, challenge} ->
        cancellation_changeset =
          ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
            challenge: challenge,
            cancellor_id: cancellor_id
          })

        if cancellation_changeset.valid? do
          update_challenge(challenge_id, %{status: "cancelled"})
        else
          {:error, cancellation_changeset}
        end

      {:error, :not_found} = error ->
        error
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
