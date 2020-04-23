FROM crystallang/crystal:0.34.0

# Deps
ENV NPM_CONFIG_LOGLEVEL warn
RUN apt-get update
RUN apt-get install curl -y
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install nodejs -y
WORKDIR /build
ADD gulpfile.js package.json shard.yml shard.lock /build/
RUN shards install
RUN npm install

# Build
COPY ./assets /build/assets
RUN npm run build
COPY . /build
RUN shards build --release
RUN mv ./bin/web /usr/local/bin/web

# Cleanup
RUN apt-get remove nodejs -y
RUN apt-get purge
RUN rm -rf /build
RUN rm `which crystal`
RUN rm `which shards`

# Move back to root
RUN mkdir /workdir
WORKDIR /workdir

ENTRYPOINT [ "/usr/local/bin/web" ]
