# Docker Rails (WIP)
This is a starter kit for running Ruby on Rails with Docker

## Versions
* Ruby on Rails - 7.0.4
* PostgreSQL - 14.1

Build our Docker images.
```
docker compose \
  -f docker-compose.yaml \
  -f docker-compose-dev.yaml \
  --env-file .env.dev \
  build \
    --build-arg APP_NAME=daapp \
    --build-arg APP_USER_ID=$UID \
    --build-arg APP_GROUP_ID=$GID \
    --build-arg APP_USER=$USER
```

If you are starting a new Rails application, copy the files 
from the contianer to your local machine.
```
export APP_NAME="daapp" \
  && docker container run -itd --name=rails-tmp rails-base sh \
  && docker container cp rails-tmp:/opt/$APP_NAME $APP_NAME \
  && docker container kill rails-tmp \
  && docker container rm rails-tmp
```

Bring up all the containers for the Development environment.
```
docker compose \
  -f docker-compose.yaml \
  -f docker-compose-dev.yaml \
  --env-file .env.dev \
  up
```

Generate a scaffold
```
docker compose run \
  --user $UID:$GID \
  app \
  bin/rails generate scaffold device name:string
```

Destroy a scaffold
```
docker compose run \
  --user $UID:$GID \
  app \
  bin/rails destroy scaffold device name:string
```
