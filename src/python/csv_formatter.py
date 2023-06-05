import os
import csv

def get_format(csv_files: list) -> dict:
    '''
    Returns the number of rows for each CSV table (one for each month) of the year of interest.
    '''
    
    row_counts = {}
    for file in csv_files:
        with open(file) as f:

            csv_reader = csv.reader(f, delimiter=',') 
            line_count = 0
            all_values =[]

            for row in csv_reader:
                line_count += 1
                all_values.append(row)
            non_empty = False

            for row in all_values:
                for value in row:
                    if len(value) > 0:
                        non_empty = True
            print(f"The file {file} is non-empty: {non_empty}")
            if not non_empty:
                os.remove(file)
            else:
                row_counts[file] = line_count    

    return row_counts

def uniform_change_format(csv_files: dict) -> None:
    '''
    Changes the position of rows so that they are all the same for clean merging. Writes to the file and removes the old one.
    '''

    for file, n_rows in csv_files.items():
        
        fixed_rows = []
        with open(file, mode='r') as csv_file:
            csv_reader = csv.reader(csv_file)
            print(n_rows)
            
            #this condition varies from year to year. one has to check manually what the long file format length is for each year.
            if n_rows == 20: 
                print(f"File {file} has long format. Formatting...")

                for row in csv_reader:
                    if not fixed_rows:
                        for j in range(0, len(row)):
                            fixed_rows.append(list())

                    for index, value in enumerate(row):
                        fixed_rows[index].append(value)
                        
                result = [ list() for row in range(0,len(fixed_rows))]

                for index, row in enumerate(fixed_rows):
                    result[index] = fixed_rows[-index-1]

                with open(file, mode="w") as csv_file:
                    writer = csv.writer(csv_file)
                    writer.writerows(result)
            elif n_rows not in [4, 8]:
                print(f"File {file} not containing the right table, skipping...")
                os.remove(file)
            elif n_rows == 8:
                print(f"File {file} already ok, skipping...")
         
        print(f"File {file} done. Moving on... \n")

    return None

def clean_table(csv_files: list, inputs_location: str, output_location:str) -> None:
    '''
    Generates formatted tables from 'raw' list of csv files. Adds a year-date column and 
    moves the modified table to the 'output' folder.
    '''
    
    months = [
        "jan",
        "feb",
        "mar",
        "apr",
        "may",
        "jun",
        "jul",
        "aug",
        "sep",
        "oct",
        "nov",
        "dec"
    ]

    month_correspondance = {k: (str(v+1) if len(str(v+1)) == 2 else "0"+str(v+1)) for v,k in enumerate(months)}

    print(csv_files)
    for file in csv_files:
        
        print(file)
        os.chdir(inputs_location)    
        date = f"{str(20) + file[4:6]}-{month_correspondance[file[0:3]]}"
        
        with open(file) as csv_file:
            csv_reader = csv.reader(csv_file)
            all_rows = []

            for row in csv_reader:
               all_rows.append(row)

            print(all_rows)
            for remove_row in [-1, 1, 0]:
                all_rows.pop(remove_row)

            for remaining_row in all_rows:
                for col_to_delete in [3, 1]:
                    remaining_row.pop(col_to_delete)
                remaining_row.insert(0,date)
            print(all_rows) 

        with open(file, mode='w') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerows(all_rows)
        
    return None

if __name__ == "__main__":

    years = [str(i) for i in range(10,21)]

    #run the script for each year individually. for example years = ["17"]
    years = []

    for year in years:
        
        indiv_files_location = os.path.join(os.path.expanduser('~'),
                                            'school',
                                            'm2',
                                            'thesis',
                                            'output_extraction',
                                            year)
        
        output_location = os.path.join(indiv_files_location,
                                       'merged_files')
    
        os.chdir(indiv_files_location)
        rows_in_file = get_format(csv_files=[ file for file in os.listdir() if file not in  ["merged_files", '.DS_Store']])
        uniform_change_format(csv_files=rows_in_file)
        
        files_to_treat = [ file for file in os.listdir(indiv_files_location) if file[-3:] == 'csv' ]