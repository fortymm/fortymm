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
      # For now, just show success message
      {:noreply,
       socket
       |> put_flash(:info, "Score saved successfully!")
       |> push_navigate(to: ~p"/matches/#{socket.assigns.match.id}")}
    else
      {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :validate)))}
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
end
