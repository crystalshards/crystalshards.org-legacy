FROM crystallang/crystal:0.34.0
SHELL ["bash", "-c"]

# Deps
ENV NPM_CONFIG_LOGLEVEL warn
RUN apt-get update
RUN apt-get install curl -y
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install nodejs -y
WORKDIR /build
ADD gulpfile.js package.json shard.yml shard.lock ./
RUN shards install
RUN npm i -g yarn
COPY package.json yarn.lock ./
RUN yarn install

# Build
COPY ./assets ./assets
RUN yarn build
COPY . ./
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
