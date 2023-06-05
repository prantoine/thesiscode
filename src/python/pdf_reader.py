import camelot
import os
import shutil
from zipfile import ZipFile

def move_pages_to_folder(raw_pdfs_loc:str , reduced_pdfs_loc:str, files:list) -> None:
    '''
    Moves reduced pdf files into the parent folder to differenciate them from the full 
    pdf reports.
    '''

    try:
        for file in files:
            shutil.move(os.path.join(raw_pdfs_loc, file), os.path.join(reduced_pdfs_loc))
    except:
        print("Could not move files... aborting.")
    return None

def avoid_overwriting(path: str) -> bool:
    '''
    Checks the extraction output folder, and prevents extraction of zip files if other
    files are already detected in the output folder (since they must already be extracted).
    '''
    
    if os.listdir(path):
        
        if len(os.listdir(path)) == 1:
            if os.listdir(path)[0] == '.DS_Store':
                return True
            else:
                print("Unexpected file in folder ! Aborting")
                return False
        elif len(os.listdir(path)) == 2:
                print("Contains no extracted output, program carries on.")
                return True                
    else:
        return True
    
def zip_extract(file: str, year: str) -> None:
    '''
    Simple function which extracts a zip file and removes it after extraction.
    '''
    
    with ZipFile(file, 'r') as zip:
        zip.extractall()
    
    os.remove(file)
    return None

def extract_from_pdf(year: str, output_path: str) -> None:
    '''
    Given the output path, extract the tables from each 'pdf' file found in the current directory,
    i.e. 'raw_pdfs_location'. Change the directory to the output path, and extract each zip file
    generated in the extraction. Keep the csv file and remove the zip to avoid overloading.
    '''

    for pdf in os.listdir():
        if pdf[-3:] == "pdf":

            print(f"Treating {pdf}...")   
            tables = camelot.read_pdf(pdf)
            tables.export(os.path.join(output_path, f"{pdf[:-4]}.csv"), f='csv', compress=True)

        else:
            print("Non pdf detected, skipping...")

    os.chdir(os.path.join(os.path.expanduser('~'),
                                           'school',
                                           'm2',
                                           'thesis',
                                           'output_extraction',
                                           year))

    for zipf in os.listdir():
        try:
            zip_extract(file=zipf, year=year)     
        except:
            print("Likely not a zip file, skipping...")

    return None
    
if __name__ == "__main__":
    
    years = [ str(i) for i in range(10,21) ]

    #run the script for each year individually. for example years = ["17"]
    years =[]
    for year in years:
        raw_pdfs_location = os.path.join(os.path.expanduser('~'),
                                           'school',
                                           'm2',
                                           'thesis',
                                           'pdf_reports',
                                           year)
        
        output_path = os.path.join(os.path.expanduser('~'),
                                           'school',
                                           'm2',
                                           'thesis',
                                           'output_extraction',
                                           year)
        os.chdir(raw_pdfs_location)
        
        extract_year = avoid_overwriting(output_path)

        if extract_year:
            move_pages_to_folder(raw_pdfs_loc=os.path.join(raw_pdfs_location, 'full_reports'), reduced_pdfs_loc=raw_pdfs_location, files=[file for file in os.listdir(os.path.join(raw_pdfs_location, 'full_reports')) if file[-6:-4] not in years and file != '.DS_Store'])
            print(f"Treating year {year}...")
            extract_from_pdf(year=year, output_path=output_path)

        elif year != years[-1]:
            print(f'This year has already been treated. Moving to year {int(year)+1}...')
        else:
            print("Last year reached and skipped.")
        