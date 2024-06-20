#!/bin/bash
# Script to add testsuites to the report
# Parameters
#   1 - AMITYPE
#   2 - AMIREGION
#   3 - amitestreport
#   4 - autodocsBaseDirectory

export AMITYPE=$1
export AMIREGION=$2
export amitestreport=$3
export autodocsBaseDirectory=$4
export junitName="${AMITYPE}-${AMIREGION}-Build-Config"
export junitTestFailures=0

echo "Reviewing status of services/tools..."
cat serviceStatus-Build.txt

echo "Creating list of test cases..."
cat ${autodocsBaseDirectory}/verification-test-build.sh | grep '##' | cut -b 3- | sort  > ${AMITYPE}-Build-Config.txt
echo "Test case list generated..."

echo "Identifying the number of test cases found..."
junitTestCases=$(cat ${AMITYPE}-Build-Config.txt | wc -l)

echo "Generating report"
cp ${autodocsBaseDirectory}/templates/junitReport.template.xml ${amitestreport}
sed -i.bak "s/tss-test1/$junitTestCases/g" ${amitestreport}
sed -i.bak "s/tss-name/$junitName/g" ${amitestreport} 

while IFS= read -r svc
do
    record="            <testcase classname=\"<clsnm>\" name=\"<clsnm>\" status=\"<status>\" time=\"1\""

    if grep -F "$svc" ${autodocsBaseDirectory}/reports/reportBuildstatus.tmp
    then
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/success}`
        record="$record />"
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $amitestreport
    else
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/failed}`
        record="$record >"
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $amitestreport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i <failure message=\"Invalid Version\" type=\"ServiceNotFound\"/>" $amitestreport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i </testcase>" $amitestreport
        junitTestFailures=`expr $junitTestFailures + 1`
    fi
done < "${AMITYPE}-Build-Config.txt"

echo "Failures: $junitTestFailures"

sed -i.bak "s/tss-failures/$junitTestFailures/g" ${amitestreport}
cat $amitestreport