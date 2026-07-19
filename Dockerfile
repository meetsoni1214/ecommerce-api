# syntax=docker/dockerfile:1.7

# 1. build — install all deps, generate Prisma client, compile TS, prune to prod
FROM node:20-alpine AS build
WORKDIR /app
RUN apk add --no-cache openssl && corepack enable && corepack prepare pnpm@9.15.4 --activate
COPY package.json pnpm-lock.yaml ./
COPY prisma ./prisma
RUN pnpm install --frozen-lockfile
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN pnpm prisma generate && pnpm build && pnpm prune --prod

# 2. runtime — slim production image
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl wget
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/dist ./dist
RUN chown -R node:node /app
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
