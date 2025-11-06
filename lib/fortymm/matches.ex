defmodule Fortymm.Matches do
  @moduledoc """
  The Matches context.
  """

  alias Fortymm.Matches.{Challenge, ChallengeStore, ChallengeUpdates, Status}

  @doc """
  Creates a changeset for a Challenge.

  ## Examples

      iex> challenge_changeset(%{length_in_games: 3})
      %Ecto.Changeset{valid?: true}

      iex> challenge_changeset(%{length_in_games: 2})
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

      iex> create_challenge(%{length_in_games: 3})
      {:ok, %Challenge{id: "...", length_in_games: 3}}

      iex> create_challenge(%{length_in_games: 2})
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

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
