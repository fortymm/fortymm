defmodule FortymmWeb.DashboardLive do
  use FortymmWeb, :live_view

  alias Fortymm.Matches

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <div class="grid gap-6">
          <%!-- Match Scoring Alert --%>
          <%= for match <- @matches_needing_scoring do %>
            <div
              role="alert"
              class="flex gap-3 alert alert-info alert-soft"
            >
              <.icon name="hero-pencil-square" />
              <span class="flex-1">
                <%= if match.games != [] do %>
                  <% current_game = List.last(match.games) %> Game {current_game.game_number} is ready for scoring.
                <% else %>
                  Your match is ready! Game 1 needs scoring.
                <% end %>
              </span>
              <div>
                <.link
                  navigate={get_score_entry_path(match)}
                  class="btn btn-sm btn-primary"
                >
                  Enter Score
                </.link>
              </div>
            </div>
          <% end %>

          <%!-- Challenge a Friend Card --%>
          <div class="card border bg-primary/30 border-primary/30">
            <div class="card-body">
              <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
                <div class="text-center sm:text-left">
                  <h2 class="card-title text-2xl mb-2">
                    <.icon name="hero-trophy" class="size-7 text-primary" /> Challenge a Friend
                  </h2>
                  <p class="text-base opacity-90">
                    Ready to put your skills to the test? Challenge a friend and see who comes out on top!
                  </p>
                </div>
                <button
                  class="btn btn-primary btn-lg gap-2 shadow-lg hover:shadow-xl transition-all"
                  onclick="challenge_modal.showModal()"
                >
                  <.icon name="hero-user-plus" class="size-5" /> Challenge a Friend
                </button>
              </div>
            </div>
          </div>

          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl">🚀 Coming Soon!</h2>
              <p class="text-lg">
                We're cooking up something special just for you. Your dashboard will soon be filled with amazing features that'll make your life easier.
              </p>
            </div>
          </div>

          <div class="grid md:grid-cols-3 gap-4">
            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">📊 Analytics</h3>
                <p class="text-sm opacity-75">
                  Track your progress with beautiful charts and insights.
                </p>
              </div>
            </div>

            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">⚡ Quick Actions</h3>
                <p class="text-sm opacity-75">Get things done faster with one-click shortcuts.</p>
              </div>
            </div>

            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">🎯 Personalized</h3>
                <p class="text-sm opacity-75">Everything tailored to your unique workflow.</p>
              </div>
            </div>
          </div>

          <div class="alert bg-primary/10 border-primary/20">
            <div>
              <span class="text-lg">✨</span>
              <span>
                <div class="font-bold">Stay tuned!</div>
                <div class="text-sm opacity-75">
                  We're working around the clock to bring you the best experience.
                </div>
              </span>
            </div>
          </div>
        </div>

        <%!-- Challenge Modal --%>
        <dialog id="challenge_modal" class="modal modal-bottom sm:modal-middle">
          <div class="modal-box max-w-2xl">
            <form method="dialog">
              <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </form>

            <div class="flex items-center gap-3 mb-6">
              <.icon name="hero-trophy" class="size-8 text-primary" />
              <h3 class="text-2xl font-bold">Challenge a Friend</h3>
            </div>

            <.form for={@form} phx-submit="create_challenge" id="challenge-form">
              <.inputs_for :let={config_form} field={@form[:configuration]}>
                <div class="space-y-6">
                  <div>
                    <fieldset class="fieldset">
                      <legend class="fieldset-legend">Match Length</legend>
                      <div class="grid grid-cols-2 gap-3">
                        <input
                          class="btn"
                          type="radio"
                          name={config_form[:length_in_games].name}
                          value="1"
                          aria-label="Just One Game"
                        />
                        <input
                          class="btn"
                          type="radio"
                          name={config_form[:length_in_games].name}
                          value="3"
                          aria-label="Best of 3"
                          checked
                        />
                        <input
                          class="btn"
                          type="radio"
                          name={config_form[:length_in_games].name}
                          value="5"
                          aria-label="Best of 5"
                        />
                        <input
                          class="btn"
                          type="radio"
                          name={config_form[:length_in_games].name}
                          value="7"
                          aria-label="Best of 7"
                        />
                      </div>
                      <%= if config_form[:length_in_games].errors != [] do %>
                        <label class="label">
                          <span class="label-text-alt text-error">
                            {Enum.map(config_form[:length_in_games].errors, fn {msg, _} -> msg end)
                            |> Enum.join(", ")}
                          </span>
                        </label>
                      <% end %>
                    </fieldset>
                  </div>

                  <div>
                    <label class="label cursor-pointer justify-start gap-3">
                      <input
                        type="checkbox"
                        name={config_form[:rated].name}
                        value="true"
                        checked="checked"
                        class="checkbox checkbox-primary"
                      />
                      <span class="label-text font-semibold">Rated</span>
                    </label>
                    <%= if config_form[:rated].errors != [] do %>
                      <label class="label">
                        <span class="label-text-alt text-error">
                          {Enum.map(config_form[:rated].errors, fn {msg, _} -> msg end)
                          |> Enum.join(", ")}
                        </span>
                      </label>
                    <% end %>
                  </div>
                </div>
              </.inputs_for>

              <div class="modal-action">
                <button type="button" class="btn btn-ghost" onclick="challenge_modal.close()">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary gap-2">
                  Create
                </button>
              </div>
            </.form>
          </div>
        </dialog>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = Matches.challenge_changeset() |> to_form()
    current_user_id = socket.assigns.current_scope.user.id
    matches_needing_scoring = Matches.get_matches_needing_scoring(current_user_id)

    socket =
      socket
      |> assign(:active_nav, :dashboard)
      |> assign(:form, form)
      |> assign(:matches_needing_scoring, matches_needing_scoring)

    {:ok, socket}
  end

  @impl true
  def handle_event("create_challenge", %{"challenge" => challenge_params}, socket) do
    challenge_params_with_creator =
      Map.put(challenge_params, "created_by_id", socket.assigns.current_scope.user.id)

    case Matches.create_challenge(challenge_params_with_creator) do
      {:ok, challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge created successfully!")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_score_entry_path(match) do
    # Get the current game (the last game in the list)
    current_game = List.last(match.games)

    if current_game do
      ~p"/matches/#{match.id}/games/#{current_game.id}/scores/new"
    else
      # Fallback to match page if no game exists (shouldn't happen)
      ~p"/matches/#{match.id}"
    end
  end
end
