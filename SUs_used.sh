#!/bin/bash

##
## FILE: SUs_used.sh
##
## DESCRIPTION:
## This Script is used to get the number of service unites used by the user/users and also saves the user details who used the over 40k service units over the period of time
## ----The number of days can be changed here "(suuser $USER 90)"
##
##
## AUTHOR: Prudhvi Donepudi
##
## DATE: 24/06/2024
## 
## VERSION: 1.0 (Stable)
##
## Usage
## To execute the code run : ./SUs_used.sh users.csv output_file1 output_file2
## Here the users.csv is the users data with email and output_file1 stores the Sus used by each user and output_file2 stores the users over 40K Sus
##
##
##

# Check if a filename is provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 users.csv output_file output_k"
    exit 1
fi

# CSV file containing the list of users
USER_FILE=$1

# Output file to save the results
OUTPUT_FILE=$2

# Output file for the users over 40k only emails
OUTPUT_k=$3

# Check if the file exists
if [ ! -f $USER_FILE ]; then
    echo "File $USER_FILE not found!"
    exit 1
fi

# Temporary file to store users with more than 40,000 SUs
TEMP_FILE=$(mktemp)

TEMP_FILE1=$(mktemp)


# Clear the output file if it exists, or create it if it doesn't
> $OUTPUT_FILE

# Loop through each user in the CSV file
while IFS= read -r USER; do
    echo "Fetching Service Units for user: $USER" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    
    # Fetch the Service Units for the user over the last 90 days
    OUTPUT=$(suuser $USER 90)
    
    # Check if used SUs is more than 40,000 and save to temporary file
    echo "$OUTPUT" | awk -F'|' 'NR>1 && $6 > 40000 {print $2 "," $3 "," $6}' >> $TEMP_FILE
    echo "$OUTPUT" | awk -F'|' 'NR>1 && $6 > 40000 {print $3}' | grep -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}' | awk '!seen[$0]++'  >> $TEMP_FILE1
    # Append the fetched output to the output file if more than 40,000 SUs
    if echo "$OUTPUT" | awk -F'|' 'NR>1 && $6 > 40000' | grep -q "."; then
        echo "$OUTPUT" >> $OUTPUT_FILE
    fi
    
    echo "" >> $OUTPUT_FILE
    
    


done < "$USER_FILE"




# Print users with more than 40,000 SUs to the output file
echo "Users with more than 40,000 SUs:" >> $OUTPUT_FILE
cat $TEMP_FILE >> $OUTPUT_FILE

#Print emails of 40k users
> $OUTPUT_k
cat $TEMP_FILE1 >> $OUTPUT_k




# Clean up temporary file
rm $TEMP_FILE
rm $TEMP_FILE1


echo "Service Units data saved to $OUTPUT_FILE"
echo "Over 40K to $OUTPUT_k"
