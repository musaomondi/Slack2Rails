FROM public.ecr.aws/docker/library/ruby:3.2 AS Builder

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev yarn nodejs libc6

ARG SSH_PRIVATE_KEY

RUN mkdir /root/.ssh/

RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa

RUN chmod 400 /root/.ssh/id_rsa

RUN touch /root/.ssh/known_hosts

RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN mkdir /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/Gemfile

COPY Gemfile.lock /usr/src/app/Gemfile.lock

WORKDIR /usr/src/app

COPY . /usr/src/app

RUN bundle install --local --jobs=4 --retry=3

FROM public.ecr.aws/docker/library/ruby:3.2

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev yarn nodejs libc6

COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/

RUN mkdir /usr/src/app

WORKDIR /usr/src/app

COPY . /usr/src/app

COPY --from=Builder /usr/src/app/vendor /usr/src/app/vendor

EXPOSE 3000

RUN chmod +x ./bin/entrypoint.sh

ENTRYPOINT ["./bin/entrypoint.sh"]

CMD ["server"]
