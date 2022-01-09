<SPAN style='text-align:left;white-space: nowrap;'>

<?php
#### Monitoring Commvault Backup Logs
#### Version 2.1
#### Writen by: Premysl Botek (pbotek@harbourmsp.com)
##################################################################################

## pragmas, global variable declarations, environment setup

error_reporting(E_ALL | E_STRICT);
ini_set('display_errors', TRUE);
ini_set('max_execution_time', 300); //300 seconds = 5 minutes

$databaseFileName='/clmdata/database/clmonitoringdata_slow.db';



## program entry point
## program initialization




$scriptAction=$_GET['a'];			# 1 - report-detail-directorylevel (detected problems), 2 - report-detail-filelevel (detected problems), 3 - report-detail-directorylevel (ignored errors), 4 - report-client-errors (detected problems)





$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);


## test if database is not locked

ini_set('display_errors', FALSE);

$stmt = $db->prepare("SELECT MAX(DL_ID) FROM TA_CLIENTS");
if ($db->lastErrorCode()==5){
echo "Database is exlusively locked, please wait and refresh this page again.";
exit();
}


ini_set('display_errors', TRUE);







## run selected action


if ($scriptAction==1){				# report-detail-directorylevel (detected problems)


$currentReportId=$_GET['rid'];


echo "<b>PROBLEMATIC DIRECTORIES LIST</b><br>";


$sql1 = <<<DELIMITER1

SELECT A.DL_JOB_ID,
	B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       B.DL_REPORT_ID = :param1 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS ZA, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING ZB, 
                  TA_REDUNDANT_DATA_LOOKUP ZC
            WHERE ZA.DL_EXCEPTION_TEMPLATE_ID = ZB.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  B.DL_CLIENT_ID = ZB.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = ZC.DL_ID 
                  AND
                  ( ZC.DS_DATA LIKE ( ZA.DS_ITEM_PATH || '%' )  )  
       ) 
       
 GROUP BY A.DL_JOB_ID,
          A.DL_ITEM_PATH_ID
 ORDER BY A.DL_JOB_ID,
           A.DL_ITEM_PATH_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";
$lastNavigationString="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\")</b> <br>";
if ( $currentNavigationString != $lastNavigationString ) {
echo $currentNavigationString;
}

$compoundDirectoryId = "$row[0]-$row[2]";
$compoundDirectoryId = "<a href='zscrdetail1.php?a=2&did=".$compoundDirectoryId."'>".$compoundDirectoryId."</a>";

echo "&nbsp;directoryId $compoundDirectoryId ($row[6] problems) : \"$row[3]\"<br>";

$rowCounter++;
$lastNavigationString = $currentNavigationString;
      
    
}


$rowCounter--;
echo "<br>Listed $rowCounter problematic directories.";


}









if ($scriptAction==2){					# 2 - report-detail-filelevel (detected problems)


$currentDirectoryId=$_GET['did'];
$currentDirectoryIdPieces=explode("-", $currentDirectoryId);


$currentJobId=$currentDirectoryIdPieces[0];
$currentPathId=$currentDirectoryIdPieces[1];



echo "<b>PROBLEMATIC FILES LIST</b><br>";


$sql1 = <<<DELIMITER1
		
SELECT A.DL_JOB_ID,
       B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       E.DS_DATA,
       F.DS_DATA
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D, 
       TA_REDUNDANT_DATA_LOOKUP E, 
       TA_REDUNDANT_DATA_LOOKUP F
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       A.DL_JOB_ID = :param1 
       AND
       A.DL_ITEM_PATH_ID = :param2 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       A.DL_ITEM_NAME_ID = E.DL_ID 
       AND
       A.DL_ITEM_REASON_ID = F.DL_ID 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS ZA, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING ZB, 
                  TA_REDUNDANT_DATA_LOOKUP ZC
            WHERE ZA.DL_EXCEPTION_TEMPLATE_ID = ZB.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  B.DL_CLIENT_ID = ZB.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = ZC.DL_ID 
                  AND
                  ( ZC.DS_DATA LIKE ( ZA.DS_ITEM_PATH || '%' )  )  
       )
 ORDER BY A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";



$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentJobId, SQLITE3_INTEGER);
$stmt->bindValue(':param2', $currentPathId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


     
    
if ( $rowCounter == 1 ) {

$compoundDirectoryId = "$row[0]-$row[2]";
$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\") <br>";
$currentNavigationString =$currentNavigationString . "&nbsp;directoryId $compoundDirectoryId : \"$row[3]\"</b><br>";
echo $currentNavigationString;

}

echo "&nbsp;&nbsp;\"$row[6]\" : $row[7]<br>";
    
    
$rowCounter++;
}


