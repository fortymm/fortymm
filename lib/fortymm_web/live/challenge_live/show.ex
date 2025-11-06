defmodule FortymmWeb.ChallengeLive.Show do
  use FortymmWeb, :live_view

  alias Fortymm.Matches
  alias FortymmWeb.Presence

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
        current_user = socket.assigns.current_scope.user
        maybe_redirect_or_show(socket, challenge, current_user)

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_event("accept_challenge", _params, socket) do
    case Matches.update_challenge(socket.assigns.challenge.id, %{status: "accepted"}) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge accepted!")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to accept challenge. Please try again.")}
    end
  end

  @impl true
  def handle_event("decline_challenge", _params, socket) do
    case Matches.update_challenge(socket.assigns.challenge.id, %{status: "rejected"}) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge declined")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to decline challenge. Please try again.")}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    # Presence tracking is happening but we don't need to update the UI
    {:noreply, socket}
  end

  @impl true
  def handle_info({:challenge_updated, challenge}, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    socket =
      case {status, is_creator} do
        # Still pending: update the challenge
        {:challenge_pending, false} ->
          assign(socket, :challenge, challenge)

        # Any other case: apply common redirect logic
        _ ->
          socket
          |> apply_status_redirect(challenge, status, is_creator)
          |> elem(1)
      end

    {:noreply, socket}
  end

  defp maybe_redirect_or_show(socket, challenge, current_user) do
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user.id

    case {status, is_creator} do
      # Pending: creator redirected to waiting room
      {:challenge_pending, true} ->
        {:ok,
         socket
         |> put_flash(:info, "View the waiting room to see who's checking out your challenge")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}

      # Pending: non-creator can see show page
      {:challenge_pending, false} ->
        topic = "challenge:#{challenge.id}"

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Fortymm.PubSub, topic)

          {:ok, _} =
            Presence.track(self(), topic, current_user.id, %{
              username: current_user.username,
              joined_at: System.system_time(:second)
            })
        end

        socket =
          socket
          |> assign(:challenge, challenge)

        {:ok, socket}

      # Accepted: creator redirected to scoring
      {:challenge_accepted, true} ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! Time to enter scores")
         |> push_navigate(to: ~p"/matches/#{challenge.id}/games/1/scores/new")}

      # Common redirects: use utility function
      _ ->
        apply_status_redirect(socket, challenge, status, is_creator)
    end
  end

  defp apply_status_redirect(socket, challenge, status, is_creator) do
    case {status, is_creator} do
      # Accepted: non-creator redirected to match page
      {:challenge_accepted, false} ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! The match has begun")
         |> push_navigate(to: ~p"/matches/#{challenge.id}")}

      # Cancelled: anyone redirected to dashboard
      {:challenge_cancelled, _} ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been cancelled")
         |> push_navigate(to: ~p"/dashboard")}

      # Rejected: anyone redirected to dashboard
      {:challenge_rejected, _} ->
        {:ok,
         socket
         |> put_flash(:info, "This challenge has been declined")
         |> push_navigate(to: ~p"/dashboard")}

      # Any other case: redirect to waiting room
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge status changed")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}/waiting_room")}
    end
  end
end
