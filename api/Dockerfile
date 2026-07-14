FROM node:22-alpine AS deps
WORKDIR /app
RUN apk add --no-cache openssl libc6-compat
COPY api/package*.json ./
COPY api/prisma ./prisma/
RUN npm ci
RUN npx prisma generate

FROM node:22-alpine AS build
WORKDIR /app
RUN apk add --no-cache openssl libc6-compat
COPY --from=deps /app/node_modules ./node_modules
COPY api/ ./
RUN npm run build
RUN npx prisma generate

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl libc6-compat
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/prisma ./prisma
COPY docs ./docs
RUN mkdir -p uploads
EXPOSE 3100
CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma db seed && node dist/main.js"]
