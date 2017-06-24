from sqlite3 import dbapi2 as sqlite3

class Data:
    def __init__(self, name):
        self.db_name = name
        self.db = self.connect_db(name)

    def connect_db(self, database_name):
        """Connects to the specific database."""
        conn = sqlite3.connect(database_name)
        conn.row_factory = sqlite3.Row

        # def dict_factory(cursor, row):
        #     d = {}
        #     for idx, col in enumerate(cursor.description):
        #         d[col[0]] = row[idx]
        #         return d

        # conn.row_factory = dict_factory

        return conn

    def init_db(self, schema_file):
        """Initializes the database"""
        with schema_file as f:
            self.db.cursor().executescript(f.read())
        self.db.commit()

    def close(self):
        self.db.close()

    def save_new_run(self, description, date, run_data):
        c = self.db.cursor()
        c.execute('INSERT INTO runs(title, date) VALUES(?, ?)', (description, date))
        run_id = c.lastrowid

        rows = []
        for item in run_data:
            rows.append((run_id, item['time'], item['speed']))

        c.executemany('INSERT INTO run_segments(run_id, time_point, speed) VALUES(?, ?, ?)', rows)
        self.db.commit()

        return {'id': run_id, 'description': description, 'date': date, 'segments': run_data}

    def get_runs(self):
        try:
            c = self.db.cursor()
            c.execute('SELECT * FROM runs')
            data = c.fetchall()
            data = map(to_dict, data)

        except Exception as e:
            print(e)
        return data




def to_dict(r):
    d = {}
    for k in r.keys():
        d[k] = r[k]
    return d

