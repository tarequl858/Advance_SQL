# MYSQL

CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
DECLARE num INT;
SET num = N - 1;
  RETURN (
        SELECT IFNULL(
            (
                SELECT DISTINCT salary
                FROM Employee
                ORDER BY salary DESC
                LIMIT 1 OFFSET num
            ),null
        )
  );
END

# POSTGRESQL

CREATE OR REPLACE FUNCTION NthHighestSalary(N INT) RETURNS TABLE (Salary INT) AS $$
BEGIN
  RETURN QUERY (
    -- Write your PostgreSQL query statement below.
    SELECT COALESCE(
    (SELECT DISTINCT e.salary
    FROM Employee as e
    ORDER BY e.salary DESC
    LIMIT 1 OFFSET N - 1),null)
  );
END;
$$ LANGUAGE plpgsql;

# Pandas

import pandas as pd

import pandas as pd

def nth_highest_salary(employee: pd.DataFrame, N: int) -> pd.DataFrame:
    sorted_salaries = employee['salary'].drop_duplicates().sort_values(ascending=False)
    if N>0:
        if len(sorted_salaries) >= N:
            nth_highest_salary = sorted_salaries.iloc[N - 1]
        else:
            nth_highest_salary = None
    else:
        nth_highest_salary = None
    return pd.DataFrame({f'getNthHighestSalary({N})': [nth_highest_salary]})