$rowCounter--;
echo "<br>Listed $rowCounter problematic files.";


}
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

if ($scriptAction==3){				# 3 - report-detail-directorylevel (ignored problems)


$currentReportId=$_GET['rid'];


echo "<b>IGNORED DIRECTORIES LIST</b><br>";


$sql1 = <<<DELIMITER1

SELECT A.DL_JOB_ID,
	B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       B.DL_REPORT_ID = :param1 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS ZA, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING ZB, 
                  TA_REDUNDANT_DATA_LOOKUP ZC
            WHERE ZA.DL_EXCEPTION_TEMPLATE_ID = ZB.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  B.DL_CLIENT_ID = ZB.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = ZC.DL_ID 
                  AND
                  ( ZC.DS_DATA LIKE ( ZA.DS_ITEM_PATH || '%' )  )  
       ) 
       
 GROUP BY A.DL_JOB_ID,
          A.DL_ITEM_PATH_ID
 ORDER BY A.DL_JOB_ID,
           A.DL_ITEM_PATH_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";
$lastNavigationString="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\")</b><br>";
if ( $currentNavigationString != $lastNavigationString ) {
echo $currentNavigationString;
}

$compoundDirectoryId = "$row[0]-$row[2]";
$compoundDirectoryId = "<a href='zscrdetail1.php?a=5&did=".$compoundDirectoryId."'>".$compoundDirectoryId."</a>";

echo "&nbsp;directoryId $compoundDirectoryId ($row[6] ignored errors) : \"$row[3]\"<br>";

$rowCounter++;
$lastNavigationString = $currentNavigationString;
      
    
}


$rowCounter--;
echo "<br>Listed $rowCounter ignored directories that contain errors.";


}






  
  
  
  
  
  
  
  


if ($scriptAction==4){				# 4 - report-client-errors (detected problems)


$currentReportId=$_GET['rid'];


echo "<b>CLIENT FAILURES IN REPORT $currentReportId</b><br><span style='white-space: nowrap;'>";


$sql1 = <<<DELIMITER1

SELECT A.DS_FAILURE_REASON,
       A.DS_FAILURE_ERROR_CODE,
       C.DL_ID,
       C.DS_NAME,
       A.DL_ID,
       A.DS_JOBID,
       A.DS_SUBCLIENT_CONTENT
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       AND
       B.DL_ID = :param1
 ORDER BY A.DL_CLIENT_ID,A.DS_SUBCLIENT_CONTENT,A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString1="";
$lastNavigationString1="";
$currentNavigationString2="";
$lastNavigationString2="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$currentNavigationString1 ="<br><b>ClientId $row[2] \"$row[3]\"</b><br>";
if ( $currentNavigationString1 != $lastNavigationString1 ) {
echo $currentNavigationString1;
$lastNavigationString2="";
}


$currentNavigationString2 ="&nbsp;<b>Subclient Content \"$row[6]\"</b><br>";
if ( $currentNavigationString2 != $lastNavigationString2 ) {
echo $currentNavigationString2;
}



echo "&nbsp;&nbsp;JobId $row[4] (Commcell JobId \"$row[5]\") : Failure Reason \"$row[0]\"<br>";



$rowCounter++;
$lastNavigationString1 = $currentNavigationString1;
$lastNavigationString2 = $currentNavigationString2;
      
    
}


$rowCounter--;
echo "</span><br>Listed $rowCounter client failures.";


}






  
  
  
  
  
  


