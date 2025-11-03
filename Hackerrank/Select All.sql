# MYSQL,POSTGRESQL,ORACLE,SQL SERVER,SQLITE

SELECT *
FROM CITY;

# sqlite3 using python

import sqlite3
import pandas as pd
conn = sqlite3.connect('world.db')
cursor = conn.cursor()
cursor.execute("""
CREATE TABLE IF NOT EXISTS CITY (
    ID INTEGER PRIMARY KEY,
    NAME TEXT,
    COUNTRYCODE TEXT,
    DISTRICT TEXT,
    POPULATION INTEGER
);
""")
city = pd.DataFrame({
    'ID': [1, 2, 3],
    'NAME': ['New York', 'Los Angeles', 'Chicago'],
    'COUNTRYCODE': ['USA', 'CF', 'USA'],
    'DISTRICT': ['New York', 'California', 'Illinois'],
    'POPULATION': [8000000, 4000000, 2700000]
})
city.to_sql('CITY', conn, if_exists='replace', index=False)
cursor.execute("""
SELECT *
FROM CITY;
""")
rows = cursor.fetchall()
for row in rows:
    print(row)
conn.close()

# pandas

import pandas as pd
city = pd.DataFrame({
    'ID': [1, 2, 3],
    'NAME': ['New York', 'Los Angeles', 'Chicago'],
    'COUNTRYCODE': ['USA', 'CF', 'USA'],
    'DISTRICT': ['New York', 'California', 'Illinois'],
    'POPULATION': [8000000, 4000000, 2700000]
})
print(city)