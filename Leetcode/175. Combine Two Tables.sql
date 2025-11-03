# Mysql, PostgreSQL, SQL Server, SQLite, Oracle

select p.firstName, p.lastName, a.city, a.state
from Person p
left join Address a
on p.personId = a.personId;

# pandas

import pandas as pd

def combine_two_tables(person: pd.DataFrame, address: pd.DataFrame) -> pd.DataFrame:
    result = pd.merge(person, address, on='personId', how='left')[['firstName', 'lastName', 'city', 'state']];
    return result;