FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV RUSTUP_INIT_SKIP_PATH_CHECK=yes

RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    sudo \
    php \
    python3 \
    python3-pip \
    libc6:i386 \
    libcurl4-openssl-dev:i386 \
    libstdc++6:i386 \
    dpkg \
    git \
    build-essential \
    zlib1g-dev:i386 \
    gcc-multilib \
    g++-multilib

RUN curl https://sh.rustup.rs -sSfo rustup-init.sh && \
    chmod +x rustup-init.sh && \
    ./rustup-init.sh -y && \
    . "$HOME/.cargo/env" && \
    rustup target add i686-unknown-linux-gnu && \
    git clone https://github.com/tgstation/rust-g && cd ./rust-g  &&\
    export PKG_CONFIG_ALLOW_CROSS=1 && \
    RUSTFLAGS="-C target-cpu=native" && cargo build --release --target i686-unknown-linux-gnu
    
# Actually download TGS
RUN sudo apt update \
    && sudo apt install -y software-properties-common \
    && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv B6FD15EE7ED77676EAEAF910EEEDC8280A307527 \
    && sudo add-apt-repository -y "deb https://tgstation.github.io/tgstation-ppa/debian unstable main" \
    && sudo apt update

# Add Node.js official repo and install ## Deprecated, BUN is the future
# Download and install nvm:
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \

    # in lieu of restarting the shell
    && \. "$HOME/.nvm/nvm.sh" && nvm install 22
    

# Set pip config
RUN python3 -m pip config set global.break-system-packages true

# Install ripgrep via cargo
#RUN apt install cargo -y && cargo install ripgrep --features pcre2

# Install dotnet SDK
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i ./packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0

# Permissions for dotnet
RUN chmod -R 777 /usr/share/dotnet

# Visudo equivalent
RUN echo 'tgstation-server ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Create non-root user
RUN useradd -ms /bin/bash tgstation-server && echo "tgstation-server:tgstation-server" | chpasswd && adduser tgstation-server sudo

USER tgstation-server
WORKDIR /home/tgstation-server

RUN git clone https://github.com/bubberstation/bubberstation && wget https://www.byond.com/download/build/516/516.1666_byond_linux.zip


RUN unzip *byond*.zip && ls && cd ./byond/ && make here && sudo make install && . ~/byond/bin/byondsetup \
    && ../bubberstation/tools/build/build.sh