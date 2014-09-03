#!/bin/bash

ORACLE_HOME=/usr/lib/oracle/12.1/client64
WORKING_DIR=/home/notroot/crs_script
DATE1_RANGE=`date -d '-150 minutes' +"%Y%m%d %R:00" | awk '{print $1}'`
TIME1_RANGE=`date -d '-150 minutes' +"%Y%m%d %R:00" | awk '{print $2}'`
DATE2_RANGE=`date -d '-120 minutes' +"%Y%m%d %R:00" | awk '{print $1}'`
TIME2_RANGE=`date -d '-120 minutes' +"%Y%m%d %R:00" | awk '{print $2}'`
OUTPUT_DIR=/home/notroot/crs_script/$DATE1_RANGE
FILE_OUTPUT_CRS=RefillDetail_$DATE1_RANGE:$TIME1_RANGE-$DATE2_RANGE:$TIME2_RANGE.DAT
FILE_OUTPUT_LAC=RefillDetail_$DATE1_RANGE:$TIME1_RANGE-$DATE2_RANGE:$TIME2_RANGE.LAC

if [ ! -d "$OUTPUT_DIR" ]
then
    mkdir $OUTPUT_DIR
fi

$ORACLE_HOME/bin/sqlplus -S  DWSADM/dwsadm@//aa.bb.cc.dd:1521/DWS <<EOF > /dev/null
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SET NEWPAGE 0
SET LINESIZE 9999
SET COLSEP ','
SET TAB OFF
SET TRIMSPOOL ON
SPOOL $OUTPUT_DIR/$FILE_OUTPUT_CRS
SELECT to_char (SAE.LOCAL_TIMESTAMP, 'yyyymmdd hh24:mi:ss')||','||SAE.SERVED_MSISDN||','||AAE.ORIG_NODE_TYPE||','||AAE.NOMINAL_TRANSACTION_AMOUNT||','||AAE.SEGMENTATION_ID
FROM AIR_ACCOUNT_EVENTS AAE, SDP_ACCOUNT_EVENTS SAE, air_journal_entries aje , sdp_journal_entries sdp
WHERE AAE.ACCOUNT_EVENT_ID=aje.ACCOUNT_EVENT_ID and SAE.ACCOUNT_EVENT_ID=AAE.ACCOUNT_EVENT_ID and aje.ACCOUNT_EVENT_ID=sdp.ACCOUNT_EVENT_ID
AND AAE.REFILL_TYPE_ID=2 AND AAE.ORIG_NODE_TYPE <> 'VAS' AND sdp.cash_account_id = aje.cash_account_id and nvl(sdp.DED_ACC_UNIT_TYPE,1) = 1
AND nvl(sdp.DED_ACC_CATG,0) <> 1 AND nvl(aje.DED_ACC_CATG,0) <> 1
and SAE.LOCAL_TIMESTAMP >= to_date('$DATE1_RANGE $TIME1_RANGE', 'yyyymmdd hh24:mi:ss')
and SAE.LOCAL_TIMESTAMP < to_date('$DATE2_RANGE $TIME2_RANGE', 'yyyymmdd hh24:mi:ss')
order by SAE.LOCAL_TIMESTAMP;
SPOOL OFF
/

EOF

if [ `cat $OUTPUT_DIR/$FILE_OUTPUT_CRS | wc -l` -ne 0 ]
then
echo `date`"    -> dump table ........ SUCCEED !"
else
echo `date`"    -> dump table ........ FAILED !" 
fi

for i in `awk -F\, '{print $2}' $OUTPUT_DIR/$FILE_OUTPUT_CRS`
do
$WORKING_DIR/GetLocationAPI.sh $i >> $OUTPUT_DIR/lac.tmp
done

paste -d, $OUTPUT_DIR/$FILE_OUTPUT_CRS $OUTPUT_DIR/lac.tmp > $OUTPUT_DIR/$FILE_OUTPUT_LAC

if [ `cat $OUTPUT_DIR/$FILE_OUTPUT_LAC | wc -l` -ne 0 ]
then
echo `date`"    -> checking LAC ........ SUCCEED !"
else
echo `date`"    -> checking LAC ........ FAILED !" 
fi 

rm -rf $OUTPUT_DIR/lac.tmp
