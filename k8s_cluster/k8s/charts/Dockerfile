FROM python:alpine

RUN pip install --upgrade pip && pip install pipreqs

COPY gcp-api.py /app/

RUN pipreqs --force /app/

RUN pip install -r /app/requirements.txt

WORKDIR /app/

RUN apk add curl

COPY * .

#ENV GOOGLE_APPLICATION_CREDENTIALS=key.json
