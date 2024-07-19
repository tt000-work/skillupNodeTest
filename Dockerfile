FROM node:16-alpine
COPY src/. /app/
WORKDIR /app/
RUN npm install

CMD [ "npm", "start" ]

