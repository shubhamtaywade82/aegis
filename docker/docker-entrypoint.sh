#!/bin/sh
set -e

rm -f /app/tmp/pids/server.pid

bundle check || bundle install

bundle exec rails db:prepare

exec "$@"