# MYSQL, SQLITE

SELECT 
    IFNULL(
        (SELECT DISTINCT salary
         FROM Employee
         ORDER BY salary DESC
         LIMIT 1 OFFSET 1),
    NULL) AS SecondHighestSalary;

# POSTGRESQL

SELECT 
    COALESCE(
        (SELECT DISTINCT salary
         FROM Employee
         ORDER BY salary DESC
         OFFSET 1 LIMIT 1),
    NULL) AS SecondHighestSalary;

# Pandas

import pandas as pd

def second_highest_salary(employee: pd.DataFrame) -> pd.DataFrame:
    sorted_salaries = employee['salary'].drop_duplicates().sort_values(ascending=False)
    second_highest_salarys = sorted_salaries.iloc[1] if len(sorted_salaries) > 1 else None
    return pd.DataFrame({'SecondHighestSalary': [second_highest_salarys]})