if ($scriptAction==5){					# 5 - report-detail-filelevel (ignored errors)


$currentDirectoryId=$_GET['did'];
$currentDirectoryIdPieces=explode("-", $currentDirectoryId);


$currentJobId=$currentDirectoryIdPieces[0];
$currentPathId=$currentDirectoryIdPieces[1];



echo "<b>IGNORED FILE ERROR LIST</b><br>";


$sql1 = <<<DELIMITER1
		
SELECT A.DL_JOB_ID,
       B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       E.DS_DATA,
       F.DS_DATA
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D, 
       TA_REDUNDANT_DATA_LOOKUP E, 
       TA_REDUNDANT_DATA_LOOKUP F
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       A.DL_JOB_ID = :param1 
       AND
       A.DL_ITEM_PATH_ID = :param2 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       A.DL_ITEM_NAME_ID = E.DL_ID 
       AND
       A.DL_ITEM_REASON_ID = F.DL_ID 
       AND
       EXISTS ( 
           SELECT 1
             FROM TA_DIEXCEPTIONS ZA, 
                  TA_DIEXCEPTION_TEMPLATES_MATCHING ZB, 
                  TA_REDUNDANT_DATA_LOOKUP ZC
            WHERE ZA.DL_EXCEPTION_TEMPLATE_ID = ZB.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  B.DL_CLIENT_ID = ZB.DL_CLIENT_ID 
                  AND
                  A.DL_ITEM_PATH_ID = ZC.DL_ID 
                  AND
                  ( ZC.DS_DATA LIKE ( ZA.DS_ITEM_PATH || '%' )  )  
       )
 ORDER BY A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";



$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentJobId, SQLITE3_INTEGER);
$stmt->bindValue(':param2', $currentPathId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


     
    
if ( $rowCounter == 1 ) {

$compoundDirectoryId = "$row[0]-$row[2]";
$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\") <br>";
$currentNavigationString =$currentNavigationString . "&nbsp;directoryId $compoundDirectoryId : \"$row[3]\"</b><br>";
echo $currentNavigationString;

}

echo "&nbsp;&nbsp;\"$row[6]\" : $row[7]<br>";
    
    
$rowCounter++;
}


$rowCounter--;
echo "<br>Listed $rowCounter ignored file errors.";


}
  
  
  
  
  
  

  
  
if ($scriptAction==6){					# 6 - list detail on client errors encountered in given period (apply exceptions)

  
$rdcefpSelectedDate1=$_GET['p0'];
$rdcefpSelectedDate2=$_GET['p1'];
     

$errorCounter = 0;
$returnValue  = "none";
$sth;
$sql1;
$currentNavigationString1="";
$lastNavigationString1="";
$currentNavigationString2="";
$lastNavigationString2="";

	
	
if ( $rdcefpSelectedDate1 == $rdcefpSelectedDate2 ) {
echo "<b>CLIENT FAILURES ON $rdcefpSelectedDate1 :</b><br>";
}
else {
echo "<b>CLIENT FAILURES BETWEEN $rdcefpSelectedDate1 AND $rdcefpSelectedDate2 :</b><br>";
}	
	
	

#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);

		
$sql1 = <<<DELIMITER1
		
SELECT A.DS_FAILURE_REASON,
       C.DS_NAME,
       C.DL_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID,
       A.DS_JOBID,
       B.DL_ID,
       B.DT_IMPORT_FINISHED,
       A.DS_FAILURE_ERROR_CODE
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
       AND
       ( B.DT_IMPORT_FINISHED IS NOT NULL ) 
       AND
       ( strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) BETWEEN strftime( '%Y-%m-%d', :param1 )  AND strftime( '%Y-%m-%d', :param2 )  ) 
 ORDER BY A.DL_CLIENT_ID;

DELIMITER1;


$stmt = $db->prepare($sql1);



		
$stmt->bindValue(':param1', $rdcefpSelectedDate1, SQLITE3_TEXT);
$stmt->bindValue(':param2', $rdcefpSelectedDate2, SQLITE3_TEXT);

		
$results = $stmt->execute();





$rowCounter = 1;


while ($row = $results->fetchArray()) {

if ( $rowCounter == 1 ) {
  $returnValue = "";
}

$currentNavigationString1 ="<br><b>clientId $row[2] \"$row[1]\"</b><br>";

if ( $currentNavigationString1 != $lastNavigationString1 ) {
    $returnValue .= $currentNavigationString1;
    $lastNavigationString2 = "";
}

			$currentNavigationString2 =
			  "<b>&nbsp;Subclient Content \"$row[3]\"</b><br>";
			if ( $currentNavigationString2 != $lastNavigationString2 ) {
				$returnValue .= $currentNavigationString2;
			}

			$returnValue .=
"&nbsp;&nbsp;jobId $row[4] (Commcell JobId \"$row[5]\"; reportId $row[6]; report imported on $row[7]) : Failure Reason \"$row[0]\"<br>";

			$rowCounter++;
			$lastNavigationString1 = $currentNavigationString1;
			$lastNavigationString2 = $currentNavigationString2;


			
}




echo $returnValue;    
    
    
  
  
  
  
}  
  

  
  
  
  
  
  
  
  
