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

# Install asdf
ENV ASDF_DIR=/opt/asdf
RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.0 && \
    echo '. /opt/asdf/asdf.sh' >> ~/.bashrc

# Add asdf to PATH
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}"

RUN echo "legacy_version_file = yes" >> ~/.asdfrc

# Set working directory for the application
WORKDIR /workspace

# Copy .tool-versions file to workspace
COPY .tool-versions /workspace/.tool-versions

# Install asdf plugins and tools
RUN . $ASDF_DIR/asdf.sh && \
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf install && \
    asdf reshim

# Install Hex and Rebar
RUN . $ASDF_DIR/asdf.sh && \
    mix local.hex --force && \
    mix local.rebar --force

CMD ["/bin/bash"]
