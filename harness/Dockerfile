FROM ruby:3.2
LABEL BitPesa "<engineers@bitpesa.co>"

RUN apt-get update \
  && apt-get install -y net-tools

# Install gems
ENV APP_HOME /app
ENV HOME /root
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
COPY vendor $APP_HOME/vendor

RUN gem install bundler
RUN bundle install

# Upload source
COPY . $APP_HOME

# Start server
EXPOSE 3000

CMD ["bundle", "exec", "rackup", "-q", "-p", "3000", "--host", "0.0.0.0"]