if ($scriptAction==7){					# 7 - list detail on x consecutive client errors encountered (apply exceptions)
  

$errorCounter = 0;
$returnValue="";
$sth1;
$sth2;
$sql1;
$sql2;
$currentNavigationString;
$lastNavigationString;



$rdcefcSelectedDate1=$_GET['p0'];
$consecutiveDaysNumber=$_GET['cd'];



#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);

		

$sql1 = <<<DELIMITER1
		
-- STATEMENT EXPLANATION:                
-- Purpose: Retrieves failed client tasks for the specified day that have failed consecutively in n1 previous occurences (regardless on error number). Applies error exceptions/templates.
-- Outer Query O "SELECT A.DL_CLIENT_ID,..." : lists all failed tasks for specified day but keeps only those which comply to "not exists" condition of nested query A and "equals condition" of nested query B and "not exists" of nested query OE
-- 	Nested Query A "NOT EXISTS ( SELECT 1 FROM TA_JOBS E,..." : helps the outer query to retrieve only most recent task record for the selected day (and relevant client and subclient content) that failed
-- 	 Double Nested Query AE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query A
-- 	Nested Query B (named Nested2) "SELECT COUNT( 1 )FROM ( SELECT C.DL_CLIENT_ID,..." : helps the outer query to verify whether for the given outer query task record there are other two nearest relevant nearest task records that failed consecutively. How: in its own nested query, it will select the previous n-1 relevant rows (regardless if they have error or not) and then from the returned recordset, it will count how many of them have error and compares their count to the expected count - this is how it will find out if errors are consecutive
-- 	 Double Nested Query BE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query B
--  Nested Query OE "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on parent query O
SELECT A.DL_CLIENT_ID,
       A.DS_SUBCLIENT_CONTENT,
       A.DL_ID AS JOBID,
       D.DS_NAME AS CLIENTNAME
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS D
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = D.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_JOBS E, 
                  TA_REPORTS F
            WHERE E.DL_ID > A.DL_ID 
                  AND
                  E.DL_REPORT_ID = F.DL_ID 
                  AND
                  E.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  E.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                  AND
                  strftime( '%Y-%m-%d', F.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
                  AND
                  E.DS_FAILURE_ERROR_CODE <> '0' 
                  AND
                  NOT EXISTS ( 
                      SELECT 1
                        FROM TA_CEEXCEPTIONS J, 
                             TA_CEEXCEPTION_TEMPLATES K, 
                             TA_CEEXCEPTION_TEMPLATES_MATCHING L
                       WHERE J.DL_EXCEPTION_TEMPLATE_ID = K.DL_ID 
                             AND
                             K.DL_ID = L.DL_EXCEPTION_TEMPLATE_ID 
                             AND
                             L.DL_CLIENT_ID = E.DL_CLIENT_ID 
                             AND
                             J.DS_ERROR_CODE = E.DS_FAILURE_ERROR_CODE 
                  ) 
                   
       ) 
       
       AND
       strftime( '%Y-%m-%d', B.DT_IMPORT_FINISHED ) = strftime( '%Y-%m-%d', 'param1' ) 
       AND
       ( 
           SELECT COUNT( 1 )
             FROM ( 
                   SELECT C.DL_CLIENT_ID,
                          C.DS_SUBCLIENT_CONTENT,
                          C.DS_FAILURE_ERROR_CODE
                     FROM TA_JOBS C
                    WHERE C.DL_CLIENT_ID = A.DL_CLIENT_ID 
                          AND
                          C.DL_ID < A.DL_ID 
                          AND
                          C.DS_SUBCLIENT_CONTENT = A.DS_SUBCLIENT_CONTENT 
                          AND
                          NOT EXISTS ( 
                              SELECT 1
                                FROM TA_CEEXCEPTIONS M, 
                                     TA_CEEXCEPTION_TEMPLATES N, 
                                     TA_CEEXCEPTION_TEMPLATES_MATCHING O
                               WHERE M.DL_EXCEPTION_TEMPLATE_ID = N.DL_ID 
                                     AND
                                     N.DL_ID = O.DL_EXCEPTION_TEMPLATE_ID 
                                     AND
                                     O.DL_CLIENT_ID = C.DL_CLIENT_ID 
                                     AND
                                     M.DS_ERROR_CODE = C.DS_FAILURE_ERROR_CODE 
                          ) 
                          
                    ORDER BY C.DL_ID DESC
                    LIMIT param2 - 1 
               ) 
               NESTED2
            WHERE NESTED2.DS_FAILURE_ERROR_CODE <> '0' 
       ) 
       = param2 - 1 
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS G, 
                  TA_CEEXCEPTION_TEMPLATES H, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING I
            WHERE G.DL_EXCEPTION_TEMPLATE_ID = H.DL_ID 
                  AND
                  H.DL_ID = I.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  I.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  G.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
 ORDER BY A.DL_CLIENT_ID,
           A.DS_SUBCLIENT_CONTENT;

DELIMITER1;

#$sql1 =~ s/param1/$rdcefcSelectedDate1/g
; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

#$sql1 =~ s/param2/$consecutiveDaysNumber/g
; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves


$sql1 = preg_replace("/param1/",$rdcefcSelectedDate1,$sql1);
; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves

$sql1 = preg_replace("/param2/",$consecutiveDaysNumber,$sql1);
; # parameters in complex parametrized sqlite queries do not work well. we do parameter replacement ourselves





$stmt1 = $db->prepare($sql1);

$results1 = $stmt1->execute();



#		while ( @rowArray1 = $sth1->fetchrow_array() ) {
while ($row1 = $results1->fetchArray()) {

$currentNavigationString =
"<br><b>clientId $row1[0] \"$row1[3]\" , Subclient Content \"$row1[1]\"</b><br>";
$returnValue .= $currentNavigationString;

$sql2 = <<<DELIMITER1
		
-- STATEMENT EXPLANATION:                
-- Purpose: Retrieves detail on consequential n relevant errorneous tasks that happened in the time before the recorded DL_ID, given from the above query. Applies error exceptions/templates.   
--  Nested Query E "AND NOT EXISTS ( SELECT 1 FROM TA_CEEXCEPTIONS G,... " : applies client error exceptions/templates on outer query
			
SELECT A.DL_ID,
       A.DS_JOBID,
       B.DL_ID,
       B.DT_IMPORT_FINISHED,
       A.DS_FAILURE_ERROR_CODE,
       A.DS_FAILURE_REASON
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DS_FAILURE_ERROR_CODE <> '0' 
       AND
       A.DL_ID <= :param1 
       AND
       A.DL_CLIENT_ID = :param2 
       AND
       A.DS_SUBCLIENT_CONTENT = :param3
       AND
       NOT EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       
 ORDER BY A.DL_ID DESC
 LIMIT ( :param4 );

DELIMITER1;


$stmt2 = $db->prepare($sql2);
		
$stmt2->bindValue(':param1', $row1[2], SQLITE3_INTEGER);
$stmt2->bindValue(':param2', $row1[0], SQLITE3_INTEGER);
$stmt2->bindValue(':param3', $row1[1], SQLITE3_TEXT);
$stmt2->bindValue(':param4', $consecutiveDaysNumber, SQLITE3_INTEGER);

		
		
$results2 = $stmt2->execute();




#while ( @rowArray2 = $sth2->fetchrow_array() ) {
while ($row2 = $results2->fetchArray()) {

$returnValue .=
"&nbsp;jobId $row2[0] (Commcell JobId \"$row2[1]\"; reportId $row2[2]; report imported on $row2[3]) : Failure Reason \"$row2[5]\"<br>";

			}

}
			
			
			
if ( $returnValue !="" ) {
		$returnValue =
"<b>CLIENTS WITH $consecutiveDaysNumber CONSECUTIVE FAILURES FROM $rdcefcSelectedDate1 BACKWARDS</b><br>"
		  . $returnValue;

		echo $returnValue;
	}
	else {
		echo "none";

	}

 
  
  
  
  
}
  

  
  
  
  
   
  
  


