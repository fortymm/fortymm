defmodule FortymmWeb.ChallengeLive.Show do
  use FortymmWeb, :live_view

  alias Fortymm.Matches

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto">
        <div class="bg-gradient-to-br from-primary/5 via-transparent to-secondary/5 rounded-2xl border border-base-300 shadow-2xl overflow-hidden">
          <%!-- Header --%>
          <div class="bg-gradient-to-r from-primary to-secondary p-8 text-primary-content">
            <div class="flex items-center justify-center gap-4 mb-4">
              <.icon name="hero-trophy" class="size-12" />
              <h1 class="text-4xl font-bold">Challenge Details</h1>
              <.icon name="hero-trophy" class="size-12" />
            </div>
            <p class="text-center text-lg opacity-90">
              You've been challenged! Review the details below.
            </p>
          </div>

          <%!-- Challenge Details --%>
          <div class="p-8 space-y-4">
            <div class="flex justify-between items-center p-5 bg-base-200 rounded-xl border border-base-300 shadow-sm hover:shadow-md transition-shadow">
              <span class="font-semibold text-lg flex items-center gap-2">
                <.icon name="hero-identification" class="size-5 text-primary" /> Challenge ID:
              </span>
              <span class="font-mono text-primary text-lg font-bold">
                {String.slice(@challenge.id, 0..7)}
              </span>
            </div>

            <div class="flex justify-between items-center p-5 bg-base-200 rounded-xl border border-base-300 shadow-sm hover:shadow-md transition-shadow">
              <span class="font-semibold text-lg flex items-center gap-2">
                <.icon name="hero-list-bullet" class="size-5 text-primary" /> Match Length:
              </span>
              <span class="text-lg font-medium">Best of {@challenge.length_in_games}</span>
            </div>

            <div class="flex justify-between items-center p-5 bg-base-200 rounded-xl border border-base-300 shadow-sm hover:shadow-md transition-shadow">
              <span class="font-semibold text-lg flex items-center gap-2">
                <.icon name="hero-chart-bar" class="size-5 text-primary" /> Match Type:
              </span>
              <span class="flex items-center gap-2">
                <%= if @challenge.rated do %>
                  <span class="badge badge-primary badge-lg font-semibold">Rated</span>
                <% else %>
                  <span class="badge badge-ghost badge-lg">Unrated</span>
                <% end %>
              </span>
            </div>
          </div>

          <%!-- Actions --%>
          <div class="p-8 pt-4 flex flex-col sm:flex-row gap-4">
            <.link
              href={~p"/dashboard"}
              class="flex-1 btn btn-outline btn-lg group hover:scale-105 transition-transform"
            >
              <.icon
                name="hero-arrow-left"
                class="size-5 group-hover:-translate-x-1 transition-transform"
              /> Back to Dashboard
            </.link>

            <button
              phx-click="decline_challenge"
              class="flex-1 btn btn-error btn-outline btn-lg group hover:scale-105 transition-transform"
            >
              <.icon name="hero-x-mark" class="size-5" /> Decline
            </button>

            <button
              phx-click="accept_challenge"
              class="flex-1 btn btn-success btn-lg group hover:scale-105 transition-transform shadow-lg"
            >
              <.icon name="hero-check" class="size-5" /> Accept Challenge
            </button>
          </div>
        </div>

        <%!-- Info Alert --%>
        <div class="alert bg-info/10 border-info/20 mt-6 shadow-lg">
          <.icon name="hero-information-circle" class="size-6 text-info shrink-0" />
          <div>
            <div class="font-bold">Ready to compete?</div>
            <div class="text-sm opacity-75">
              Accepting this challenge will start a match. Make sure you're ready!
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Matches.get_challenge(id) do
      {:ok, challenge} ->
        current_user_id = socket.assigns.current_scope.user.id

        # If the user is the creator, redirect them to the waiting room
        if challenge.created_by_id == current_user_id do
          {:ok,
           socket
           |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}
        else
          # Otherwise, show the challenge details
          socket =
            socket
            |> assign(:challenge, challenge)

          {:ok, socket}
        end

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("accept_challenge", _params, socket) do
    # TODO: Implement challenge acceptance logic
    # For now, just show a flash message
    {:noreply,
     socket
     |> put_flash(:info, "Challenge acceptance coming soon!")
     |> push_navigate(to: ~p"/dashboard")}
  end

  @impl true
  def handle_event("decline_challenge", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Challenge declined")
     |> push_navigate(to: ~p"/dashboard")}
  end
end
