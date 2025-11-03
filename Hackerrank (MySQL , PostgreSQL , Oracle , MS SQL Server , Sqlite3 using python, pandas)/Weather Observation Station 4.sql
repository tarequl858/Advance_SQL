# MYSQL, PostgreSQL, SQL Server, Oracle, SQLite

SELECT (COUNT(CITY)-COUNT(DISTINCT(CITY)))
FROM STATION;

# PYTHON (using SQLite)

import sqlite3
import pandas as pd
conn = sqlite3.connect('world.db')
query = """
SELECT (COUNT(CITY)-COUNT(DISTINCT(CITY)))
FROM STATION;
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
result = df.loc['CITY'].count() - df['CITY'].nunique()
print(result)