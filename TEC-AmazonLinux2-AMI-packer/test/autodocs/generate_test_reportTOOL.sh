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
export junitName="${AMITYPE}-${AMIREGION}-Tool-Config"
export junitTestFailures=0

echo "Reviewing status of services... "
cat ${autodocsBaseDirectory}/reports/reportTOOLstatus.tmp
echo ""

echo "Reviewing versions of services... "
cat ${autodocsBaseDirectory}/reports/reportTOOLversion.tmp
echo ""

echo "Creating services list..."
cat ${autodocsBaseDirectory}/verification-test-TOOL.sh | grep '##' | cut -b 3- | sort  > ${AMITYPE}-Tool-Config.txt
echo "Services list generated..."
echo ""

echo "Identifying the number of test cases found..."
junitTestCases=$(cat ${AMITYPE}-Tool-Config.txt | wc -l)
echo ""

echo "Generating Report"
cp ${autodocsBaseDirectory}/templates/junitReport.template.xml ${amitestreport}
sed -i.bak "s/tss-test1/$junitTestCases/g" ${amitestreport}
sed -i.bak "s/tss-name/$junitName/g" ${amitestreport} 
echo ""

while IFS= read -r svc
do
    record="<testcase classname=\"<clsnm>\" name=\"<clsnm>\" status=\"<status>\" time=\"1\" "

    if grep -F "$svc" ${autodocsBaseDirectory}/reports/reportTOOLstatus.tmp && grep -F "$svc" ${autodocsBaseDirectory}/reports/reportTOOLversion.tmp
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
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i <failure message=\"INACTIVE/UNAVAILABLE\" type=\"ServiceNotFound\"/>" $amitestreport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i </testcase>" $amitestreport
        junitTestFailures=`expr $junitTestFailures + 1`
    fi
done < "${AMITYPE}-Tool-Config.txt"

echo ""
echo "Failures: $junitTestFailures"
echo ""

sed -i.bak "s/tss-failures/$junitTestFailures/g" ${amitestreport}
cat $amitestreport