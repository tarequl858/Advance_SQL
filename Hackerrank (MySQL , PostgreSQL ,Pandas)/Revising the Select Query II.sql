# MYSQL,POSTGRESQL,ORACLE,SQL SERVER,SQLITE

SELECT NAME
FROM CITY
WHERE POPULATION > 120000 AND COUNTRYCODE = 'USA';

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
SELECT NAME
FROM CITY
WHERE COUNTRYCODE = 'USA'
  AND POPULATION > 120000;
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
filtered = city[(city['COUNTRYCODE'] == 'USA') & (city['POPULATION'] > 120000)]
print(filtered[['NAME']])