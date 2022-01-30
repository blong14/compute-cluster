FROM marceloglezer/cockroach:v20.2.0

COPY cockroach.sh cockroach.sh

RUN addgroup --gid 1000581000 cockroach-group

RUN chown :1000581000 /cockroach && chmod -R 755 /cockroach && chmod g+s /cockroach