if ($scriptAction==8){				# 8 - report-client-errors (ignored problems)


$currentReportId=$_GET['rid'];


echo "<b>IGNORED CLIENT FAILURES IN REPORT $currentReportId</b><br><span style='white-space: nowrap;'>";


$sql1 = <<<DELIMITER1

SELECT A.DS_FAILURE_REASON,
       A.DS_FAILURE_ERROR_CODE,
       C.DL_ID,
       C.DS_NAME,
       A.DL_ID,
       A.DS_JOBID,
       A.DS_SUBCLIENT_CONTENT
  FROM TA_JOBS A, 
       TA_REPORTS B, 
       TA_CLIENTS C
 WHERE A.DL_REPORT_ID = B.DL_ID 
       AND
       A.DL_CLIENT_ID = C.DL_ID 
       AND
       DS_FAILURE_ERROR_CODE <> '0' 
       AND
       EXISTS ( 
           SELECT 1
             FROM TA_CEEXCEPTIONS D, 
                  TA_CEEXCEPTION_TEMPLATES E, 
                  TA_CEEXCEPTION_TEMPLATES_MATCHING F
            WHERE D.DL_EXCEPTION_TEMPLATE_ID = E.DL_ID 
                  AND
                  E.DL_ID = F.DL_EXCEPTION_TEMPLATE_ID 
                  AND
                  F.DL_CLIENT_ID = A.DL_CLIENT_ID 
                  AND
                  D.DS_ERROR_CODE = A.DS_FAILURE_ERROR_CODE 
       ) 
       AND
       B.DL_ID = :param1
 ORDER BY A.DL_CLIENT_ID,A.DS_SUBCLIENT_CONTENT,A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString1="";
$lastNavigationString1="";
$currentNavigationString2="";
$lastNavigationString2="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$currentNavigationString1 ="<br><b>ClientId $row[2] \"$row[3]\"</b><br>";
if ( $currentNavigationString1 != $lastNavigationString1 ) {
echo $currentNavigationString1;
$lastNavigationString2="";
}


$currentNavigationString2 ="&nbsp;<b>Subclient Content \"$row[6]\"</b><br>";
if ( $currentNavigationString2 != $lastNavigationString2 ) {
echo $currentNavigationString2;
}



echo "&nbsp;&nbsp;JobId $row[4] (Commcell JobId \"$row[5]\") : Failure Reason \"$row[0]\"<br>";



$rowCounter++;
$lastNavigationString1 = $currentNavigationString1;
$lastNavigationString2 = $currentNavigationString2;
      
    
}


