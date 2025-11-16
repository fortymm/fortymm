defmodule FortymmWeb.MatchLive.Show do
  use FortymmWeb, :live_view
  alias Fortymm.{Matches, Accounts}
  alias Fortymm.Matches.MatchUpdates

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Matches.get_match(id) do
      {:ok, match} ->
        # Subscribe to match updates for real-time changes
        if connected?(socket) do
          MatchUpdates.subscribe(id)
        end

        socket =
          socket
          |> assign(:match_id, id)
          |> assign(:match, match)
          |> assign(:page_title, "Match Details")
          |> load_participants()

        {:ok, socket}

      {:error, :not_found} ->
        {:ok,
         socket
         |> assign(:match_id, id)
         |> assign(:match, nil)
         |> assign(:page_title, "Match Details")
         |> put_flash(:error, "Match not found")}
    end
  end

  @impl true
  def handle_info({:match_updated, updated_match}, socket) do
    # Refresh the match details with the updated data
    socket =
      socket
      |> assign(:match, updated_match)
      |> load_participants()

    {:noreply, socket}
  end

  defp load_participants(socket) do
    match = socket.assigns.match

    participants_with_users =
      match.participants
      |> Enum.map(fn participant ->
        user = Accounts.get_user!(participant.user_id)
        {participant, user}
      end)

    socket
    |> assign(:participants_with_users, participants_with_users)
    |> compute_match_stats()
  end

  defp compute_match_stats(socket) do
    match = socket.assigns.match
    participants_with_users = socket.assigns.participants_with_users

    games_won = calculate_games_won(match)
    participant_user_map = build_participant_user_map(participants_with_users)

    socket
    |> assign(:games_won, games_won)
    |> assign(:participant_user_map, participant_user_map)
  end

  defp calculate_games_won(match) do
    match.participants
    |> Enum.map(fn participant ->
      games_won_count = count_games_won(participant, match.games)
      {participant.id, games_won_count}
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

  defp build_participant_user_map(participants_with_users) do
    participants_with_users
    |> Enum.into(%{}, fn {participant, user} -> {participant.id, user} end)
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-100 py-8 px-4">
        <div class="max-w-6xl mx-auto">
          <%= if @match do %>
            <%!-- Header --%>
            <div class="mb-6">
              <.link
                navigate={~p"/matches"}
                class="btn btn-ghost btn-sm gap-2"
              >
                <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Matches
              </.link>
            </div>

            <%!-- Match Status Card --%>
            <div class="card bg-base-200 shadow-lg mb-6">
              <div class="card-body">
                <div class="flex items-start justify-between mb-4">
                  <div>
                    <h1 class="card-title text-3xl mb-2">
                      Match {format_match_id(@match.id)}
                    </h1>
                    <p class="text-base-content/70">
                      {String.capitalize(@match.status)} • Best of {@match.match_configuration.length_in_games} games
                    </p>
                  </div>
                  <div class={["badge badge-lg", match_status_badge_class(@match.status)]}>
                    {String.capitalize(@match.status)}
                  </div>
                </div>

                <%!-- Match Score Summary --%>
                <div class="grid grid-cols-2 gap-4 my-4">
                  <%= for {participant, user} <- @participants_with_users do %>
                    <div class="bg-base-100 rounded-lg p-4">
                      <p class="text-sm text-base-content/70 mb-2">
                        Player {participant.participant_number}
                      </p>
                      <div class="flex items-end justify-between">
                        <div>
                          <p class="font-bold">{user.username}</p>
                        </div>
                        <div class="text-right">
                          <p class="text-3xl font-black text-primary">
                            {Map.get(@games_won, participant.id, 0)}
                          </p>
                          <p class="text-xs text-base-content/50">games won</p>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>

                <%!-- Match Progress Bar --%>
                <div class="mt-4">
                  <div class="flex items-center justify-between mb-2">
                    <p class="text-sm font-medium">Match Progress</p>
                    <p class="text-sm text-base-content/70">
                      {Enum.count(@match.games)} of {@match.match_configuration.length_in_games} games
                    </p>
                  </div>
                  <progress
                    class="progress progress-primary w-full"
                    value={
                      if Enum.count(@match.games) == 0,
                        do: 0,
                        else:
                          trunc(
                            Enum.count(@match.games) / @match.match_configuration.length_in_games *
                              100
                          )
                    }
                    max="100"
                  >
                  </progress>
                </div>
              </div>
            </div>

            <%!-- Participants Section --%>
            <div class="card bg-base-200 shadow-lg mb-6">
              <div class="card-body">
                <h2 class="card-title">Participants</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <%= for {participant, user} <- @participants_with_users do %>
                    <div class="bg-base-100 rounded-lg p-4">
                      <div class="flex items-start justify-between mb-4">
                        <div>
                          <p class="text-sm text-base-content/70 mb-1">
                            Player {participant.participant_number}
                          </p>
                          <p class="font-semibold">{user.username}</p>
                        </div>
                        <div class="text-right">
                          <p class="text-2xl font-bold text-primary">
                            {Map.get(@games_won, participant.id, 0)}
                          </p>
                          <p class="text-xs text-base-content/50">games won</p>
                        </div>
                      </div>

                      <%!-- Recent game scores --%>
                      <%= if Enum.any?(@match.games) do %>
                        <div class="mt-4 pt-4 border-t border-base-300">
                          <p class="text-xs font-medium mb-3 uppercase tracking-wide">
                            Recent Games
                          </p>
                          <div class="space-y-2">
                            <%= for game <- Enum.take(@match.games, 3) |> Enum.reverse() do %>
                              <%= if final_score_proposal(game) do %>
                                <div class="flex items-center justify-between text-sm">
                                  <span class="text-base-content/70">Game {game.game_number}</span>
                                  <%= for score <- final_score_proposal(game).scores, score.match_participant_id == participant.id do %>
                                    <div class="flex items-center gap-2">
                                      <span class="font-semibold">{score.score}</span>
                                      <%= if winner?(score, final_score_proposal(game)) do %>
                                        <span class="badge badge-success badge-sm">
                                          W
                                        </span>
                                      <% else %>
                                        <span class="badge badge-error badge-sm">
                                          L
                                        </span>
                                      <% end %>
                                    </div>
                                  <% end %>
                                </div>
                              <% end %>
                            <% end %>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Games Section --%>
            <div class="card bg-base-200 shadow-lg">
              <div class="card-body">
                <div class="flex items-center justify-between mb-4">
                  <h2 class="card-title">Games</h2>
                  <%= if Enum.any?(@match.games) do %>
                    <span class="text-sm text-base-content/70">
                      {Enum.count(@match.games)} of {@match.match_configuration.length_in_games} games
                    </span>
                  <% end %>
                </div>

                <%= if Enum.empty?(@match.games) do %>
                  <div class="text-center py-8 text-base-content/70">
                    <p class="mb-2">No games in this match yet</p>
                    <p class="text-sm">
                      Players can start entering scores once games are created
                    </p>
                  </div>
                <% else %>
                  <div class="space-y-4">
                    <%= for game <- Enum.reverse(@match.games) do %>
                      <div class="bg-base-100 rounded-lg p-4">
                        <div class="flex items-center justify-between mb-4">
                          <div class="flex items-center gap-3">
                            <h3 class="font-semibold">Game {game.game_number}</h3>
                            <%= if game.game_number == Enum.count(@match.games) && has_score_proposal?(game) == false do %>
                              <span class="badge badge-info badge-sm">
                                Current
                              </span>
                            <% end %>
                          </div>
                          <%= if has_score_proposal?(game) do %>
                            <span class="badge badge-success gap-1">
                              <.icon name="hero-check" class="w-3 h-3" /> Completed
                            </span>
                          <% else %>
                            <span class="badge badge-warning gap-1">
                              <.icon name="hero-clock" class="w-3 h-3" /> Pending
                            </span>
                          <% end %>
                        </div>

                        <%= if has_score_proposal?(game) do %>
                          <%!-- Display the winning score proposal --%>
                          <%= if final_score_proposal(game) do %>
                            <div class="bg-base-200 rounded-lg p-4 mb-4">
                              <%= for score <- final_score_proposal(game).scores do %>
                                <div class="flex items-center justify-between mb-2 last:mb-0">
                                  <%= for {participant, user} <- @participants_with_users, participant.id == score.match_participant_id do %>
                                    <div class="flex items-center gap-3">
                                      <span>{user.username}</span>
                                      <%= if winner?(score, final_score_proposal(game)) do %>
                                        <span class="badge badge-success badge-outline">Winner</span>
                                      <% end %>
                                    </div>
                                    <span class="text-2xl font-bold">{score.score}</span>
                                  <% end %>
                                </div>
                              <% end %>
                            </div>
                          <% end %>

                          <%!-- Display score proposals --%>
                          <%= if Enum.count(game.score_proposals) > 1 do %>
                            <details class="mt-2">
                              <summary class="cursor-pointer text-sm font-medium hover:text-primary">
                                All proposals ({Enum.count(game.score_proposals)})
                              </summary>
                              <div class="mt-3 space-y-3">
                                <%= for proposal <- game.score_proposals do %>
                                  <div class="bg-base-200 rounded-lg p-3">
                                    <%= for {participant, user} <- @participants_with_users, participant.id == proposal.proposed_by_participant_id do %>
                                      <p class="text-xs text-base-content/70 mb-2">
                                        Proposed by {user.username}
                                      </p>
                                    <% end %>
                                    <div class="space-y-1">
                                      <%= for score <- proposal.scores do %>
                                        <div class="flex items-center justify-between text-sm">
                                          <%= for {participant, user} <- @participants_with_users, participant.id == score.match_participant_id do %>
                                            <span class="text-base-content/70">{user.username}</span>
                                            <span class="font-semibold">{score.score}</span>
                                          <% end %>
                                        </div>
                                      <% end %>
                                    </div>
                                  </div>
                                <% end %>
                              </div>
                            </details>
                          <% end %>
                        <% else %>
                          <div class="flex items-center justify-between">
                            <p class="text-sm text-base-content/70">Waiting for score entry...</p>
                            <.link
                              navigate={~p"/matches/#{@match.id}/games/#{game.id}/scores/new"}
                              class="btn btn-primary btn-sm gap-1"
                            >
                              <.icon name="hero-plus" class="w-4 h-4" /> Enter Score
                            </.link>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="card bg-base-200 shadow-lg text-center">
              <div class="card-body">
                <h1 class="card-title justify-center text-3xl mb-4">Match Not Found</h1>
                <p class="mb-6 text-base-content/70">The match you're looking for doesn't exist.</p>
                <.link
                  navigate={~p"/matches"}
                  class="btn btn-primary gap-1 w-fit mx-auto"
                >
                  <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to Matches
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp match_status_badge_class(status) do
    case status do
      "pending" -> "badge-warning"
      "in_progress" -> "badge-info"
      "complete" -> "badge-success"
      "canceled" -> "badge-error"
      "aborted" -> "badge-error"
      _ -> "badge-neutral"
    end
  end

  defp format_match_id(id) do
    String.slice(id, 0..7)
  end

  defp has_score_proposal?(game) do
    Enum.any?(game.score_proposals)
  end

  defp final_score_proposal(game) do
    case game.score_proposals do
      [proposal] -> proposal
      [_ | _] = proposals -> List.last(proposals)
      [] -> nil
    end
  end
end
