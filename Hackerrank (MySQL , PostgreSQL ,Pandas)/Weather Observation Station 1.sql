# MYSQL,POSTGRESQL,ORACLE,SQL SERVER,SQLITE

SELECT CITY,STATE
FROM STATION;

# sqlite3 using python

import sqlite3
import pandas as pd
conn = sqlite3.connect('world.db')
cursor = conn.cursor()
cursor.execute("""
CREATE TABLE IF NOT EXISTS STATION (
    ID INTEGER PRIMARY KEY,
    CITY TEXT,
    COUNTRYCODE TEXT,
    STATE TEXT,
    POPULATION INTEGER
);
""")
city = pd.DataFrame({
    'ID': [1, 2, 3],
    'CITY': ['New York', 'Los Angeles', 'Chicago'],
    'COUNTRYCODE': ['USA', 'CF', 'JPN'],
    'STATE': ['New York', 'California', 'Illinois'],
    'POPULATION': [8000000, 4000000, 2700000]
})
city.to_sql('STATION', conn, if_exists='replace', index=False)
cursor.execute("""
SELECT ID, CITY, COUNTRYCODE, STATE, POPULATION
FROM STATION;
""")
rows = cursor.fetchall()
for row in rows:
    print(row)
conn.close()

# pandas

import pandas as pd
city = pd.DataFrame({
    'ID': [1, 2, 3],
    'CITY': ['New York', 'Los Angeles', 'Chicago'],
    'COUNTRYCODE': ['USA', 'CF', 'JPN'],
    'STATE': ['New York', 'California', 'Illinois'],
    'POPULATION': [8000000, 4000000, 2700000]
})
print(city[['CITY', 'STATE']])