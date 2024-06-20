#!/bin/bash
# Script to add testsuites to the report
# Parameters
#   1 - AMITYPE
#   2 - AMIREGION
#   3 - testReport
#   4 - autodocsBaseDirectory

export AMITYPE=$1
export AMIREGION=$2
export testReport=$3
export autodocsBaseDirectory=$4
export junitName="${AMITYPE}-Release-Verify"
export junitTestFailures=0

export aRegions=( ap-northeast-1 ap-southeast-1 eu-central-1 eu-west-1 us-east-1 us-west-2 )

echo $autodocsBaseDirectory
echo ${autodocsBaseDirectory}
echo $@

echo "Reviewing status of services/tools..."
cat ${autodocsBaseDirectory}/reports/ReleaseVerificationServiceStatus.txt

echo "Creating list of test cases..."
for region in ${aRegions[@]}; do
    echo "${region}" >> ${AMITYPE}-Release-Verify.txt
done
echo "Test case list generated..."

echo "Identifying the number of test cases found..."
junitTestCases=$(cat ${AMITYPE}-Release-Verify.txt | wc -l)

echo "Generating report"
cp ${autodocsBaseDirectory}/templates/junitReport.template.xml ${testReport}
sed -i.bak "s/tss-test1/$junitTestCases/g" ${testReport}
sed -i.bak "s/tss-name/$junitName/g" ${testReport} 

while IFS= read -r svc
do
    record="            <testcase classname=\"<clsnm>\" name=\"<clsnm>\" status=\"<status>\" time=\"1\""

    if grep -F "$svc" ${autodocsBaseDirectory}/reports/ReleaseVerificationReport.tmp
    then
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/success}`
        record="$record />"
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $testReport
    else
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/failed}`
        record="$record >"
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $testReport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i <failure message=\"Invalid Version\" type=\"ServiceNotFound\"/>" $testReport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i </testcase>" $testReport
        junitTestFailures=`expr $junitTestFailures + 1`
    fi
done < "${AMITYPE}-Release-Verify.txt"

echo "Failures: $junitTestFailures"

sed -i.bak "s/tss-failures/$junitTestFailures/g" ${testReport}
cat $testReport