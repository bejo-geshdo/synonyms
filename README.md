# Background

This is a mono repo for a synonym look up app

The purpos of the app is to be able to add and find synonyms from an API that keeps the synonyms in memmory

## Access to the app

The app is hosted on AWS.
The frontend can be accessed on: https://synonyms.castrojonsson.se/
The API can be accessed on: https://api.synonyms.castrojonsson.se/
Swagger documentation is avalible on: https://api.synonyms.castrojonsson.se/swagger

The dev version of the frontend can be accessed on: https://dev-synonyms.castrojonsson.se/
The dev version of the API can be accessed on: https://api.dev-synonyms.castrojonsson.se/

## Running localy

### Frontend

CD into the ./frontend directory and run:

1. `npm ci`
2. `npm run start`
3. Access the app on http://localhost:3000

#### Change backend URL

You can change what api the frontend will use be setting "REACT_APP_API_URL".

### Backend

CD into the ./backend directory and run:

1. `npm ci`
2. `npm run start`

#### Running localy with Docker.

Run the following to run it localy with Docker:

1. `docker build -t "synonyms-api" .`
2. `docker run -p 8080:8080 synonyms-api`

## Notes about the tech

The frontend is a react app

The backend is an express app running in docker built in typescript

The infrastructure is managed by Terraform

Everything is deployed useing Github Actions

## CI/CD

The app has three github actions with dev/prod support: Infra, Backend and Frontend

The actions are triggerd when ever the directory for each componte or the coresponding workflow file is updated.

When a PR is made into `main` a test action is run testing Infra, Backend and Frontend

## Improvments

Here i will write thing that i can improve about the app.
