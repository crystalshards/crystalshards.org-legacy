FROM crystallang/crystal:0.22.0
WORKDIR /app

ADD shard.yml shard.lock /app/
RUN shards install

COPY . /app
RUN shards build
CMD ./bin/web