$rowCounter--;
echo "</span><br>Listed $rowCounter ignored client failures.";


}


  
  
  
  
  
  
  
  
  
  


if ($scriptAction==9){				# 9 - list all imported jobs in report


$currentReportId=$_GET['rid'];


echo "<b>REPORT $currentReportId / IMPORTED BACKUP JOBS</b><br>";


$sql1 = <<<DELIMITER1

SELECT A.DL_ID,
       B.DL_ID,
       B.DS_NAME,
       A.DS_SUBCLIENT_CONTENT,
       A.DS_STATUS,
       A.DS_FAILURE_ERROR_CODE,
       A.DS_FAILURE_REASON,
       ( 
           SELECT COUNT( 1 )
             FROM TA_JOB_ITEMS
            WHERE DL_JOB_ID = A.DL_ID 
       ) 
       AS FAILEDITEMCOUNT
  FROM TA_JOBS A, 
       TA_CLIENTS B
 WHERE A.DL_REPORT_ID = :param1 
       AND
       A.DL_CLIENT_ID = B.DL_ID
 ORDER BY A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$jobInfoDisplayString="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$jobInfoDisplayString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[2]\"; subclientContent \"$row[3]\")</b><br>";
$jobInfoDisplayString =$jobInfoDisplayString."&nbsp;Status: $row[4] <br>";
$jobInfoDisplayString =$jobInfoDisplayString."&nbsp;Failure Error Code: $row[5] <br>";
$jobInfoDisplayString =$jobInfoDisplayString."&nbsp;Failure Description: \"$row[6]\" <br>";

$failedItemsDisplay=$row[7];
if ($failedItemsDisplay>0){
$failedItemsDisplay="<a href='zscrdetail1.php?a=10&rid=".$currentReportId."&jid=".$row[0]."'>".$failedItemsDisplay."</a>";
}
$jobInfoDisplayString =$jobInfoDisplayString."&nbsp;Failed Items: $failedItemsDisplay <br>";

echo $jobInfoDisplayString;


$rowCounter++;
      
    
}


$rowCounter--;
echo "<br>Listed $rowCounter backup jobs.";


}





  
  
  





if ($scriptAction==10){				# - list failed directories of items for all imported jobs in report


$currentReportId=$_GET['rid'];
$currentJobId=$_GET['jid'];


echo "<b>REPORT $currentReportId / IMPORTED BACKUP JOBS / JOB</b><br>";


$sql1 = <<<DELIMITER1

SELECT A.DL_JOB_ID,
	B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       COUNT( 1 )
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       B.DL_REPORT_ID = :param1 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       A.DL_JOB_ID=:param2
       
 GROUP BY A.DL_JOB_ID,
          A.DL_ITEM_PATH_ID
 ORDER BY A.DL_JOB_ID,
           A.DL_ITEM_PATH_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";
$lastNavigationString="";


$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentReportId, SQLITE3_INTEGER);
$stmt->bindValue(':param2', $currentJobId, SQLITE3_INTEGER);


