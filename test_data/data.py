import csv
import random
from datetime import datetime, timedelta
import argparse
import sys

def generate_row(index):
    """Generate a single row of air quality data"""
    
    # Random coordinates
    lat = round(random.uniform(-90, 90), 6)
    lon = round(random.uniform(-180, 180), 6)
    
    # Random date/time in 2020
    start_date = datetime(2020, 1, 1)
    random_hours = random.randint(0, 8760)  # Hours in a year
    date = start_date + timedelta(hours=random_hours)
    utc = date.strftime('%-m/%-d/%y %-H:00')
    
    # Air quality parameters
    parameters = ['OZONE', 'PM2.5', 'PM10', 'CO', 'NO2', 'SO2']
    parameter = random.choice(parameters)
    
    # Units
    units = ['PPB', 'UG/M3', 'PPM']
    unit = random.choice(units)
    
    # Concentrations and AQI
    raw_concentration = random.randint(0, 100)
    concentration = int(raw_concentration * 1.15)
    aqi = random.randint(0, 200)
    category = random.randint(1, 5)
    
    # Site information
    site_names = [
        '16th and Whitmore',
        'Downtown Monitor',
        'Riverside Station',
        'Industrial Park',
        'Suburban Center',
        'Airport Site',
        'North District',
        'South Valley'
    ]
    site_name = random.choice(site_names)
    
    agencies = [
        'Douglas County Health Department (Omaha)',
        'EPA Regional Office',
        'State Environmental Agency',
        'City Air Quality Division'
    ]
    site_agency = random.choice(agencies)
    
    # IDs
    aqs_id = random.randint(100000000, 999999999)
    full_aqs_id = f"{random.uniform(8.4e11, 8.5e11):.5E}"
    
    return [lat, lon, utc, parameter, concentration, unit, 
            raw_concentration, aqi, category, site_name, 
            site_agency, aqs_id, full_aqs_id]

def generate_csv(filename, num_rows):
    """Generate CSV file with specified number of rows"""
    
    print(f"Generating {num_rows:,} rows...")
    
    headers = [
        'Latitude', 'Longitude', 'UTC', 'Parameter', 'Concentration', 
        'Unit', 'Raw Concentration', 'AQI', 'Category', 'Site Name', 
        'Site Agency', 'AQS ID', 'Full AQS ID'
    ]
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        
        # Generate rows with progress indicator
        for i in range(num_rows):
            row = generate_row(i)
            writer.writerow(row)
            
            # Progress indicator
            if (i + 1) % 10000 == 0 or (i + 1) == num_rows:
                progress = ((i + 1) / num_rows) * 100
                print(f"Progress: {progress:.1f}% ({i + 1:,}/{num_rows:,} rows)", end='\r')
    
    print(f"\n✓ Successfully generated {filename} with {num_rows:,} rows!")

def main():
    parser = argparse.ArgumentParser(
        description='Generate CSV files with air quality monitoring data',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python csv_generator.py --rows 1000
  python csv_generator.py --rows 10000 --output data_10k.csv
  python csv_generator.py --size 1M
  
Size shortcuts:
  1K  = 1,000 rows
  10K = 10,000 rows
  100K = 100,000 rows
  1M = 1,000,000 rows
  10M = 10,000,000 rows
        """
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--rows', type=int, help='Number of rows to generate')
    group.add_argument('--size', type=str, choices=['1K', '10K', '100K', '1M', '10M'],
                      help='Predefined size (1K, 10K, 100K, 1M, 10M)')
    
    parser.add_argument('--output', type=str, help='Output filename (default: air_quality_data_<rows>_rows.csv)')
    
    args = parser.parse_args()
    
    # Determine number of rows
    if args.size:
        size_map = {
            '1K': 1000,
            '10K': 10000,
            '100K': 100000,
            '1M': 1000000,
            '10M': 10000000
        }
        num_rows = size_map[args.size]
    else:
        num_rows = args.rows
    
    # Determine output filename
    if args.output:
        filename = args.output
    else:
        filename = f'air_quality_data_{num_rows}_rows.csv'
    
    # Generate the CSV
    try:
        generate_csv(filename, num_rows)
    except KeyboardInterrupt:
        print("\n\n✗ Generation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()