#!/bin/bash - 
# set -x 

# task: compare two binary files of any size, and indicate if same or different.
#   same files:  return value 0 
#   different files:  return value 1 
#      for different files, create a subset of records leading up to the difference
#      and including the first difference
#      for easy analysis

# requires:  dd diffutils hexdump sha256sum stat

# author:  James Lemley, July 11 2022 - prototype 


# define a function to compare only one block of a file

function fcompare()
{ 
    file1=${1}
    file2=${2}
    blocksize=${3}
    blocknum=${4}

    hash1=$(dd if=${file1} bs=${blocksize} skip=${blocknum} count=1 status=none | sha256sum)

    if [ $? -ne 0 ]; then 
        echo "$0: error hashing if=${file1} bs=${blocksize} skip=${blocknum}"
        return 1
    fi
    hash2=$(dd if=${file2} bs=${blocksize} skip=${blocknum} count=1 status=none | sha256sum)
    if [ $? -ne 0 ]; then
        echo "$0: error hashing if=${file2} bs=${blocksize} skip=${blocknum}"
        return 1
    fi

    if [ "${hash1}" == "${hash2}" ]; then
        return 0 
    else 
        return 1
    fi
}

# make sure arguments are OK

# expect file1 file2 lrecl
if [ $# -lt 3 ]; then 
    echo "Usage: $0 file1 file2 lrecl"
    echo " where file1 and file2 are the files to compare "
    echo " and lrecl is the record length in decimal  "
    exit 1
fi

if [ ! -f "$1" ]; then 
    echo "$1 is not a file"
    exit 1
fi

if   [ ! -f "$2" ]; then 
    echo "$2 is not a file"
    exit 1
fi

# assign arguments 

retval=0
file1=${1}
file2=${2}
lrecl=${3}

# calculate blocksize as smallest number of records that makes an even blocksize over 1MB 
# 1MB is arbitarary - too small and we have poor performance, too large and 
#      it becomes more difficult to analyze block differences

blockrecords=$((1048576 / ${lrecl}))
if [ $((${blockrecords} * ${lrecl})) -lt 1048576 ]; then 
    blockrecords=$((${blockrecords} + 1))
fi

blocksize=$((${blockrecords} * ${lrecl}))

file1size=$(stat -c %s ${file1})
file2size=$(stat -c %s ${file2})

# warn if files are different size
if [ $file1size -ne $file2size ]; then 
    echo $0: warning - files are different sizes; comparing only equal sized portions
    retval=1
fi

if [ ${file1size} -lt ${file2size} ]; then 
    filesize=$file1size
else   
    filesize=$file2size
fi

blocknum=0
while [ $((${blocknum} * ${blocksize})) -lt ${filesize} ]; do 
    fcompare ${file1} ${file2} ${blocksize} ${blocknum} 
    if [ $? -ne 0 ]; then 
        offset=$((${blocknum} * ${blocksize}))
        echo "$0: differences in block ${blocknum} at offset $offset and spanning $blocksize bytes" 
        retval=1

        # save off the differences 
        hexdump -n ${blocksize} -s $((${blocknum} * ${blocksize})) ${file1} > file1.${offset}.txt
        hexdump -n ${blocksize} -s $((${blocknum} * ${blocksize})) ${file2} > file2.${offset}.txt
        echo "$0: to see differences, run sdiff -s file1.${offset}.txt file2.${offset}.txt"
        break
    fi
    blocknum=$(($blocknum + 1))
done

exit ${retval}