$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\")</b> <br>";
if ( $currentNavigationString != $lastNavigationString ) {
echo $currentNavigationString;
}

$compoundDirectoryId = "$row[0]-$row[2]";
$compoundDirectoryId = "<a href='zscrdetail1.php?a=11&did=".$compoundDirectoryId."&rid=".$currentReportId."'>".$compoundDirectoryId."</a>";

echo "&nbsp;directoryId $compoundDirectoryId ($row[6] problems) : \"$row[3]\"<br>";

$rowCounter++;
$lastNavigationString = $currentNavigationString;
      
    
}


$rowCounter--;
echo "<br>Listed $rowCounter problematic directories.";


}







  
  
  



if ($scriptAction==11){					# 11 - report-detail-filelevel (detected problems)


$currentReportId=$_GET['rid'];
$currentDirectoryId=$_GET['did'];
$currentDirectoryIdPieces=explode("-", $currentDirectoryId);


$currentJobId=$currentDirectoryIdPieces[0];
$currentPathId=$currentDirectoryIdPieces[1];



echo "<b>REPORT $currentReportId / IMPORTED BACKUP JOBS / JOB / DIRECTORY / FAILED ITEMS</b><br>";


$sql1 = <<<DELIMITER1
		
SELECT A.DL_JOB_ID,
       B.DL_CLIENT_ID,
       A.DL_ITEM_PATH_ID,
       D.DS_DATA,
       C.DS_NAME,
       B.DS_SUBCLIENT_CONTENT,
       E.DS_DATA,
       F.DS_DATA
  FROM TA_JOB_ITEMS A, 
       TA_JOBS B, 
       TA_CLIENTS C, 
       TA_REDUNDANT_DATA_LOOKUP D, 
       TA_REDUNDANT_DATA_LOOKUP E, 
       TA_REDUNDANT_DATA_LOOKUP F
 WHERE A.DL_JOB_ID = B.DL_ID 
       AND
       A.DL_JOB_ID = :param1 
       AND
       A.DL_ITEM_PATH_ID = :param2 
       AND
       B.DL_CLIENT_ID = C.DL_ID 
       AND
       A.DL_ITEM_PATH_ID = D.DL_ID 
       AND
       A.DL_ITEM_NAME_ID = E.DL_ID 
       AND
       A.DL_ITEM_REASON_ID = F.DL_ID 
       
 ORDER BY A.DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);



$rowCounter = 1;
$currentNavigationString="";



$stmt = $db->prepare($sql1);
$stmt->bindValue(':param1', $currentJobId, SQLITE3_INTEGER);
$stmt->bindValue(':param2', $currentPathId, SQLITE3_INTEGER);

$results = $stmt->execute();

while ($row = $results->fetchArray()) {


     
    
if ( $rowCounter == 1 ) {

$compoundDirectoryId = "$row[0]-$row[2]";
$currentNavigationString ="<br><b>jobId $row[0] (clientId $row[1] \"$row[4]\"; subclientContent \"$row[5]\") <br>";
$currentNavigationString =$currentNavigationString . "&nbsp;directoryId $compoundDirectoryId : \"$row[3]\"</b><br>";
echo $currentNavigationString;

}

echo "&nbsp;&nbsp;\"$row[6]\" : $row[7]<br>";
    
    
$rowCounter++;
}


$rowCounter--;
echo "<br>Listed $rowCounter problematic files.";


}
  
  
  
  
  
  
  
  
  
  
    
  
  
  
  

  
  
  
  
  

if ($scriptAction==12){					# 12 - dump die exceptions map




echo "<b>DIRECTORY ITEM ERROR EXCEPTION MAP</b><br>";
echo "(documentation on how to manage this is <a target='_blank' href='https://wiki.lab.com.au/display/ENG/Monitoring+Commvault+Backup+V1.0#MonitoringCommvaultBackupV1.0-3.2.1.2DIEXCEPTIONLISTMANAGEMENT'>here</a>)<br>";
	



$sql1 = <<<DELIMITER1

SELECT DL_ID,
       DS_NAME
  FROM TA_DIEXCEPTION_TEMPLATES
ORDER BY DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);






