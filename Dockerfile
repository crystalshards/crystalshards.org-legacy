FROM crystallang/crystal:0.22.0
WORKDIR /app
ADD . /app
RUN shards build
CMD ./bin/web
