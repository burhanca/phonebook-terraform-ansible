# WEBSERVER
#init a base image Alpine linux distro
FROM python:3.7-alpine

COPY requirements.txt .
#run pip to install the dependencies of the flask app
RUN python3 -m pip install --upgrade pip
RUN pip install -r requirements.txt

#define the present working directory
WORKDIR /app


#copy the contents into the working dir
ADD  . /app



# app web port
EXPOSE 80

# define the command to start the container

CMD python3 app.py
