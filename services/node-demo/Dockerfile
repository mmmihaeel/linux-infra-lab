FROM node:20-alpine
WORKDIR /app
COPY --chown=node:node server.js .
USER node
EXPOSE 3006
CMD ["node", "server.js"]
