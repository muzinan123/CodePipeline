#!/bin/bash
# Script to add testsuites to the report
# Parameters
#   1 - AMITYPE
#   2 - AMIREGION
#   3 - amitestreport
#   4 - orcBaseDirectory

export AMITYPE=$1
export AMIREGION=$2
export amitestreport=$3
export orcBaseDirectory=$4
export junittests=$(cat $orcBaseDirectory/test-cases.json | jq -r '.Parameters.commands[]' | wc -l)
export junitname="${AMITYPE}-${AMIREGION}"
export junitfailures=0

echo "Reviewing status of services .. "
cat ${orcBaseDirectory}/reports/report.tmp

echo "Creating services list ..."

# cat ${orcBaseDirectory}/test-cases.json | jq -r '.Parameters.commands[]' | grep "systemctl" | cut -d' ' -f5 | sed -r 's/\*//g'  | sort > ${AMITYPE}services.txt
cat ${orcBaseDirectory}/test-cases.json | jq -r '.Parameters.commands[]' | grep '#' | cut -d'#' -f2 | sort >> ${AMITYPE}services.txt

echo "Services list generated .. "
cat ${AMITYPE}services.txt

echo "Generating Report"
cp ${orcBaseDirectory}/templatereportjunit.xml ${amitestreport}
sed -i.bak "s/tss-tests/$junittests/g" ${amitestreport}
sed -i.bak "s/tss-name/$junitname/g" ${amitestreport} 

while IFS= read -r svc
do
    record="<testcase classname=\"<clsnm>\" name=\"<clsnm>\" status=\"<status>\" time=\"1\" "
    echo "Verifying for $svc."
    if grep -Fq "$svc" ${orcBaseDirectory}/reports/report.tmp
    then
        echo "$svc Service is ACTIVE"
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/success}`
        record="$record />"
        echo -e $record
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $amitestreport
    else
        echo "$svc Service is INACTIVE/UNAVAILABLE"
        record=`echo ${record//<clsnm>/$svc}`
        record=`echo ${record//<status>/failed}`
        record="$record >"
        echo $record
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i $record" $amitestreport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i <failure message=\"INACTIVE/UNAVAILABLE\" type=\"ServiceNotFound\"/>" $amitestreport
        sed -i.bak "/^<!-- TESTCASESTOP -->$/i </testcase>" $amitestreport
        junitfailures=`expr $junitfailures + 1`
    fi
done < "${AMITYPE}services.txt"

echo "Failures: $junitfailures"

sed -i.bak "s/tss-failures/$junitfailures/g" ${amitestreport}
cat $amitestreport
