from sqlite3 import dbapi2 as sqlite3

class Data:
    def __init__(self, name):
        self.db = self.connect_db(name)

    def connect_db(self, database_name):
        """Connects to the specific database."""
        rv = sqlite3.connect(database_name)
        rv.row_factory = sqlite3.Row
        return rv

    def init_db(self, schema_file):
        """Initializes the database"""
        with schema_file as f:
            self.db.cursor().executescript(f.read())
        self.db.commit()

    def close(self):
        self.db.close()

    def save_new_run(self, data):
        pass

    def get_runs(self):
        pass

