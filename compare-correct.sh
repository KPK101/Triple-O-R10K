echo "Comparing ground truth outputs to new processor"
source setup-paths.sh

truth_dir=./correct_output
output_dir=./output

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass_all=true
for source_file in programs/*.s programs/*.c; do
    if [ "$source_file" = "programs/crt.s" ]
    then
        continue
    fi
    program=$(echo "$source_file" | cut -d '.' -f1 | cut -d '/' -f 2)

    echo -e "\nRunning $program"
    # Using -B to always create fresh output
    make $program.out

    echo "Comparing writeback output for $program"
    truth_wb=$truth_dir/$program.wb
    output_wb=$output_dir/$program.wb
    diff_wb=$(diff $truth_wb $output_wb)
    if [ "$diff_wb" ]
    then
        echo -e "${RED}Incorrect writeback output for $program${NC}"
    fi

    echo "Comparing pipeline output for $program"
    truth_ppln=$truth_dir/$program.ppln
    output_ppln=$output_dir/$program.ppln
    diff_ppln=$(diff $truth_wb $output_wb)
    if [ "$diff_wb" ]
    then
        echo -e "${RED}Incorrect writeback output for $program${NC}"
    fi

    echo "Comparing memory output for $program"
    truth_out=$truth_dir/$program.out
    output_out=$output_dir/$program.out
    diff_out=$(diff <(grep @@@ $truth_out) <(grep @@@ $output_out))
    if [ "$diff_out" ]
    then
        echo -e "${RED}Incorrect memory output for $program${NC}"
    fi


    if [ "$diff_wb" ] || [ "$diff_ppln" ] || [ "$diff_out" ]
    then
        pass_all=false
        echo -e "${RED}Failed $program${NC}"

        # exit on first fail
        # exit 1
    else
        echo -e "${GREEN}Passed $program${NC}"
    fi
done

if [ "$pass_all" == true ]
then
    echo -e "\n${GREEN}Passed all programs${NC}"
else
    echo -e "\n${RED}Failed some programs${NC}"
fi
