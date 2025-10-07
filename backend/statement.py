from docx import Document
import pandas as pd
from recommend import FinancialAnalyzer  as fa
import copy

def extract(df,date,debit,credit,balance):
    required_cols = [date, debit, credit, balance]
    if not all(col in df.columns for col in required_cols):
        raise ValueError(f"Required columns {required_cols} not found in DataFrame")

    li = []
    for i in df[balance]:
        clean_val = str(i).replace(',', '').strip()
        if clean_val == '':
            li.append(0.0)
        else:
            try:
                li.append(float(clean_val))
            except ValueError:
                li.append(0.0)
    df[balance] = li

    li = []
    for i in df[date]:
        dic = {'01':'Jan','02':'Feb','03':'Mar','04':'Apr','05':'May','06':'Jun','07':'Jul','08':'Aug','09':'Sep','10':'Oct','11':'Nov','12':'Dec'}
        val = str(i).replace('\n',' ')
        val = val.replace('-',' ')
        val = val.replace('/',' ')
        val = val.strip()
        mon = val.split(' ')
        try:
            if len(mon) == 3 and mon[1] in dic:
                mon[1] = dic[mon[1]]
                if len(mon[2]) == 2:
                    mon[2] = '20'+mon[2]
                val = ' '.join(mon)
        except IndexError:
            pass  # Keep original val if parsing fails
        li.append(val)
    df[date] = li

    li = []
    for i in df[debit]:
        clean_val = str(i).replace(',', '').strip()
        if clean_val == '':
            li.append(0)
        else:
            try:
                li.append(float(clean_val))
            except ValueError:
                li.append(0)
    df[debit] = li

    li = []
    for i in df[credit]:
        clean_val = str(i).replace(',', '').strip()
        if clean_val == '':
            li.append(0)
        else:
            try:
                li.append(float(clean_val))
            except ValueError:
                li.append(0)
    df[credit] = li
    return pd.DataFrame({'Date':df[date],'Debit':df[debit],'Credit':df[credit],'Balance':df[balance]})

# Function to read tables and convert to a combined DataFrame
def read_and_concat_tables(file_path,  bank):
    # Load the document
    doc = Document(file_path)
    all_tables = []
    for table in doc.tables:
        # Extract each row in the table as a list of cell text
        table_data = []
        for row in table.rows:
            row_data = [cell.text for cell in row.cells]
            table_data.append(row_data)

        # Convert table data to a DataFrame
        df = pd.DataFrame(table_data)

        # Reset the header and ensure columns are consistent
        df.columns = [f"Column {i+1}" for i in range(len(df.columns))]  # Rename columns
        df = df[1:]  # Skip the header row in the data, if applicable

        # Append each table's DataFrame to the list
        all_tables.append(df)

    # Concatenate all DataFrames into a single DataFrame
    combined_df = pd.concat(all_tables, ignore_index=True)
    ob = fa()
    # Display the combined DataFrame
    if bank == 'sbi':
        required_cols = ['Column 1', 'Column 5', 'Column 6', 'Column 7']
        if not all(col in combined_df.columns for col in required_cols):
            raise ValueError(f"Required columns {required_cols} not found in SBI statement")
        val = extract(combined_df,'Column 1','Column 5','Column 6','Column 7')
        val = val[val['Date'].str.match(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$', na=False)]
        chart_data = copy.deepcopy(val)
        analysis = ob.analyse(val)
        return [chart_data, analysis]

    elif bank == 'canara':
        required_cols = ['Column 2', 'Column 6', 'Column 7', 'Column 8']
        if not all(col in combined_df.columns for col in required_cols):
            raise ValueError(f"Required columns {required_cols} not found in Canara statement")
        sliced_df = combined_df.iloc[10:combined_df.shape[0]-2]
        val = extract(sliced_df,'Column 2','Column 6','Column 7','Column 8')
        val = val[val['Date'].str.match(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$', na=False)]
        chart_data = copy.deepcopy(val)
        analysis = ob.analyse(val)
        return [chart_data, analysis]

    elif bank == 'axis':
        required_cols = ['Column 1', 'Column 4', 'Column 5', 'Column 6']
        if not all(col in combined_df.columns for col in required_cols):
            raise ValueError(f"Required columns {required_cols} not found in Axis statement")
        sliced_df = combined_df.iloc[1:combined_df.shape[0]-2]
        val = extract(sliced_df,'Column 1','Column 4','Column 5','Column 6')
        val = val[val['Date'].str.match(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$', na=False)]
        chart_data = copy.deepcopy(val)
        analysis = ob.analyse(val)
        return [chart_data, analysis]

    elif bank == 'hdfc':
        if 'Column 7' not in combined_df.columns:
            raise ValueError("Required column 'Column 7' not found in HDFC statement")
        combined_df = combined_df[combined_df['Column 7'] != '']
        required_cols = ['Column 1', 'Column 5', 'Column 6', 'Column 7']
        if not all(col in combined_df.columns for col in required_cols):
            raise ValueError(f"Required columns {required_cols} not found in HDFC statement")
        sliced_df = combined_df.iloc[1:combined_df.shape[0]-4]
        val = extract(sliced_df,'Column 1','Column 5','Column 6','Column 7')
        val = val[val['Date'].str.match(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$', na=False)]
        chart_data = copy.deepcopy(val)
        analysis = ob.analyse(val)
        return [chart_data, analysis]
    else:
        required_cols = ['Column 1', 'Column 5', 'Column 6', 'Column 7']
        if not all(col in combined_df.columns for col in required_cols):
            raise ValueError(f"Required columns {required_cols} not found in statement")
        val = extract(combined_df,'Column 1','Column 5','Column 6','Column 7')
        val = val[val['Date'].str.match(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$', na=False)]
        chart_data = copy.deepcopy(val)
        analysis = ob.analyse(val)
        return [chart_data, analysis]

