import os

def avoid_overwriting(path: str) -> bool:
    
    if os.listdir(path):
        
        if len(os.listdir(path)) in [1,2]:
            print(f"Allow extraction to {path}.")
            return True
        elif len(os.listdir(path)) > 2:
            print("More than 2 files detected: must have been extracted and moved. Aborting.")
            return False
        else:
            print("Error, aborting.")
            return False                
    else:
        print("Nothing found. Extracting...")
        return True

def extract_pages(file_instruction: dict) -> None:
    
    for month_yr, pages in file_instruction.items():
        if pages:
            for page in pages:
                os.system(f"skimpdf extract {month_yr}.pdf {month_yr}-p{page}.pdf -page {page}")
        else:
            print("Instruction: no extraction for this month. Skipping...")
            
    return None

if __name__ == "__main__":

    #run the script for each year individually. for example years = ["17"]
    years = []

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
        extract_year = avoid_overwriting(raw_pdfs_location)
        
        if extract_year:
            
            os.chdir(os.path.join(raw_pdfs_location, "full_reports"))
            
            extracting_instructions = {
                "jan_"+year: [],
                "feb_"+year: [],
                "mar_"+year: [],
                "apr_"+year: [],
                "may_"+year: [],
                "jun_"+year: [],
                "jul_"+year: [],
                "aug_"+year: [],
                "sep_"+year: [],
                "oct_"+year: [],
                "nov_"+year: [],
                "dec_"+year: []
            }     

            extract_pages(file_instruction=extracting_instructions)