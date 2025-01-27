#!/bin/bash


##
## FILE: efficiency_check.sh
##
## DESCRIPTION:
## Script is used to get the Average CPU and Memory Efficiency of a prticular user for the COMPLETED jobs in the alpine of the user.
## 
## AUTHOR: Prudhvi Donepudi
##
## DATE: 24/06/2024
## 
## VERSION: 1.0 (Stable)
##
## Usage
## To executethe code run : ./efficiency_check.sh [ -u <username> | -l <user_list_file> ]
## -u <username> : This for the single user ------> ./efficiency_check.sh -u ram@colostate.edu
## -l <user_list_file> : This is for the list of users stored in a txt file -------> ./efficiency_check.sh -l test.txt
## The output will be saved to the efficiencies.csv in the current directory
##
##
## To get the data in specific date range there is "Start_date" and "end_date" arguments present in the code which can be changed as   ## per the requirements.

# Parse command line arguments
while getopts ":u:l:" opt; do
  case ${opt} in
    u )
      users+=("$OPTARG")
      ;;
    l )
      while IFS= read -r line; do
        users+=("$line")
      done < "$OPTARG"
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." 1>&2
      exit 1
      ;;
  esac
done

# If no users were provided, prompt the user to enter them
if [ ${#users[@]} -eq 0 ]; then
  echo "Enter user email addresses separated by spaces:"
  read -ra users
fi

# Start and end dates for job search
start_date="2023-07-01"
end_date="2023-08-01"


# Output file

output_file="efficiencies.csv"

echo "User,Average CPU Efficiency (%),Average Memory Efficiency (%)" > "$output_file"








# Loop through each user email and get completed jobs
for user in "${users[@]}"
do
 ##### echo "Completed jobs for $user:"
  job_ids=$(sacct --format=jobid,state --user="$user" --starttime="$start_date" --endtime="$end_date" -X | grep COMPLETED | awk '{print $1}')
  cpu_efficiencies=()
  memory_efficiencies=()
  for job_id in $job_ids
  do
   ### echo -n "CPU efficiency for job ID $job_id: "
    seff_output=$(seff $job_id)
    cpu_efficiency=$(echo "$seff_output" | grep '^CPU Efficiency' | awk '{print $3}')
    memory_efficiency=$(echo "$seff_output" | grep '^Memory Efficiency' | awk '{print $3}')
    if [[ "$cpu_efficiency" =~ ^[0-9]+(\.[0-9]+)?%$ ]]; then
     ####### echo "$cpu_efficiency"
      cpu_efficiencies+=("${cpu_efficiency%%%}")  # Add CPU efficiency value to array, removing the % symbol
    else
      echo "Warning: invalid CPU efficiency value ($cpu_efficiency)"
    fi

    if [[ "$memory_efficiency" =~ ^[0-9]+(\.[0-9]+)?%$ ]]; then
      memory_efficiencies+=("${memory_efficiency%%%}")  # Add memory efficiency value to array, removing the % symbol
    else
      echo "Warning: invalid memory efficiency value ($memory_efficiency)"
    fi
  done

  # Calculate average CPU efficiency
  if [ ${#cpu_efficiencies[@]} -gt 0 ]; then  # Check if array is not empty
    sum=0
    for cpu_efficiency in "${cpu_efficiencies[@]}"
    do
      sum=$(echo "$sum + $cpu_efficiency" | bc -l)
    done
    avg=$(printf "%.2f" $(echo "$sum / ${#cpu_efficiencies[@]}" | bc -l))
###    printf "Average CPU efficiency for $user: %.2f%%\n" "$avg"
  fi


    # Calculate average memory efficiency
  if [ ${#memory_efficiencies[@]} -gt 0 ]; then  # Check if array is not empty
    sum=0
    for memory_efficiency in "${memory_efficiencies[@]}"
    do
      sum=$(echo "$sum + $memory_efficiency" | bc -l)
    done
    avg_mem=$(printf "%.2f" $(echo "$sum / ${#memory_efficiencies[@]}" | bc -l))
####    printf "Average Memory efficiency for $user: %.2f%%\n" "$avg_mem"
  fi

  # Write to output file
  echo "$user,$avg,$avg_mem" >> "$output_file"
done

echo "Efficiency calculations complete. Results saved to $output_file."

