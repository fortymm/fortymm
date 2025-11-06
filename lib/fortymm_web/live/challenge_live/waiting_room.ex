defmodule FortymmWeb.ChallengeLive.WaitingRoom do
  use FortymmWeb, :live_view

  alias Fortymm.Matches
  alias FortymmWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto">
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body items-center text-center">
            <%!-- Animated waiting indicator --%>
            <div class="relative w-32 h-32 mb-6">
              <div class="absolute inset-0 rounded-full border-8 border-primary/20"></div>
              <div class="absolute inset-0 rounded-full border-8 border-primary border-t-transparent animate-spin">
              </div>
              <div class="absolute inset-0 flex items-center justify-center">
                <.icon name="hero-trophy" class="size-16 text-primary" />
              </div>
            </div>

            <h2 class="card-title text-3xl mb-2">Waiting for Opponent</h2>
            <p class="text-lg opacity-75 mb-6">
              Challenge sent! We're waiting for your opponent to accept.
            </p>

            <%!-- Challenge Details --%>
            <div class="w-full max-w-md space-y-4 mb-6">
              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Challenge ID:</span>
                <span class="font-mono text-primary">#{String.slice(@challenge.id, 0..7)}</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Match Length:</span>
                <span>Best of {@challenge.length_in_games}</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Match Type:</span>
                <span class="flex items-center gap-2">
                  <%= if @challenge.rated do %>
                    <span class="badge badge-primary">Rated</span>
                  <% else %>
                    <span class="badge badge-ghost">Unrated</span>
                  <% end %>
                </span>
              </div>

              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Viewers:</span>
                <span>
                  <%= if @viewers == [] do %>
                    <span class="text-base-content/60">No one yet...</span>
                  <% else %>
                    <div class="flex flex-wrap gap-2 justify-end">
                      <%= for viewer <- @viewers do %>
                        <span class="badge badge-success gap-2">
                          <.icon name="hero-eye" class="size-4" />
                          {viewer}
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                </span>
              </div>
            </div>

            <%!-- Actions --%>
            <div class="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
              <.link href={~p"/dashboard"} class="btn btn-outline">
                <.icon name="hero-arrow-left" class="size-5" /> Back to Dashboard
              </.link>
              <button class="btn btn-error btn-outline" phx-click="cancel_challenge">
                <.icon name="hero-x-mark" class="size-5" /> Cancel Challenge
              </button>
            </div>
          </div>
        </div>

        <%!-- Info Alert --%>
        <div class="alert bg-info/10 border-info/20 mt-6">
          <.icon name="hero-information-circle" class="size-6 text-info" />
          <div>
            <div class="font-bold">Heads up!</div>
            <div class="text-sm opacity-75">
              Your opponent will receive a notification. You'll be automatically redirected when they accept.
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
        maybe_redirect_or_show(socket, challenge, current_user_id)

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Challenge not found")
         |> push_navigate(to: ~p"/dashboard")}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    topic = "challenge:#{socket.assigns.challenge.id}"
    {:noreply, assign(socket, :viewers, list_viewers(topic))}
  end

  @impl true
  def handle_info({:challenge_updated, challenge}, socket) do
    current_user_id = socket.assigns.current_scope.user.id
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    socket =
      case {status, is_creator} do
        # Still pending: update the challenge
        {:challenge_pending, true} ->
          assign(socket, :challenge, challenge)

        # Any other case: apply common redirect logic
        _ ->
          socket
          |> apply_status_redirect(challenge, status, is_creator)
          |> elem(1)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_challenge", _params, socket) do
    case Matches.update_challenge(socket.assigns.challenge.id, %{status: "cancelled"}) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Challenge cancelled")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Challenge not found.")
         |> push_navigate(to: ~p"/dashboard")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to cancel challenge. Please try again.")}
    end
  end

  defp list_viewers(topic) do
    topic
    |> Presence.list()
    |> Enum.map(fn {_user_id, %{metas: [meta | _]}} -> meta.username end)
  end

  defp maybe_redirect_or_show(socket, challenge, current_user_id) do
    status = Matches.status(challenge)
    is_creator = challenge.created_by_id == current_user_id

    case {status, is_creator} do
      # Pending: creator can see waiting room
      {:challenge_pending, true} ->
        topic = "challenge:#{challenge.id}"

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Fortymm.PubSub, topic)
        end

        socket =
          socket
          |> assign(:challenge, challenge)
          |> assign(:viewers, list_viewers(topic))

        {:ok, socket}

      # Pending: non-creator redirected to show page
      {:challenge_pending, false} ->
        {:ok,
         socket
         |> put_flash(:info, "View the challenge details to accept or decline")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}")}

      # Common redirects: use utility function
      _ ->
        apply_status_redirect(socket, challenge, status, is_creator)
    end
  end

  defp apply_status_redirect(socket, challenge, status, is_creator) do
    case {status, is_creator} do
      # Accepted: creator redirected to scoring
      {:challenge_accepted, true} ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge accepted! Time to enter scores")
         |> push_navigate(to: ~p"/matches/#{challenge.id}/games/1/scores/new")}

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

      # Any other case: redirect to show page
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Challenge status changed")
         |> push_navigate(to: ~p"/challenges/#{challenge.id}")}
    end
  end
end
