FROM cassandra:2.2

MAINTAINER "Salman Taherizadeh - Jozef Stefan Institute"

RUN apt-get update && apt-get install -yq dnsutils && apt-get clean && rm -rf /var/lib/apt/lists

COPY pre-docker-entrypoint.sh /
RUN chmod 777 /pre-docker-entrypoint.sh

ENTRYPOINT ["/pre-docker-entrypoint.sh"]

CMD ["cassandra", "-f"]
