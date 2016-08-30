FROM ruby:2.2.2

RUN apt-get update && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get --no-install-recommends install --yes \
    postgresql-contrib \
    sqlite3 libsqlite3-dev \
    nodejs git \
    build-essential libreadline-dev \
    libpq-dev libkrb5-dev \
    libxslt-dev libxml2-dev \
    ruby-dev

EXPOSE 5000
CMD ./run.sh

RUN gem install -v 1.10.6 bundler
RUN mkdir /gradecraft
WORKDIR /gradecraft/
ADD Gemfile /gradecraft/Gemfile
ADD Gemfile.lock /gradecraft/Gemfile.lock
RUN bundle install

COPY . /gradecraft