$stmt1 = $db->prepare($sql1);

$results1 = $stmt1->execute();

while ($row1 = $results1->fetchArray()) {


     
    

echo "<b><br>Template dietemplateId $row1[0] \"$row1[1]\"</b><br>";






$sql2 = <<<DELIMITER1

SELECT DL_ID,
       DS_ITEM_PATH
  FROM TA_DIEXCEPTIONS
 WHERE DL_EXCEPTION_TEMPLATE_ID = :param1
 ORDER BY DL_ID;


DELIMITER1;



$stmt2 = $db->prepare($sql2);
$stmt2->bindValue(':param1', $row1[0], SQLITE3_INTEGER);

$results2 = $stmt2->execute();


echo "&nbsp;<b>Exceptions List</b><br>";



while ($row2 = $results2->fetchArray()) {

echo "&nbsp;&nbsp;diexceptionId $row2[0] : path \"$row2[1]\"<br>";



}

    
    


$sql3 = <<<DELIMITER1

SELECT A.DL_ID,
       A.DS_NAME
  FROM TA_CLIENTS A, 
       TA_DIEXCEPTION_TEMPLATES_MATCHING B
 WHERE B.DL_CLIENT_ID = A.DL_ID 
       AND
       B.DL_EXCEPTION_TEMPLATE_ID = :param1;


DELIMITER1;



$stmt3 = $db->prepare($sql3);
$stmt3->bindValue(':param1', $row1[0], SQLITE3_INTEGER);

$results3 = $stmt3->execute();


echo "&nbsp;<b>Assigned Clients</b><br>";



while ($row3 = $results3->fetchArray()) {

echo "&nbsp;&nbsp;clientId $row3[0] \"$row3[1]\"<br>";



}    
    

}





}
  
  
  
  
  
  
  
  
  

  
  
  
  

if ($scriptAction==13){					# 13 - dump ce exceptions map




echo "<b>CLIENT ERROR EXCEPTION MAP</b><br>";
echo "(documentation on how to manage this is <a target='_blank' href='https://wiki.lab.com.au/display/ENG/Monitoring+Commvault+Backup+V1.0#MonitoringCommvaultBackupV1.0-3.2.2.2CEEXCEPTIONLISTMANAGEMENT'>here</a>)<br>";




$sql1 = <<<DELIMITER1

SELECT DL_ID,
       DS_NAME
  FROM TA_CEEXCEPTION_TEMPLATES
ORDER BY DL_ID;

DELIMITER1;





#$db = new SQLite3($databaseFileName,SQLITE3_OPEN_READONLY);






$stmt1 = $db->prepare($sql1);

$results1 = $stmt1->execute();

while ($row1 = $results1->fetchArray()) {


     
    

echo "<b><br>Template ceetemplateId $row1[0] \"$row1[1]\"</b><br>";






$sql2 = <<<DELIMITER1

SELECT DL_ID,
       DS_ERROR_CODE
  FROM TA_CEEXCEPTIONS
 WHERE DL_EXCEPTION_TEMPLATE_ID = :param1
 ORDER BY DL_ID;


DELIMITER1;



$stmt2 = $db->prepare($sql2);
$stmt2->bindValue(':param1', $row1[0], SQLITE3_INTEGER);

$results2 = $stmt2->execute();


echo "&nbsp;<b>Exceptions List</b><br>";



while ($row2 = $results2->fetchArray()) {

echo "&nbsp;&nbsp;ceexceptionId $row2[0] : error code \"$row2[1]\"<br>";



}

    
    


$sql3 = <<<DELIMITER1

SELECT A.DL_ID,
       A.DS_NAME
  FROM TA_CLIENTS A, 
       TA_CEEXCEPTION_TEMPLATES_MATCHING B
 WHERE B.DL_CLIENT_ID = A.DL_ID 
       AND
       B.DL_EXCEPTION_TEMPLATE_ID = :param1;


DELIMITER1;



$stmt3 = $db->prepare($sql3);
$stmt3->bindValue(':param1', $row1[0], SQLITE3_INTEGER);

$results3 = $stmt3->execute();


echo "&nbsp;<b>Assigned Clients</b><br>";



while ($row3 = $results3->fetchArray()) {

echo "&nbsp;&nbsp;clientId $row3[0] \"$row3[1]\"<br>";



}    
    

}





}
  
  
  
  
  
  
  
  
  
  
  
  
?>


</SPAN>














