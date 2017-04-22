import unittest

import data

class DataTest(unittest.TestCase):

    def setUp(self):
        self.db = data.Data("test.db")
        f = open('schema.sql')
        self.db.init_db(f)
        f.close()

    def test_save(self):
        segments = [{'time': 0, 'speed': 1}, {'time': 1, 'speed': 0}]
        result = self.db.save_new_run("test", "2017-01-01 01:01:01", segments)

        self.assertEqual(result['id'], 1)
        self.assertEqual(result['description'], "test")
        self.assertEqual(result['date'], "2017-01-01 01:01:01")
        self.assertEqual(result['segments'], segments)


if __name__ == '__main__':
    unittest.main()
