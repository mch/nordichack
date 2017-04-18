from sqlite3 import dbapi2 as sqlite3

def connect_db(database_name):
    """Connects to the specific database."""
    rv = sqlite3.connect(database_name)
    rv.row_factory = sqlite3.Row
    return rv

def init_db(db, schema_file):
    """Initializes the database"""
    with schema_file as f:
        db.cursor().executescript(f.read())
    db.commit()

