defmodule FortymmWeb.MatchLive.ScoreEntry do
  use FortymmWeb, :live_view

  alias Fortymm.Accounts
  alias Fortymm.Matches
  alias Fortymm.Matches.ScoreEntry

  @impl true
  def mount(%{"match_id" => match_id, "id" => game_id}, _session, socket) do
    with {:ok, match} <- Matches.get_match(match_id),
         game when not is_nil(game) <- Enum.find(match.games, &(&1.id == game_id)) do
      current_user_id = socket.assigns.current_scope.user.id
      opponent = find_opponent(match, current_user_id)

      opponent_username =
        if opponent, do: Accounts.get_user!(opponent.user_id).username, else: "opponent"

      # Subscribe to match updates so we're notified when the opponent enters a score
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Fortymm.PubSub, "match:#{match_id}")
      end

      {:ok,
       socket
       |> assign(:match, match)
       |> assign(:game, game)
       |> assign(:opponent_username, opponent_username)
       |> assign(:page_title, "Enter Score")
       |> assign(:form, build_form(game_id))}
    else
      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Match not found")
         |> push_navigate(to: ~p"/dashboard")}

      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  defp find_opponent(match, current_user_id) do
    Enum.find(match.participants, fn p -> p.user_id != current_user_id end)
  end

  defp build_form(game_id) do
    ScoreEntry.changeset(%ScoreEntry{}, %{game_id: game_id})
    |> to_form()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <style>
        input[type="number"]::-webkit-inner-spin-button,
        input[type="number"]::-webkit-outer-spin-button {
          -webkit-appearance: none;
          margin: 0;
        }
        input[type="number"] {
          -moz-appearance: textfield;
        }
      </style>

      <div class="container mx-auto max-w-md py-8 px-4">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Enter Score</h2>
            <p class="text-sm opacity-70">
              <%= case @game.game_number do %>
                <% 1 -> %>
                  Enter the score for your first game against {@opponent_username}
                <% n -> %>
                  Enter the score for game {n} against {@opponent_username}
              <% end %>
            </p>

            <.form
              for={@form}
              id="score-form"
              phx-submit="save"
              phx-change="validate"
              class="space-y-4"
            >
              <input type="hidden" name="score_entry[game_id]" value={@game.id} />

              <%!-- Display form-level errors --%>
              <div
                :if={has_errors?(@form)}
                class="alert alert-error"
                role="alert"
                phx-no-format
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="stroke-current shrink-0 h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <div>
                  <div :for={{field, errors} <- @form.errors} class="text-sm">
                    <%= for error <- errors do %>
                      <div>{Phoenix.Naming.humanize(field)}: {translate_error(error)}</div>
                    <% end %>
                  </div>
                  <%!-- Display nested errors from score_proposal --%>
                  <div :if={has_score_proposal_errors?(@form)} class="text-sm">
                    <div>{get_score_proposal_error_message(@form)}</div>
                  </div>
                </div>
              </div>

              <%= for {participant, index} <- Enum.with_index(@match.participants) do %>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Player {participant.participant_number}</span>
                  </label>

                  <input
                    type="hidden"
                    name={"score_entry[score_proposal][scores][#{index}][match_participant_id]"}
                    value={participant.id}
                  />

                  <input
                    type="number"
                    name={"score_entry[score_proposal][scores][#{index}][score]"}
                    placeholder="0"
                    min="0"
                    value={get_score_value(@form, index)}
                    class={[
                      "input input-bordered",
                      has_score_error?(@form, index) && "input-error"
                    ]}
                  />
                  <label :if={has_score_error?(@form, index)} class="label">
                    <span class="label-text-alt text-error">
                      {get_score_error(@form, index)}
                    </span>
                  </label>
                </div>
              <% end %>

              <div class="card-actions justify-end pt-4">
                <.link navigate={~p"/matches/#{@match.id}"} class="btn btn-ghost">
                  Cancel
                </.link>
                <button type="submit" class="btn btn-primary">
                  Save
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({:match_updated, updated_match}, socket) do
    # When the opponent enters a score, check if we need to redirect
    # If the match was updated (opponent entered score), re-fetch and potentially redirect
    if match_updated?(socket.assigns.match, updated_match) do
      # Reload the current game in case it was updated
      current_game_id = socket.assigns.game.id
      updated_game = Enum.find(updated_match.games, &(&1.id == current_game_id))

      {:noreply,
       socket
       |> assign(:match, updated_match)
       |> assign(:game, updated_game)
       |> put_flash(:info, "Your opponent entered a score!")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"score_entry" => params}, socket) do
    params_with_proposer = add_proposer(params, socket)

    changeset =
      ScoreEntry.changeset_with_game(%ScoreEntry{}, params_with_proposer, socket.assigns.game)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"score_entry" => params}, socket) do
    params_with_proposer = add_proposer(params, socket)

    changeset =
      ScoreEntry.changeset_with_game_for_submission(
        %ScoreEntry{},
        params_with_proposer,
        socket.assigns.game
      )

    if changeset.valid? do
      match = socket.assigns.match
      score_entry = Ecto.Changeset.apply_changes(changeset)

      # Store the score proposal in the game
      game_with_score =
        add_score_proposal_to_game(socket.assigns.game, score_entry.score_proposal)

      match_with_updated_game = update_game_in_match(match, game_with_score)

      # Update match status based on game state
      match_with_status = update_match_status(match_with_updated_game)

      # Update the match in storage
      Matches.MatchStore.insert(match.id, match_with_status)

      # Broadcast the match update to other players subscribed to this match
      Phoenix.PubSub.broadcast(
        Fortymm.PubSub,
        "match:#{match.id}",
        {:match_updated, match_with_status}
      )

      handle_score_saved(socket, match_with_status)
    else
      {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate)))}
    end
  end

  defp handle_score_saved(socket, match_with_updated_game) do
    if match_winner_determined?(match_with_updated_game) do
      # Match is over, redirect to match details
      {:noreply,
       socket
       |> put_flash(:info, "Score saved! Match complete!")
       |> push_navigate(to: ~p"/matches/#{match_with_updated_game.id}")}
    else
      # Create next game and redirect to score entry for it
      handle_next_game(socket, match_with_updated_game)
    end
  end

  defp handle_next_game(socket, match_with_updated_game) do
    case create_next_game(match_with_updated_game) do
      {:ok, next_game, updated_match} ->
        Matches.MatchStore.insert(match_with_updated_game.id, updated_match)

        {:noreply,
         socket
         |> put_flash(:info, "Score saved! Starting next game...")
         |> push_navigate(
           to: ~p"/matches/#{match_with_updated_game.id}/games/#{next_game.id}/scores/new"
         )}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create next game")
         |> push_navigate(to: ~p"/matches/#{match_with_updated_game.id}")}
    end
  end

  defp add_proposer(params, socket) do
    current_user_id = socket.assigns.current_scope.user.id

    # Find the participant that matches the current user
    participant =
      Enum.find(socket.assigns.match.participants, fn p ->
        p.user_id == current_user_id
      end)

    if participant do
      params
      |> Map.put("score_proposal", params["score_proposal"] || %{})
      |> put_in(["score_proposal", "proposed_by_participant_id"], participant.id)
    else
      params
    end
  end

  defp has_errors?(form) do
    form.errors != [] || has_score_proposal_errors?(form)
  end

  defp has_score_proposal_errors?(form) do
    case form.source.changes[:score_proposal] do
      changeset when is_map(changeset) and changeset.errors != [] ->
        true

      _ ->
        false
    end
  end

  defp get_score_proposal_error_message(form) do
    case form.source.changes[:score_proposal] do
      changeset when is_map(changeset) and changeset.errors != [] ->
        Enum.map_join(changeset.errors, "; ", fn {field, {msg, _opts}} ->
          "#{Phoenix.Naming.humanize(field)}: #{msg}"
        end)

      _ ->
        ""
    end
  end

  defp has_score_error?(form, index) do
    case form.source.changes[:score_proposal] do
      %{changes: %{scores: scores}} when is_list(scores) ->
        case Enum.at(scores, index) do
          changeset when is_map(changeset) and changeset.errors != [] -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  defp get_score_error(form, index) do
    with %{changes: %{scores: scores}} when is_list(scores) <-
           form.source.changes[:score_proposal],
         changeset when is_map(changeset) and changeset.errors != [] <- Enum.at(scores, index) do
      Enum.map_join(changeset.errors, "; ", fn {_field, {msg, _opts}} -> msg end)
    else
      _ -> ""
    end
  end

  defp get_score_value(form, index) do
    case form.source.changes[:score_proposal] do
      %{changes: %{scores: scores}} when is_list(scores) ->
        case Enum.at(scores, index) do
          changeset when is_map(changeset) ->
            Ecto.Changeset.get_field(changeset, :score) || ""

          _ ->
            ""
        end

      _ ->
        ""
    end
  end

  defp add_score_proposal_to_game(game, score_proposal) do
    %{game | score_proposals: [score_proposal | game.score_proposals]}
  end

  defp update_game_in_match(match, updated_game) do
    updated_games =
      Enum.map(match.games, fn game ->
        if game.id == updated_game.id, do: updated_game, else: game
      end)

    %{match | games: updated_games}
  end

  defp match_winner_determined?(match) do
    games_won_per_participant = calculate_games_won_per_participant(match)
    required_wins = required_wins_for_match(match.match_configuration.length_in_games)

    Enum.any?(games_won_per_participant, fn {_participant_id, games_won} ->
      games_won >= required_wins
    end)
  end

  defp calculate_games_won_per_participant(match) do
    match.participants
    |> Enum.map(fn participant ->
      games_won = count_games_won(participant, match.games)
      {participant.id, games_won}
    end)
    |> Enum.into(%{})
  end

  defp count_games_won(participant, games) do
    games
    |> Enum.count(fn game -> participant_won_game?(game, participant) end)
  end

  defp participant_won_game?(game, participant) do
    case final_score_proposal(game) do
      nil -> false
      proposal -> participant_won?(participant, proposal)
    end
  end

  defp participant_won?(participant, proposal) do
    Enum.any?(proposal.scores, fn score ->
      score.match_participant_id == participant.id && winner?(score, proposal)
    end)
  end

  defp winner?(score, proposal) do
    player_score = score.score
    opponent_score = get_opponent_score(score, proposal.scores)

    case opponent_score do
      nil -> false
      _ -> wins_by_rules?(player_score, opponent_score)
    end
  end

  defp get_opponent_score(player_score, [score1, score2]) do
    if score1.match_participant_id == player_score.match_participant_id do
      score2.score
    else
      score1.score
    end
  end

  defp get_opponent_score(_player_score, _scores), do: nil

  defp wins_by_rules?(player_score, _opponent_score) when player_score < 11, do: false

  defp wins_by_rules?(_player_score, opponent_score) when opponent_score < 10,
    do: true

  defp wins_by_rules?(player_score, opponent_score),
    do: player_score - opponent_score >= 2

  defp final_score_proposal(game) do
    case game.score_proposals do
      [proposal] -> proposal
      [_ | _] = proposals -> List.last(proposals)
      [] -> nil
    end
  end

  defp required_wins_for_match(length_in_games) do
    # For best-of-3: need 2 wins
    # For best-of-5: need 3 wins
    # Formula: (length_in_games // 2) + 1
    div(length_in_games, 2) + 1
  end

  defp match_updated?(old_match, new_match) do
    # Check if the number of games changed (opponent entered a score)
    Enum.count(old_match.games) != Enum.count(new_match.games)
  end

  defp create_next_game(match) do
    next_game_number = Enum.count(match.games) + 1

    if next_game_number <= match.match_configuration.length_in_games do
      game = %Fortymm.Matches.Game{
        id: generate_id(),
        game_number: next_game_number,
        score_proposals: []
      }

      updated_match = %{match | games: match.games ++ [game]}
      {:ok, game, updated_match}
    else
      {:error, :match_complete}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp update_match_status(match) do
    case match.status do
      "pending" ->
        # First score entered, move to in_progress
        %{match | status: "in_progress"}

      "in_progress" ->
        if match_winner_determined?(match) do
          # Match is complete
          %{match | status: "complete"}
        else
          match
        end

      status ->
        # Keep existing status for canceled, aborted, complete
        %{match | status: status}
    end
  end
end
