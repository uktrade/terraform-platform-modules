import psycopg2
from manage_users.manage_users import create_or_update_db_user

class TestCreateOrUpdateDbUser: 
    def test_create_or_update_db_user_creates_user(self, database_connection):
        permissions = ['SELECT', 'DELETE']
        
        cursor = database_connection.cursor()
        cursor.execute('CREATE ROLE postgres WITH SUPERUSER')
        cursor.execute('CREATE ROLE application_user WITH SUPERUSER')
        
        create_or_update_db_user(database_connection, cursor, 'new_user', 'new_password', permissions)
        
        cursor.execute('SELECT usename FROM pg_catalog.pg_user WHERE usename= %s', ("new_user",))
        assert cursor.fetchone()[0] == 'new_user'
        
        
    def test_new_user_can_connect_select_and_create_a_table(self):
        new_user_connection = psycopg2.connect(
            dbname='test_db',
            user='new_user',
            password='new_password',
            host='postgres-unittest',
            port=5432
        )
        new_cursor = new_user_connection.cursor()
        new_cursor.execute('SELECT * FROM pg_catalog.pg_user')
        
        assert new_cursor.fetchone()[0] == 'test_user'
        
        new_cursor.execute('CREATE TABLE public.new_user_table (id SERIAL PRIMARY KEY)')
        new_cursor.execute('INSERT INTO public.new_user_table VALUES (1)')
        new_cursor.execute('SELECT id FROM public.new_user_table')
        
        assert new_cursor.fetchone()[0] == 1
        
        new_user_connection.commit()
        new_user_connection.close()
        
    
    def test_executing_create_or_update_db_user_again_does_not_drop_new_user_tables(self, database_connection):
        cursor = database_connection.cursor()
        create_or_update_db_user(database_connection, cursor, 'new_user', 'another_new_password', ['SELECT'])
        
        new_user_connection = psycopg2.connect(
            dbname='test_db',
            user='new_user',
            password='another_new_password',
            host='postgres-unittest',
            port=5432
        )
        new_cursor = new_user_connection.cursor()
        
        new_cursor.execute('SELECT id FROM public.new_user_table')
        assert new_cursor.fetchone()[0] == 1