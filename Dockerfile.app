# Dockerfile development version
FROM ruby:3.1.2-alpine3.16 AS app-base

ARG APP_NAME

ARG RUN_PACKAGES="build-base tzdata postgresql-dev postgresql-client nodejs yarn"

WORKDIR /opt/${APP_NAME}

RUN echo "http://dl-4.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories \
  && echo "http://dl-4.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories \
  && apk update \
  && apk add --no-cache $RUN_PACKAGES

# Default directory
ENV APP_PATH /opt/${APP_NAME}
RUN mkdir -p ${APP_PATH}

COPY --from=rails-base /usr/local/bundle /usr/local/bundle
COPY ./${APP_NAME} ${APP_PATH}
RUN bundle install \
  && yarn install --check-files

# Cleanup cache
RUN bundle clean --force \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete


# Add a script to be executed every time the container starts.
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]