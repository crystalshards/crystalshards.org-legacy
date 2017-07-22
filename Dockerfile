FROM crystallang/crystal:0.23.0

# Install and link amber_cmd
ENV AMBER_VERSION 0.1.13
ADD https://github.com/Amber-Crystal/amber_cmd/archive/v$AMBER_VERSION.tar.gz /usr/local/share
RUN cd /usr/local/share/amber_cmd-$AMBER_VERSION && shards install make
RUN ln -sf /usr/local/share/amber_cmd-$AMBER_VERSION/bin/amber /usr/local/bin/amber

# Build the app
WORKDIR /app
ADD shard.yml shard.lock /app
RUN shards install
RUN shards build

# Set config
CMD bin/app
