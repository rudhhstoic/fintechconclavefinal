import pandas as pd
import psycopg2

# Load CSV data into a DataFrame
csv_file_path = r'D:\Project\fintechconclavefinal\backend\updateddata.csv'
df = pd.read_csv(csv_file_path)

# Database connection details
db_config = {
    'dbname': 'Archons',
    'user': 'postgres',
    'password': 'Archana',
    'host': 'localhost',  # or your database server IP
    'port': '5432'        # default PostgreSQL port
}

# Connect to PostgreSQL
try:
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    print("Connected to the database successfully.")

    # Insert each row of the DataFrame into the table
    for _, row in df.iterrows():
        insert_query = """
INSERT INTO mutual_funds (
    name, category, amc, current_value, return_per_annum,
    expense_ratio, age, id, category_main, category_sub,
    return1month, return3month, return6month, crisil
) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

        

        # Convert row data to a tuple and insert
        cursor.execute(insert_query, tuple(row))

    # Commit the transaction
    conn.commit()
    print("Data inserted successfully.")

except Exception as e:
    print("Error:", e)
    conn.rollback()

finally:
    # Close the connection
    cursor.close()
    conn.close()
