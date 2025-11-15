FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
ENV ELIXIR_ERL_OPTIONS="+fnu"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libwxgtk-webview3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    libncurses-dev \
    openjdk-11-jdk \
    inotify-tools \
    postgresql-client \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libffi-dev \
    libyaml-dev \
    tzdata \
    watchman \
    && rm -rf /var/lib/apt/lists/*

# Install mise
RUN curl https://mise.jdx.dev/install.sh | sh
ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"

# Set working directory for the application
WORKDIR /workspace

# Copy .tool-versions file to workspace
COPY .tool-versions /workspace/.tool-versions

# Install tools via mise
RUN bash -c 'eval "$(~/.local/bin/mise activate bash)" && mise install'

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

CMD ["/bin/bash"]
