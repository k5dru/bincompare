#/bin/bash - 

# test 1:  
echo 
echo test 1:  compare files that match

# create a file with lrecl 357 such that
#  21000 records match

dd if=/dev/urandom of=tempfile bs=357 count=21000  status=none
cp tempfile file1.dat
cp tempfile file2.dat
rm tempfile

# expect match: 
echo starting compare
time ./bincompare.sh file1.dat file2.dat 357

if [ $? != 0 ]; then 
	echo test failed - expected return value 0 from bincompare.sh
	exit 1
else
	echo test 1 passed 
fi

# test 2:  
echo
echo test 2:  compare files that do not match late in the file

# create a file with lrecl 357 such that
#  18000 records match
#  1 records mismatch 
#  2999 records then match

dd if=/dev/urandom of=tempfile bs=357 count=18000 status=none
cp tempfile file1.dat
cp tempfile file2.dat

# add a single different record
dd if=/dev/urandom bs=357 count=1 status=none  >> file1.dat
dd if=/dev/urandom bs=357 count=1 status=none  >> file2.dat

# add more same records
dd if=/dev/urandom of=tempfile bs=357 count=2999 status=none
cat tempfile >> file1.dat
cat tempfile >> file2.dat
rm tempfile

# expect mismatch: 
echo starting compare
time ./bincompare.sh file1.dat file2.dat 357

if [ $? != 1 ]; then 
	echo test failed - expected return value 1 from bincompare.sh
	exit 1
else
	echo test 2 passed 
fi

