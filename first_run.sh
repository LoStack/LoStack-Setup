sudo docker compose up openldap lostack-db -d
sudo docker compose run -e FIRST_RUN=true --rm lostack
sudo docker compose up lostack traefik authelia -d --build