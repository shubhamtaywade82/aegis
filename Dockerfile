# syntax=docker/dockerfile:1

FROM ruby:3.4.2-slim AS base

ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=development

WORKDIR $APP_HOME

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libpq-dev \
    postgresql-client \
    pkg-config \
    nodejs \
    npm \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN gem update --system && \
    bundle install

COPY . .

RUN chmod +x docker/docker-entrypoint.sh

RUN useradd -m rails
RUN chown -R rails:rails /app

USER rails

ENTRYPOINT ["docker/docker-entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]