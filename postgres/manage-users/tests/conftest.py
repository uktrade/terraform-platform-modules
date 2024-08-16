import os
import pytest
import psycopg2

@pytest.fixture(scope="session")
def database_connection():
    conn = psycopg2.connect(os.getenv("DATABASE_URL"))
    yield conn