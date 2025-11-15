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
    MatchStore,
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
    with {:ok, challenge} <- get_challenge(challenge_id),
         {:ok, match} <- Creation.from_challenge(challenge, acceptor_id),
         {:ok, _updated_challenge} <-
           update_challenge(challenge_id, %{status: "accepted", match_id: match.id}) do
      {:ok, match}
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

  @doc """
  Gets a match by ID from ETS.

  Returns `{:ok, match}` if found.
  Returns `{:error, :not_found}` if not found.

  ## Examples

      iex> get_match("valid-id")
      {:ok, %Match{}}

      iex> get_match("invalid-id")
      {:error, :not_found}

  """
  def get_match(id) do
    MatchStore.get(id)
  end

  @doc """
  Lists matches with filtering, sorting, and pagination.

  ## Options

    * `:page` - Page number (defaults to 1, minimum 1)
    * `:per_page` - Items per page (defaults to 20)
    * `:sort_by` - Field to sort by (defaults to :id)
    * `:sort_order` - Sort direction (:asc or :desc, defaults to :asc)
    * `:search` - Search term for match IDs (case-insensitive substring match)
    * `:status` - Filter by match status

  ## Examples

      iex> list_matches(page: 1, per_page: 20)
      %{matches: [...], total: 42, page: 1, per_page: 20, total_pages: 3}

      iex> list_matches(search: "abc", status: "complete")
      %{matches: [...], total: 5, ...}

  """
  def list_matches(opts \\ []) do
    page = max(Keyword.get(opts, :page, 1), 1)
    per_page = Keyword.get(opts, :per_page, 20)
    sort_by = Keyword.get(opts, :sort_by, :id)
    sort_order = Keyword.get(opts, :sort_order, :asc)
    search = Keyword.get(opts, :search)
    status = Keyword.get(opts, :status)

    all_matches = MatchStore.list_all()

    matches =
      all_matches
      |> apply_search_filter(search)
      |> apply_status_filter(status)
      |> apply_sort(sort_by, sort_order)

    total = length(matches)
    total_pages = max(ceil(total / per_page), 1)

    paginated_matches =
      matches
      |> Enum.drop((page - 1) * per_page)
      |> Enum.take(per_page)

    %{
      matches: paginated_matches,
      total: total,
      page: page,
      per_page: per_page,
      total_pages: total_pages
    }
  end

  defp apply_search_filter(matches, nil), do: matches
  defp apply_search_filter(matches, ""), do: matches

  defp apply_search_filter(matches, search) when is_binary(search) do
    search_lower = String.downcase(search)

    Enum.filter(matches, fn match ->
      match.id && String.contains?(String.downcase(match.id), search_lower)
    end)
  end

  defp apply_status_filter(matches, nil), do: matches
  defp apply_status_filter(matches, ""), do: matches

  defp apply_status_filter(matches, status) when is_binary(status) do
    Enum.filter(matches, fn match ->
      match.status == status
    end)
  end

  defp apply_sort(matches, sort_by, sort_order)
       when sort_by in [:id, :status] and sort_order in [:asc, :desc] do
    matches
    |> Enum.sort_by(
      fn match ->
        case sort_by do
          :id -> match.id || ""
          :status -> match.status || ""
        end
      end,
      sort_order
    )
  end

  defp apply_sort(matches, _sort_by, _sort_order) do
    Enum.sort_by(matches, & &1.id, :asc)
  end

  @doc """
  Gets matches that need scoring for a given user.

  Returns matches where:
  - The user is a participant
  - The match is not complete, canceled, or aborted
  - There's a current game that needs the user's score

  ## Examples

      iex> get_matches_needing_scoring(1)
      [%Match{id: "...", status: "in_progress", ...}]

  """
  def get_matches_needing_scoring(user_id) do
    MatchStore.list_all()
    |> Enum.filter(fn match ->
      user_is_participant?(match, user_id) &&
        match_is_active?(match) &&
        has_game_needing_score?(match, user_id)
    end)
  end

  defp user_is_participant?(match, user_id) do
    Enum.any?(match.participants, fn participant ->
      participant.user_id == user_id
    end)
  end

  defp match_is_active?(match) do
    match.status in ["pending", "in_progress"]
  end

  defp has_game_needing_score?(match, user_id) do
    # Find the participant for this user
    participant =
      Enum.find(match.participants, fn p ->
        p.user_id == user_id
      end)

    if participant do
      # Check if there's a current game without the user's score
      current_game = List.last(match.games)

      if current_game do
        user_has_not_scored?(current_game, participant.id)
      else
        # No games yet, match needs first game score
        true
      end
    else
      false
    end
  end

  defp user_has_not_scored?(game, participant_id) do
    # Check if user has already submitted a score proposal for this game
    not Enum.any?(game.score_proposals, fn proposal ->
      proposal.proposed_by_participant_id == participant_id
    end)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
