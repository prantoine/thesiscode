import os
import json
import csv
import shutil
from sys import platform

def csv_as_list(file:str) -> list:
    '''
    Returns an array of arrays, each one containing a row, of a given file. Handles opening the file.
    '''

    array_of_rows = []
    with open(file) as csv_file:
        csv_reader = csv.reader(csv_file)    
        for row in csv_reader:
            array_of_rows.append(row)
    
    return array_of_rows

def merge_csv_files(csv_files: list, output_location: str, input_location: str) -> None:
    '''
    Takes a list of csv files to be merged, gives the rows of each file and appends it to a 
    'parrent' array which contains all rows (not necessarily in the right order).
    Generates a new csv file, containing merging data. Finally, removes the files used for merging.
    '''
    
    rows_merged_files = []
    
    for file in csv_files:
        rows_in_file = csv_as_list(file)
        rows_merged_files.append(rows_in_file)

    rows_merged_files = [item for sublist in rows_merged_files for item in sublist]

    os.chdir(output_location)

    with open(f"opium_prices_{csv_files[0][4:6]}.csv", mode="w") as merged_csv:
        writer = csv.writer(merged_csv)
        writer.writerows(rows_merged_files)

    os.chdir(input_location)
        
    for file in csv_files:
        os.remove(file)
    
    return None

if __name__ == "__main__":

    print(f'Starting program... at {os.getcwd()}')

    print(os.getcwd())
    with open("./code/SETTINGS_CSV.json") as json_settings:
        settings = json.load(json_settings)
    
    #run the script for each year individually. for example years = ["17"]
    years = []

    for year in years:
        
        #settings is a file which contains the path for mac and linux.
        
        inputs_path = os.path.expanduser('~')
        for folder in settings[platform]['input']:
            inputs_path = os.path.join(inputs_path, folder)
        inputs_path = os.path.join(inputs_path, year)
        
        output_path = os.path.expanduser('~')
        for folder in settings[platform]['output']:
            output_path = os.path.join(output_path, folder)
            if folder == 'output_extraction':
                output_path = os.path.join(output_path, year)
            
        os.chdir(inputs_path)
        print(os.getcwd())

        files_to_treat = [ file for file in os.listdir(inputs_path) if file[-3:] == 'csv' ]
        merge_csv_files(csv_files=files_to_treat, output_location=output_path, input_location=inputs_path)
