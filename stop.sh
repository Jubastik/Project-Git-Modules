#!/bin/sh

docker rm -f backend-service frontend postgres
docker network rm backend frontend
docker volume rm postgres