# if you're doing anything beyond your local machine, please pin this to a specific version at https://hub.docker.com/_/node/
FROM node:10.8.0-alpine

RUN mkdir -p /opt/app

# set our node environment, either development or production
# defaults to production, compose overrides this to development on build and run
ARG NODE_ENV=production
ARG npm_config_registry
ARG yarn_config_registry
ENV NODE_ENV $NODE_ENV

# default to port 80 for node, and 9229 and 9230 (tests) for debug
ARG PORT=80
ENV PORT $PORT
EXPOSE $PORT 9229 9230

# you'll likely want the latest npm and yarn, reguardless of node version, for speed and fixes
RUN npm install npm@latest -g && npm install yarn@latest -g

# install dependencies first, in a different location for easier app bind mounting for local development
WORKDIR /opt
COPY  package.json yarn.lock* package-lock.json* ./

RUN if [ -n "${npm_config_registry+1}" ]; then npm config set registry $npm_config_registry --global ; fi \
&& if [ -n "${yarn_config_registry+1}" ]; then yarn config set registry $yarn_config_registry --global ; find . -type f -name 'yarn.lock' -exec sed -i "s|https:\/\/registry\.yarnpkg\.com\/|$yarn_config_registry|g" {} + ; fi \
&& if [[ -f package.json && -f yarn.json ]]; then yarn set progress=false; yarn install; yarn cache clean --force; fi \
&& if [[ -f package.json && ! -f yarn.json ]]; then npm set progress=false; npm install; npm cache clean --force; fi 

ENV PATH /opt/node_modules/.bin:$PATH

# check every 30s to ensure this service returns HTTP 200
HEALTHCHECK --interval=30s CMD node healthcheck.js

# copy in our source code last, as it changes the most
WORKDIR /opt/app
COPY . /opt/app

# if you want to use npm start instead, then use `docker run --init in production`
# so that signals are passed properly. Note the code in index.js is needed to catch Docker signals
# using node here is still more graceful stopping then npm with --init afaik
# I still can't come up with a good production way to run with npm and graceful shutdown
CMD [ "node", "index.js" ]
