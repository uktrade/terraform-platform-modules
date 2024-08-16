FROM python:3.9
RUN apt-get update && apt-get install -y curl
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /src
COPY poetry.lock ./
COPY pyproject.toml ./

RUN poetry update
COPY . ./
RUN poetry install --no-root

CMD ["poetry", "run", "pytest"]