# Which Ruby version to use. You may need to use a more restrictive version,
# e.g. `3.0`
ARG VARIANT=3.3

# Pull Microsoft's ruby devcontainer base image
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

# Install libsodium dependency for voice channel interactions
RUN apt update -yq && apt install -y libsodium-dev

# Ensure we're running the latest bundler, as what ships with the Ruby image may
# not be current, and bundler will auto-downgrade to match the Gemfile.lock
RUN gem install bundler
