# MYSQL, PostgreSQL, SQL Server, and SQLITE

SELECT DISTINCT CITY
FROM STATION
WHERE ID %2 = 0;

# ORACLE, DB2

SELECT DISTINCT CITY
FROM STATION
WHERE MOD(ID, 2) = 0;

# PYTHON (using SQLite)

import sqlite3
import pandas as pd
conn = sqlite3.connect('world.db')
query = """
SELECT DISTINCT CITY
FROM STATION
WHERE ID % 2 = 0;
"""
df = pd.read_sql_query(query, conn)
print(df)
conn.close()

# pandas

import pandas as pd
df = pd.DataFrame({
    'ID': [1, 2, 3, 4, 5, 6],
    'CITY': ['Dhaka', 'Chittagong', 'Khulna', 'Rajshahi', 'Sylhet', 'Barisal']
})
result = df.loc[df['ID'] % 2 == 0, 'CITY'].drop_duplicates()
print(result)