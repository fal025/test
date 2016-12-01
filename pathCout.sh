
# First we grab the input params...
#while getopts ":v:g:r:" opt; do
#  case $opt in
#    v) voc_id=$OPTARG ;;
#    g) voc_file=$OPTARG ;;
#    r) voc_rep_file=$OPTARG ;;
#  esac
#done

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#ASNLIB=$DIR

#cd $DIR/$1

GDIR=GradingData
mkdir -p $GDIR
#vocSaveSubData $GDIR

{

echo "Running the checkpoint grading script..."
echo ""


totalScore=0

###################################################################

# function for printing what the common exit values are
# $1 should be the return value
printExitCode ()
{
  # TODO add in cases for common exit values
  if [ -n "$1" ]; then
    echo "Exit code is $1"
  fi
}


# function for running the test cases
# $1 should be the name of the file to test
runTest ()
{
  echo ""
  echo "Testing ${1}.tsv ..."
  echo "time taken:"

  time timeout 50 ./pathfinder $ASNLIB/${1}.tsv u $ASNLIB/${1}_pair.tsv ${1}_uout.tsv > temp.txt 2>&1

  RTNVAL=$?
  printExitCode $RTNVAL

  echo "Verifying your paths..."
  numLinesPair=(`wc -l $ASNLIB/${1}_pair.tsv`)
  numLinesOut=(`wc -l ${1}_uout.tsv`)

  if [ "${numLinesPair[0]}" == "${numLinesOut[0]}" ]; then

    $ASNLIB/modPath.sh ${1}_uout.tsv ${1}_uout_mod.tsv
    $ASNLIB/pathverifier $ASNLIB/${1}.tsv u $ASNLIB/${1}_pair.tsv ${1}_uout_mod.tsv ${1}_uscore.txt > temp.txt 2>&1

	#cat temp.txt
    CURRSCORE=`tail -1 ${1}_uscore.txt`

    if [ "$CURRSCORE" == "1" ]; then
      echo "${1}.tsv test PASSED (+1)."
    elif [ "$CURRSCORE" == "0.5" ]; then
      head -50 temp.txt
      echo "Looks like one or more of your paths weren't shortest."
      echo "You will still get half the credit for this test file (+0.5)."
    elif [ "$CURRSCORE" == "0" ]; then
      head -50 temp.txt
      echo "Looks like one or more of your paths weren't correct."
      echo "Sorry, but no points for this test file (+0)."
    else
      echo "If you see this message you may not have successfully created an output file."
    fi

  else

    echo "Number of lines in your paths file (${numLinesOut[0]}) does not match the pair file (${numLinesPair[0]})"
    echo "Sorry, but no points for this test file (+0)."
	echo "Here is what was printed to stdout and stderr by pathfinder:"
	echo "\"\""
	head -50 temp.txt
	echo "\"\""
    CURRSCORE=0

  fi


  cp $ASNLIB/${1}.tsv $ASNLIB/${1}_pair.tsv ${1}_uout.tsv ${1}_uscore.txt $GDIR >temp.txt 2>&1
  rm ${1}_uout.tsv ${1}_uout_mod.tsv ${1}_uscore.txt >temp.txt 2>&1

  totalScore=`echo "$totalScore + $CURRSCORE" | bc`
}

##################################################################


# Check compilation #

make clean > temp.txt

make pathfinder > temp.txt 2>&1

if [[ $? != 0 ]] ; then

  echo "Code doesn't compile. Showing the first 50 lines of"
  echo "\"make pathfinder\" output:"
  head -50 temp.txt
  echo "Exiting"
    
  # make clean > temp.txt
  # rm -f temp.txt

fi 

echo "Code compiles successfully! (warnings may still exist)"

##################################################################

# Create an array of test filenames
declare -a testFiles=("2-node_simple" "3-node_simple" "3-node_3-movie" "medium_weighted_graph" "movie_casts_grading")

# Get length of array
testFilesLen=${#testFiles[@]}

echo "Running tests..."
  
for (( i=0; i < ${testFilesLen}; i++ )); do
  runTest ${testFiles[$i]} $i
done

echo "Done running tests."


rm tmpOut1.txt tmpOut2.txt > /dev/null 2>&1

echo "Total Score for Checkpoint: $totalScore"

} 2>&1 | tee $GDIR/checkpointGradeScriptOutput.txt

