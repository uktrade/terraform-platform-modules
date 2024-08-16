build:
	docker-compose build

test: down build
	docker-compose run manage-users poetry run pytest

down:
	docker-compose down