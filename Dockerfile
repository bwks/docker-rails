################## RAILS BUILD IMAGE ################## 
# Use this to generate a new rails application
FROM ruby:3.1.2-alpine3.16 AS build

# ARGs are passed in via the `--build-arg ` CLI argument
ARG APP_NAME
ARG APP_USER
ARG APP_USER_ID
ARG APP_GROUP_ID
ENV APP_NAME ${APP_NAME}
ENV APP_USER ${APP_USER}
ENV APP_USER_ID ${APP_USER_ID}
ENV APP_GROUP_ID ${APP_GROUP_ID}

# Static variables
ARG BUILD_PACKAGES="build-base"

# Install build deps
RUN echo "http://dl-4.alpinelinux.org/alpine/v3.16/main" >> /etc/apk/repositories \
  && echo "http://dl-4.alpinelinux.org/alpine/v3.16/community" >> /etc/apk/repositories \
  && apk update \
  && apk add ${BUILD_PACKAGES}

# Set working directory
WORKDIR /opt

# Install Rails
RUN gem install rails bundler --no-document

# Create new Rails app
RUN rails new \
  --skip-bundle \
  --skip-git \
  --database=postgresql \
  --css=tailwind \
  ${APP_NAME}

WORKDIR /opt/${APP_NAME}

################## RAILS BASE IMAGE ################## 
FROM ruby:3.1.2-alpine3.16 AS rails-base

ARG APP_NAME
ARG APP_USER
ARG APP_USER_ID
ARG APP_GROUP_ID
ENV APP_NAME ${APP_NAME}
ENV APP_USER ${APP_USER}
ENV APP_USER_ID ${APP_USER_ID}
ENV APP_GROUP_ID ${APP_GROUP_ID}

ARG RUN_PACKAGES="build-base tzdata postgresql-dev postgresql-client nodejs yarn"

RUN echo "http://dl-4.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories \
  && echo "http://dl-4.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories \
  && apk update \
  && apk add --no-cache $RUN_PACKAGES

# Default directory
RUN mkdir -p /opt/${APP_NAME}
WORKDIR /opt/${APP_NAME}

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /opt/${APP_NAME} /opt/${APP_NAME}
COPY config/Gemfile Gemfile

RUN bundle install \
  && bin/rails tailwindcss:install

COPY config/Procfile.dev Procfile.dev
COPY config/database.yml config/database.yml
COPY config/environments-development.rb config/environments/development.rb
COPY config/bin-dev bin/dev
RUN chmod +x bin/dev

# Cleanup cache
RUN bundle clean --force \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete

# Create app user and group
RUN addgroup -S ${APP_USER} -g ${APP_GROUP_ID}  && adduser -u ${APP_USER_ID} -S ${APP_USER} -G ${APP_USER}

# Set directory ownership
RUN chown -R ${APP_USER_ID}:${APP_GROUP_ID} /opt/${APP_NAME}

USER ${APP_USER}

# Add a script to be executed every time the container starts.
EXPOSE 3000
CMD ["bin/dev"]