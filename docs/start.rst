.. _start:

Start
=====

To adapt this project, just clone the repo: 

`git clone https://github.com/roedoejet/flask_festival_api_starter.git`

If you want to spin up your own version on Heroku, just make a Heroku project, and push the project.
You'll need to set the stack to "container", like `heroku set:stack container`

If you want to just run this locally, change the `$PORT` variable in the Dockerfile to whatever port (say, 5000) you want to run on and then build your docker container:

`docker build -t tts_api .`
`docker run -t tts_api -p 5000:5000`

Then you can access the API on port 5000.