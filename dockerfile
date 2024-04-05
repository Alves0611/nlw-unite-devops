FROM node:20 AS base
USER node
RUN mkdir ~/.npm-global
RUN npm config set prefix '~/.npm-global'
ENV PATH=$PATH:/home/node/.npm-global/bin
RUN npm install -g pnpm
WORKDIR /usr/src/app
COPY --chown=node:node package*.json pnpm-lock.yaml ./
RUN pnpm install 

FROM base AS build
USER node
WORKDIR /usr/src/app
COPY --chown=node:node . .
RUN pnpm run build  # Este comando deve existir no seu package.json e criar o diretório dist

FROM node:20-alpine3.19 AS deploy
USER node
WORKDIR /usr/src/app

RUN mkdir ~/.npm-global
RUN npm config set prefix '~/.npm-global'
ENV PATH=$PATH:/home/node/.npm-global/bin

RUN npm install -g --unsafe-perm pnpm

COPY --chown=node:node --from=build /usr/src/app/dist ./dist
COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/package.json ./package.json
COPY --chown=node:node --from=build /usr/src/app/prisma ./prisma

RUN pnpm prune --prod
RUN pnpx prisma generate

EXPOSE 3333
CMD ["pnpm", "start"]
