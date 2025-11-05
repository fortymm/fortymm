defmodule FortymmWeb.DashboardLive do
  use FortymmWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <.header>
          Dashboard
          <:subtitle>Welcome back, {@current_scope.user.username}! 👋</:subtitle>
        </.header>

        <div class="mt-8 grid gap-6">
          <%!-- Challenge a Friend Card --%>
          <div class="card bg-gradient-to-br from-primary/20 to-secondary/20 shadow-xl border border-primary/30">
            <div class="card-body">
              <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
                <div class="text-center sm:text-left">
                  <h2 class="card-title text-2xl mb-2">
                    <.icon name="hero-trophy" class="size-7 text-primary" /> Challenge a Friend
                  </h2>
                  <p class="text-base opacity-90">
                    Ready to put your skills to the test? Invite a friend and see who comes out on top!
                  </p>
                </div>
                <button
                  class="btn btn-primary btn-lg gap-2 shadow-lg hover:shadow-xl transition-all"
                  onclick="challenge_modal.showModal()"
                >
                  <.icon name="hero-user-plus" class="size-5" /> Start Challenge
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

            <.form for={%{}} phx-submit="create_challenge" id="challenge-form">
              <div class="space-y-4">
                <div>
                  <label class="label">
                    <span class="label-text font-semibold">Friend's Email or Username</span>
                  </label>
                  <input
                    type="text"
                    name="opponent"
                    placeholder="Enter email or username"
                    class="input input-bordered w-full"
                    required
                  />
                  <label class="label">
                    <span class="label-text-alt text-base-content/60">
                      We'll send them an invitation to compete
                    </span>
                  </label>
                </div>

                <div>
                  <label class="label">
                    <span class="label-text font-semibold">Challenge Type</span>
                  </label>
                  <select name="challenge_type" class="select select-bordered w-full">
                    <option selected>Quick Match (5 rounds)</option>
                    <option>Standard (10 rounds)</option>
                    <option>Marathon (20 rounds)</option>
                  </select>
                </div>

                <div>
                  <label class="label">
                    <span class="label-text font-semibold">Optional Message</span>
                  </label>
                  <textarea
                    name="message"
                    class="textarea textarea-bordered w-full h-24"
                    placeholder="Add a friendly message or trash talk..."
                  >
                  </textarea>
                </div>
              </div>

              <div class="modal-action">
                <button type="button" class="btn btn-ghost" onclick="challenge_modal.close()">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary gap-2">
                  <.icon name="hero-paper-airplane" class="size-5" /> Send Challenge
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
    socket =
      socket
      |> assign(:active_nav, :dashboard)

    {:ok, socket}
  end

  @impl true
  def handle_event("create_challenge", _params, socket) do
    # Generate a temporary challenge ID
    # In the future, this would come from the database after creating the challenge
    challenge_id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)

    {:noreply, push_navigate(socket, to: ~p"/challenges/#{challenge_id}/waiting_room")}
  end
end
