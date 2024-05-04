source setup-paths.sh

for source_file in programs/*.s programs/*.c; do
    if [ "$source_file" = "programs/crt.s" ]
    then
        continue
    fi
    program=$(echo "$source_file" | cut -d '.' -f1 | cut -d '/' -f 2)
    echo "Running $program"
    make $program.out
done