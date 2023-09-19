# Gebruik node image 18 alpine is de lightweight versie en is daarom ook sneller
FROM node:18-alpine as base
# Je hebt python nodig om alpine te gebruiken daarom hebben we deze line nodig
RUN apk add --no-cache g++ make py3-pip libc6-compat
WORKDIR /app
COPY package*.json ./
EXPOSE 3000
# Alle settings die we hergebruiken in andere fases komen in de base.

# Dit gedeelte van de multi-stage zorgt voor npm build deze stage word geroepen nadat we proberen copy --from=builder.
# Note: Deze sage wordt alleen geroepen wanneer deze files nog niet bestaan, om deze reden is multi-stage krachtig.
FROM base as builder
WORKDIR /app
COPY . .
RUN npm run build

FROM base as production
WORKDIR /app
# Set de env naar production
ENV NODE_ENV=production
# We gebruiken npm ci ipv npm install omdat dit simpelweg veel sneller is.
# Note: ci overschrijft niks, het kan niet gebruikt worden voor single installs src: https://stackoverflow.com/questions/52499617/what-is-the-difference-between-npm-install-and-npm-ci
RUN npm ci

# Maak een extra non-root user aan vanwege security issues
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs


COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

CMD npm start

FROM base as dev
ENV NODE_ENV=development
RUN npm install
COPY . .
CMD npm run dev