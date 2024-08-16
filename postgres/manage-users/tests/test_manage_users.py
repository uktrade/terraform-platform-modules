from manage_users.manage_users import create_db_user

class TestCreateDbUser:
    
    def test_create_db_user_creates_user_with_select_permissions(self, database_connection):
        permissions = ['SELECT']
        cursor = database_connection.cursor()
        cursor.execute('CREATE ROLE postgres WITH SUPERUSER')
        cursor.execute('CREATE ROLE application_user WITH SUPERUSER')
        create_db_user(database_connection, cursor, 'new_user', 'new_password', permissions)
        cursor.execute('SELECT usename FROM pg_catalog.pg_user WHERE usename= %s', ("new_user",))
        
        assert cursor.fetchone()[0] == 'new_user'
