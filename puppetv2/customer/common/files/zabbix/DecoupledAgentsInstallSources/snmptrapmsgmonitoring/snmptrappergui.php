<?php
#### Monitoring SNMP Trap Messages (User Web GUI)
#### Version 1.6
#### Written by: Premysl Botek (premysl.botek@lab.com)
##################################################################################
# engaged URL param names:
#
# action = 1 :
# a1zfrc: DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE EQUALS
# a1ihr: DL_RECOGNIZED_ZABBIX_HOST EQUALS
# a1oidr: DL_RECOGNIZED_BY_SNMPTT EQUALS
# a1trg: > DT_TIMESTAMP
# a1trs: < DT_TIMESTAMP
# a1ts : frm5text1SearchConditionTrapSource LIKE
# a1toid: frm5text2SearchConditionTrapOID LIKE
#
## pragmas

ini_set('max_execution_time', 60); 			# 60 seconds
error_reporting(E_ALL | E_STRICT);
define('DISPLAY_ERRORS', FALSE);			# must be false or error messages with be served first to user instead of passed to global handlers
#define('E_FATAL',  E_ERROR | E_USER_ERROR | E_PARSE | E_CORE_ERROR | E_COMPILE_ERROR | E_RECOVERABLE_ERROR);


#register_shutdown_function('GlobalShutdownHandler');
set_error_handler('GlobalErrorHandler');





## html headers, shared javascript service functionality
?>


<html>
<head>



<script type="text/css"> 
html, body, object, embed {height:100%;} 
</script> 



<script type='text/javascript'>


function bodyOnLoad(){


}



function frm5btn2ClearOnClick() {

document.getElementById('frm5text1SearchConditionTrapSource').value="";
document.getElementById('frm5text2SearchConditionTrapOID').value="";
document.getElementById('frm5text3SearchConditionTimeReceivedGreater').value="";
document.getElementById('frm5text4SearchConditionTimeReceivedSmaller').value="";
document.getElementById('frm5text5SearchConditionForwardingResultCode').value="";
document.getElementById('frm5text6SearchConditionIsZabbixHostRecognized').value="";
document.getElementById('frm5text7SearchConditionIsOIDResolved').value="";


//document.getElementById('frm5').submit();

}



function frm1ConfirmAndSubmit1() {			//add new host

if (confirm("Really want to add new host "+document.getElementById('frm1text1NewHostName').value+" and insert forwarding rules from selected templates to it?")) {
  
  		
      var x=document.getElementById("frm6list1Templates");
      var y="";
      for (var i = 0; i < x.options.length; i++) {
	  if(x.options[i].selected ==true){
	      y=y+x.options[i].value+',';
	  }
      } 
 
  
  document.getElementById('frm6hidden1selectedtemplates').value=y;  
  document.getElementById('frm1hidden1formaction').value=2;
  document.getElementById('frm1').submit();
}

}



function frm1ConfirmAndSubmit2() {			//remove existing host


if (document.getElementById('frm1hidden2selectedhost').value==''){

alert('First select a host from the list');

}

else {


	if (document.getElementById('frm1hidden2selectedhost').value=='UNLISTED_HOSTS'){

		  alert('Host '+document.getElementById('frm1hidden2selectedhost').value+' can not be deleted');

	} else {


		  if (confirm("Really want to remove "+document.getElementById('frm1hidden2selectedhost').value+"?")) {
			  document.getElementById('frm1hidden1formaction').value=3;
			  document.getElementById('frm1').submit();
		    }

		}	
	
    }
    
}





function frm1ConfirmAndSubmit3() {			//remove templated forwarding rules from selected host


if (document.getElementById('frm1hidden2selectedhost').value==''){

alert('First select a host from the list');

}

else {


		  if (confirm("Really want to remove forwarding rules from "+document.getElementById('frm1hidden2selectedhost').value+" that originated from templates?")) {
			  document.getElementById('frm1hidden1formaction').value=4;
			  document.getElementById('frm1').submit();


		  }	
	
    }
    
}








function frm1ConfirmAndSubmit4() {			//add forwarding rules from selected templates to selected host


if ((document.getElementById('frm1hidden2selectedhost').value=='')||(document.getElementById('frm1hidden3selectedhostid').value=='')){

alert('First select a host from the list');

}

else {


if (confirm("Really want to add forwarding rules from selected templates to "+document.getElementById('frm1hidden2selectedhost').value+"?")) {
			
			
			
      var x=document.getElementById("frm6list1Templates");
      var y="";
      for (var i = 0; i < x.options.length; i++) {
	  if(x.options[i].selected ==true){
	      y=y+x.options[i].value+',';
	  }
      } 
 
  
  document.getElementById('frm6hidden1selectedtemplates').value=y;			
  document.getElementById('frm1hidden1formaction').value=5;
  document.getElementById('frm1').submit();


		  }	
	
    }
    
}









function frm7ConfirmAndSubmit1(element) {			//add ip to maintenance list

if (confirm("Really want to add IP "+document.getElementById('frm7text1Host').value+" to Maintenance List?")) {
  document.getElementById('frm7hidden1formaction').value=1;
  
  document.getElementById('frm7').submit();
}

}








function frm4ConfirmAndSubmit1(element) {			//add host to forwarding rules host list

if (confirm("Really want to add "+element.getAttribute("hostname")+" to Hosts list and insert forwarding rules from selected templates to it?")) {
  document.getElementById('frm4hidden1formaction').value=1;
  document.getElementById('frm4hidden2newhostname').value=element.getAttribute("hostname");
  
  
  var x=document.getElementById("frm6list1Templates");
  var y="";
  for (var i = 0; i < x.options.length; i++) {
     if(x.options[i].selected ==true){
      y=y+x.options[i].value+',';
      }
  } 
 
  
  document.getElementById('frm6hidden1selectedtemplates').value=y;
  
  document.getElementById('frm4').submit();
}

}




function frm1list1OnItemSelected() {		

var selectedItem=document.getElementById('frm1list1Hosts').options[document.getElementById('frm1list1Hosts').selectedIndex];

document.getElementById('frm1hidden2selectedhost').value=selectedItem.value;
document.getElementById('frm3text2CurrentHost').value=selectedItem.value;
document.getElementById('frm3text4CurrentHost').value=selectedItem.value;
document.getElementById('frm1hidden3selectedhostid').value=selectedItem.getAttribute("dbid");
document.getElementById('frm1hidden1formaction').value=0;

document.getElementById('frm1').submit();


}









function frm2ConfirmAndSubmit1() {			//add new queue

if (confirm("Really want to add "+document.getElementById('frm2text1NewQueueName').value+"?")) {
  document.getElementById('frm2hidden1formaction').value=2;
  document.getElementById('frm1').submit();
}

}



function frm2ConfirmAndSubmit2() {			//remove existing queue


if (document.getElementById('frm2hidden2selectedqueue').value==''){

alert('First select a queue from the list');

}

else {


	if (document.getElementById('frm2hidden2selectedqueue').value=='SNMPTrap-Queue1'){

		  alert('Queue '+document.getElementById('frm2hidden2selectedqueue').value+' can not be deleted');

	} else {


		  if (confirm("Really want to remove "+document.getElementById('frm2hidden2selectedqueue').value+"?")) {
			  document.getElementById('frm2hidden1formaction').value=3;
			  document.getElementById('frm1').submit();
		    }

		}	
	
    }
    
}


function frm2list1OnItemSelected() {

var selectedItem=document.getElementById('frm2list1Queues').options[document.getElementById('frm2list1Queues').selectedIndex];

document.getElementById('frm2hidden2selectedqueue').value=selectedItem.value;
document.getElementById('frm3text3CurrentQueue').value=selectedItem.value;
document.getElementById('frm3text5CurrentQueue').value=selectedItem.value;
document.getElementById('frm2hidden3selectedqueueid').value=selectedItem.getAttribute("dbid");
document.getElementById('frm2hidden1formaction').value=0;



}









function frm3ConfirmAndSubmit1() {			//add new message


//alert (document.getElementById('frm1hidden3selectedhostid').value);

if (confirm("Really want to add "+document.getElementById('frm3text1NewMessage').value+"?")) {
  document.getElementById('frm3hidden1formaction').value=4;
  document.getElementById('frm1').submit();
}

}



function frm3ConfirmAndSubmit2() {			//remove existing message


if (document.getElementById('frm3hidden2selectedmessage').value==''){

alert('First select a message OID from the list');

}

else {


	if (document.getElementById('frm3hidden3selectedmessageid').value=='1'){

		  alert('Message OID '+document.getElementById('frm3hidden2selectedmessage').value+' can not be deleted');

	} else {


		  if (confirm("Really want to remove "+document.getElementById('frm3hidden2selectedmessage').value+"?")) {
			  document.getElementById('frm3hidden1formaction').value=5;
			  document.getElementById('frm1').submit();
		    }

		}	
	
    }
    
}





function frm3ConfirmAndSubmit3() {			//change default queue

if (confirm("Really want to change Default Queue for host "+document.getElementById('frm3text4CurrentHost').value+" to "+document.getElementById('frm3text5CurrentQueue').value+" ?")) {
  document.getElementById('frm3hidden1formaction').value=6;
  document.getElementById('frm1').submit();
}

}





function frm3list1OnItemSelected() {		

var selectedItem=document.getElementById('frm3list1Messages').options[document.getElementById('frm3list1Messages').selectedIndex];

document.getElementById('frm3hidden2selectedmessage').value=selectedItem.value;
document.getElementById('frm3hidden3selectedmessageid').value=selectedItem.getAttribute("dbid");
document.getElementById('frm3hidden1formaction').value=0;


}





</script>



</head>

<body onload='bodyOnLoad();'>


<SPAN style='text-align:left;white-space: nowrap;height: 100%;'>

<?php

## global variable declarations, environment setup


## DEPENDENT SETTINGS (values need to be reverified/set correctly during each installation - for this script to work and be integrated with the rest of functionality)

$scriptsBaseDir        	  	= "/srv/zabbix/scripts/snmptrapmsgmonitoring";
$coreDatabaseFileName		= "$scriptsBaseDir/snmptrapmsgmonitoringdata.db";
$coreScriptsLogFileName		= "$scriptsBaseDir/log.txt";


$loggingLevel 			= 2;		# 0 - no logging, 1 - log errors only, 2 - log everything (errors, warnings, debug info)
$logOutput 			= 2;		# 1 - output to console, 2 - output to log file, 3 - output to both console and log file


$proxyTimeZone			= "Australia/ACT";


$sqliteBusyTimeout		= 10000;	# locked (concurent transaction) SQlite database wait timeout (milliseconds)


## End - REQUIRED SETTINGS






$systemTmpDir        	  	= "/tmp";
#$zabbixProxyDatabaseFileName	= "$systemTmpDir/zabbix_proxy.db";

$systemLogDir      		= "/var/log";
$SNMPTTReceivedLogFileName	= "$systemLogDir/snmptrapd-allreceivedtraps.log";


$SNMPConfDir      		= "/etc/snmp";
$SNMPTTIniFileName		= "$SNMPConfDir/snmptt.ini";



$thisModuleID 			= "SNMPTRAPPER-PHP-GUI";       # just for log file record identification purposes



$thisProxyZabbixHostName;

$thisProxyZabbixVersionMajor;



$hostAddFwRulesTemplated_SQLArray = array();
$hostAddFwRulesTemplated_TemplateNameArray = array();


#$trapReportDebugInfo = 0;


## program entry point
## program initialization




# self reflection

$thisFilename		= $_SERVER["PHP_SELF"];
$parts 			= Explode('/', $thisFilename);
$thisFilename		= $parts[count($parts) - 1];



$parts 			= Explode('/', __FILE__);
$thisPath="";
for ($i = 0; $i < (count($parts) - 1); $i++) {
$thisPath=$thisPath.$parts[$i]."/";
}
$thisPath=chop($thisPath,'/');




# self reflection - end


$hostAddFwRulesTemplated_TemplatesDirectory=$thisPath."/TrapMsgForwardRule-HostTemplates";


#echo "path: ".$thisPath;




date_default_timezone_set($proxyTimeZone);






## Read system settings stored in the system DB


$thisProxyZabbixVersionMajor=readSettingFromDatabase1('ZABBIX_VERSION_MAJOR');

if ( !isset($thisProxyZabbixVersionMajor) ) {
	logEvent( 2,
		"ZABBIX_VERSION_MAJOR does not exist in TA_SETTINGS. Terminating."
	);
	die;
}


#


#$thisProxyZabbixHostName=readSettingFromDatabase1('THIS_PROXY_ZABBIX_HOSTNAME');
#$thisProxyZabbixHostName="pb-test1-port";
$pieces = explode(".", php_uname('n'));
$thisProxyZabbixHostName=$pieces[0];


logEvent(1,"test1:".$thisProxyZabbixHostName);


if ( !isset($thisProxyZabbixHostName) ) {
	logEvent( 2,
		"THIS_PROXY_ZABBIX_HOSTNAME does not exist in TA_SETTINGS. Terminating."
	);
	die;
}

if ( $thisProxyZabbixHostName=="" ) {
	logEvent( 2,
		"THIS_PROXY_ZABBIX_HOSTNAME in TA_SETTINGS is empty. Terminating." );
	die;
}


##


if (isset($_GET['a'])){
$scriptAction=$_GET['a'];			
} else {

$scriptAction=0;

}


#if (isset($_GET['trapdebuginfo'])){
#$trapReportDebugInfo=1;
#}

## main execution block




if (!file_exists($coreDatabaseFileName)){
echo "Database file $coreDatabaseFileName does not exist";
exit();
}



## run selected action


switch ($scriptAction) {
    case 1:
        fnReportSNMPTTHelperTrapsProcessed();
        break;
    case 2:
        fnDumpCoreScriptsLogFile();
        break;
    case 3:
        fnDumpSNMPTTReceivedLogFile();
        break;
        
    case 4:
        fnDumpSNMPTTIniFileTrapFilesSection();
        break;
    
    case 5:
        fnShowDiagAndMaintenanceDashboard();
        break;
    
    case 6:
        fnShowLocallyKnownZabbixHosts();
        break;
    
    case 7:
        fnEditTrapMessageForwardingRules();
        break;
        
    case 8:
        fnSNMPTTHelperTrapsProcessedNavigationListByDay();
        break;
        
    
    case 9:
        fnShowProcessedMessageDetail();
        break;

        
    case 10:
        fnSNMPTTHelperTrapsProcessedNavigationListOfRecordedMonths();
        break;
        
    case 11:
        fnIgnoreList();
        break;
            
    
    
    default:
       #echo "Incorrect or missing parameters";
       fnShowDiagAndMaintenanceDashboard();
       
       
       
}



## end - main execution block

##  program exit point	###########################################################################






#################################################################################
#Service functions:




## check if host is registered in core database
function IsHostListed($hostName) {
global $coreDatabaseFileName;
global $sqliteBusyTimeout;

$result = 0;


$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);

$sql1 ="SELECT 1 FROM TA_FORWARD_RULES_HOSTS WHERE DS_HOST_NAME=:hostname";

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$hostName);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

$resultsetRow = $results->fetchArray();

if (isset($resultsetRow[0])){
    $result=1;
}

return $result;

}







function readSettingFromDatabase1($key1) {
global $coreDatabaseFileName;
global $sqliteBusyTimeout;


$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);

$sql1 ="SELECT DS_VALUE FROM TA_SETTINGS WHERE DS_KEY=:key1";

$stmt = $db->prepare($sql1);
$stmt->bindParam(':key1',$key1);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

$resultsetRow = $results->fetchArray();

if (!isset($resultsetRow[0])){
    #logEvent( 2, "Error 1 occured in readSettingFromDatabase1(): $@" );
}


return $resultsetRow[0];

}








function InsertNewHostToForwardRulesHostList($newhostname){
global $coreDatabaseFileName;
global $sqliteBusyTimeout;



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);
$db->busyTimeout($sqliteBusyTimeout);


$sql1 = <<<DELIMITER1

INSERT INTO TA_FORWARD_RULES_HOSTS
(DS_HOST_NAME,DL_DEFAULT_QUEUE_ID) VALUES (:hostname,1)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$newhostname);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();




# get the inserted host id


$sql1 = <<<DELIMITER1

SELECT MAX(DL_ID) FROM TA_FORWARD_RULES_HOSTS
WHERE DS_HOST_NAME=(:hostname)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$newhostname);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();


$resultsetRow = $results->fetchArray();



# insert default forwarding rule for new host



$sql1 = <<<DELIMITER1

INSERT INTO TA_FORWARD_RULES_MESSAGES
(DS_MSG_OID,DL_HOST_ID,DL_QUEUE_ID,DS_RULE_ORIGIN) VALUES (:messageoid,:hostid,:queueid,'system')

DELIMITER1;


$stmt = $db->prepare($sql1);

$strTmp1="UNLISTED_MESSAGES";
$stmt->bindParam(':messageoid',$strTmp1);			# all messages not explicitly specified

$stmt->bindParam(':hostid',$resultsetRow[0]);			# new host id

$intTmp1=1;
$stmt->bindParam(':queueid',$intTmp1);				# default queue

$results = $stmt->execute();



AddTemplatedFwRulesToHost($resultsetRow[0]);




}




function AddTemplatedFwRulesToHost($hostId){
global $coreDatabaseFileName;
global $hostAddFwRulesTemplated_SQLArray;
global $hostAddFwRulesTemplated_TemplateNameArray;
global $hostAddFwRulesTemplated_TemplatesDirectory;
global $sqliteBusyTimeout;



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);
$db->busyTimeout($sqliteBusyTimeout);



# load templated forwarding rules from template files


$templateFilesToImport = explode(",", $_REQUEST['frm6hidden1selectedtemplates']);

foreach ($templateFilesToImport as &$fileName1) {
    
	    
	    if ($fileName1!=''){
	    
		HostAddFwRulesTemplated_LoadFile($fileName1);
	    
	    }

}



# insert templated forwarding rules to database


for ($i = 0; $i < (count($hostAddFwRulesTemplated_SQLArray)); $i++) {


$stmt = $db->prepare($hostAddFwRulesTemplated_SQLArray[$i]);
    
    
if (!$stmt){    

    logEvent( 2,
		"Error 1 in AddTemplatedFwRulesToHost(). Unable to prepare statement $hostAddFwRulesTemplated_SQLArray[$i]"
	);

    throw new Exception('Error 1 in AddTemplatedFwRulesToHost(). Unable to prepare statement, more in log.txt');
	
} else {
    
    $ruleOrigin=$hostAddFwRulesTemplated_TemplateNameArray[$i];
    
    $stmt->bindParam(':hostid',$hostId);			# host id
    $stmt->bindParam(':ruleorigin',$ruleOrigin);				# template file name

    $results = $stmt->execute();    
       
}

}




}





function fnEditTrapMessageForwardingRules(){
global $thisFilename;
global $coreDatabaseFileName;
#global $genericPageHeader1;
global $thisProxyZabbixHostName;
global $sqliteBusyTimeout;



#try {




echo getGenericPageHeader1("<b>Messsage Forwarding Rules </b>(selecting the correct queue(trapper item key) on Zabbix hosts) :");



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);
$db->busyTimeout($sqliteBusyTimeout);


## html form post actions handlers



if (isset($_REQUEST['frm1hidden1formaction'])){


$postFrm1Action=$_REQUEST['frm1hidden1formaction'];




if ($postFrm1Action==2){			# add new host to TA_FORWARD_RULES_HOSTS

  InsertNewHostToForwardRulesHostList($_REQUEST['frm1text1NewHostName']);

}




if ($postFrm1Action==3){			# remove existing host+its forward rules



# delete host's forward rules

$sql1 = <<<DELIMITER1

DELETE FROM TA_FORWARD_RULES_MESSAGES
WHERE DL_HOST_ID=
(SELECT DL_ID FROM TA_FORWARD_RULES_HOSTS WHERE DS_HOST_NAME=(:hostname) LIMIT 1)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$_REQUEST['frm1hidden2selectedhost']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();




# delete host

$sql1 = <<<DELIMITER1

DELETE FROM TA_FORWARD_RULES_HOSTS
WHERE DS_HOST_NAME=(:hostname)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$_REQUEST['frm1hidden2selectedhost']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();



}





if ($postFrm1Action==4){			# remove forward rules from selected host that originated in templates



# delete host's forward rules

$sql1 = <<<DELIMITER1

DELETE FROM TA_FORWARD_RULES_MESSAGES
WHERE DS_RULE_ORIGIN<>'system' AND DS_RULE_ORIGIN<>'manual'
AND DL_HOST_ID=(SELECT DL_ID FROM TA_FORWARD_RULES_HOSTS WHERE DS_HOST_NAME=(:hostname) LIMIT 1)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostname',$_REQUEST['frm1hidden2selectedhost']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();




}








if ($postFrm1Action==5){			# add forward rules originated in templates to selected host 


#echo "AddTemplatedFwRulesToHostid: ".$_REQUEST['frm1hidden3selectedhostid']."<br>";

AddTemplatedFwRulesToHost($_REQUEST['frm1hidden3selectedhostid']);





}






}







if (isset($_REQUEST['frm2hidden1formaction'])){


$postFrm2Action=$_REQUEST['frm2hidden1formaction'];


if ($postFrm2Action==2){			# # add new queue to TA_FORWARD_RULES_QUEUES

$sql1 = <<<DELIMITER1

INSERT INTO TA_FORWARD_RULES_QUEUES
(DS_QUEUE_NAME) VALUES (:queuename)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':queuename',$_REQUEST['frm2text1NewQueueName']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}




if ($postFrm2Action==3){			# remove existing host from TA_FORWARD_RULES_QUEUES

$sql1 = <<<DELIMITER1

DELETE FROM TA_FORWARD_RULES_QUEUES
WHERE DS_QUEUE_NAME=(:queuename)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':queuename',$_REQUEST['frm2hidden2selectedqueue']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}

}













if (isset($_REQUEST['frm3hidden1formaction'])){


#echo "*************frm3hidden1formaction:".$_REQUEST['frm3hidden1formaction'];

$postFrm3Action=$_REQUEST['frm3hidden1formaction'];


if ($postFrm3Action==4){			# add new message rule to TA_FORWARD_RULES_MESSAGES

$sql1 = <<<DELIMITER1

INSERT INTO TA_FORWARD_RULES_MESSAGES
(DS_MSG_OID,DL_HOST_ID,DL_QUEUE_ID,DS_RULE_ORIGIN) VALUES (:messageoid,:hostid,:queueid,'manual')

DELIMITER1;


if ($_REQUEST['frm3text1NewMessage'][0]!='.'){
    $_REQUEST['frm3text1NewMessage']='.'.$_REQUEST['frm3text1NewMessage'];			# add . to the begin of OID if it is missing
}


$stmt = $db->prepare($sql1);
$stmt->bindParam(':messageoid',$_REQUEST['frm3text1NewMessage']);			# parametrized queries = good protection against SQL injection
$stmt->bindParam(':hostid',$_REQUEST['frm1hidden3selectedhostid']);			# parametrized queries = good protection against SQL injection
$stmt->bindParam(':queueid',$_REQUEST['frm2hidden3selectedqueueid']);			# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}




if ($postFrm3Action==5){			# remove existing message from TA_FORWARD_RULES_MESSAGES

$sql1 = <<<DELIMITER1

DELETE FROM TA_FORWARD_RULES_MESSAGES
WHERE DL_ID=(:messageid)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':messageid',$_REQUEST['frm3hidden3selectedmessageid']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}



if ($postFrm3Action==6){			# update TA_FORWARD_RULES_HOSTS - set new default queue


# nested query will return the very first message forwarding record for the selected host - first records 
# is always Default Queue record
$sql1 = <<<DELIMITER1

UPDATE TA_FORWARD_RULES_MESSAGES
SET DL_QUEUE_ID=:currentqueueid
WHERE DL_ID=(SELECT MIN(DL_ID) FROM TA_FORWARD_RULES_MESSAGES WHERE DL_HOST_ID=:currenthostid)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':currentqueueid',$_REQUEST['frm2hidden3selectedqueueid']);			# parametrized queries = good protection against SQL injection
$stmt->bindParam(':currenthostid',$_REQUEST['frm1hidden3selectedhostid']);			# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}



}




## end - html form post actions handlers





echo "<form name='frm1' id='frm1' action='".$thisFilename."?a=7' method='post'>";	# start of main form for this action (3 merged into 1, items have split naming)


echo "<table border=1 width=100% height=200><tr><td valign='top'>";


# definition of form frm1


#echo "<form name='frm1' id='frm1' action='".$thisFilename."?a=7' method='post'>";	# start of main form (3 merged into 1, items have split naming)

echo "<b>Hosts</b> (Zabbix hostname or IP of any other sender) :<br>";
echo "<select name='frm1list1Hosts' id='frm1list1Hosts' size=25 style='width:300px;' onClick='frm1list1OnItemSelected();'>";

$sql1 = <<<DELIMITER1

SELECT DL_ID,DS_HOST_NAME
FROM TA_FORWARD_RULES_HOSTS
ORDER BY DS_HOST_NAME

DELIMITER1;

$stmt = $db->prepare($sql1);
$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$tmpStr1="";
if (isset($_REQUEST['frm1hidden3selectedhostid'])){

#echo "***************".$_REQUEST['frm1hidden3selectedhostid']."------------".$row[0];

      if ($_REQUEST['frm1hidden3selectedhostid']==$row[0]){
	  $tmpStr1=" selected";
      }
}

echo "<option id='frm1list1Hosts_Item_".$row[0]."' dbid='".$row[0]."'".$tmpStr1.">".$row[1];


}


echo "</select><br>";

echo "<input type='button' name='frm1btn2RemoveHost' id='frm1btn2RemoveHost' value='Delete Selected Host' onClick='frm1ConfirmAndSubmit2();'><br><br>";
echo "<input type='button' name='frm1btn4RemoveHostTemplatedRules' id='frm1btn4RemoveHostTemplatedRules' value='Add Selected Templates To Selected Host' onClick='frm1ConfirmAndSubmit4();'><br>";
echo "<input type='button' name='frm1btn3RemoveHostTemplatedRules' id='frm1btn3RemoveHostTemplatedRules' value='Remove Templated Rules From Selected Host' onClick='frm1ConfirmAndSubmit3();'><br><br>";



HostAddFwRulesTemplated_GenerateTemplateList();



echo "<input type='text' name='frm1text1NewHostName' id='frm1text1NewHostName' size=30><br>";
echo "<input type='button' name='frm1btn1AddNewHost' id='frm1btn1AddNewHost' value='Add New Host (case sensitive)' onClick='frm1ConfirmAndSubmit1();'>";





$tmpStr2="";
if (isset($_REQUEST['frm1hidden2selectedhost'])){
$tmpStr2=$_REQUEST['frm1hidden2selectedhost'];
}

$tmpStr3="";
if (isset($_REQUEST['frm1hidden3selectedhostid'])){
$tmpStr3=$_REQUEST['frm1hidden3selectedhostid'];
}

$tmpStr4="";
if (isset($_REQUEST['frm2hidden2selectedqueue'])){
$tmpStr4=$_REQUEST['frm2hidden2selectedqueue'];
}

$tmpStr5="";
if (isset($_REQUEST['frm2hidden3selectedqueueid'])){
$tmpStr5=$_REQUEST['frm2hidden3selectedqueueid'];
}



echo "<input type='hidden' name='frm1hidden1formaction' id='frm1hidden1formaction' value=0>";
echo "<input type='hidden' name='frm1hidden2selectedhost' id='frm1hidden2selectedhost' value='".$tmpStr2."'>";
echo "<input type='hidden' name='frm1hidden3selectedhostid' id='frm1hidden3selectedhostid' value='".$tmpStr3."'>";


#echo "</form>";



echo "</td><td valign='top'>";


# definition of form frm2


#echo "<form name='frm2' id='frm2' action='".$thisFilename."?a=7' method='post'>";

echo "<b>Zabbix Host Forward Queues</b> (Zabbix trapper item keys) :<br>";
echo "<select name='frm2list1Queues' id='frm2list1Queues' size=30 style='width:250px;' onClick='frm2list1OnItemSelected();'>";

$sql1 = <<<DELIMITER1

SELECT DL_ID,DS_QUEUE_NAME
FROM TA_FORWARD_RULES_QUEUES
ORDER BY DS_QUEUE_NAME

DELIMITER1;

$stmt = $db->prepare($sql1);
$results = $stmt->execute();

while ($row = $results->fetchArray()) {

$tmpStr1="";
if (isset($_REQUEST['frm2hidden3selectedqueueid'])){
      if ($_REQUEST['frm2hidden3selectedqueueid']==$row[0]){
	  $tmpStr1=" selected";
      }
}

echo "<option id='frm2list1Queues_Item_".$row[0]."' dbid='".$row[0]."'".$tmpStr1.">".$row[1];


}

echo "</select><br>";

echo "<input type='button' name='frm2btn2RemoveQueue' id='frm2btn2RemoveQueue' value='Delete Selected Queue' onClick='frm2ConfirmAndSubmit2();'><br><br>";

echo "<input type='text' name='frm2text1NewQueueName' id='frm2text1NewQueueName' size=30><br>";
echo "<input type='button' name='frm2btn1AddNewQueue' id='frm2btn1AddNewQueue' value='Add New Queue (case sensitive)' onClick='frm2ConfirmAndSubmit1();'>";



echo "<input type='hidden' name='frm2hidden1formaction' id='frm2hidden1formaction' value=0>";
echo "<input type='hidden' name='frm2hidden2selectedqueue' id='frm2hidden2selectedqueue' value='".$tmpStr4."'>";
echo "<input type='hidden' name='frm2hidden3selectedqueueid' id='frm2hidden3selectedqueueid' value='".$tmpStr5."'>";

#echo "</form>";




echo "</td><td valign='top'>";






# definition of form frm3


#echo "<form name='frm3' id='frm3' action='".$thisFilename."?a=7' method='post'>";


$tmpStr1="";
if (isset($_REQUEST['frm1hidden2selectedhost'])){
$tmpStr1=$_REQUEST['frm1hidden2selectedhost'];
}


$tmpStr2="";
if (isset($_REQUEST['frm2hidden2selectedqueue'])){
$tmpStr2=$_REQUEST['frm2hidden2selectedqueue'];
}

echo "<b>SNMP Trap Messages Zabbix Forwarding Rules</b> (messageOID => hostName => forwardQueue) :<br>";
echo "<select name='frm3list1Messages' id='frm3list1Messages' size=30 style='width:950px;background-color:#AAFFFF;' onClick='frm3list1OnItemSelected();'>";



if (isset($_REQUEST['frm1hidden3selectedhostid'])){

$sql1 = <<<DELIMITER1

SELECT A.DL_ID,A.DS_MSG_OID,B.DS_QUEUE_NAME,C.DS_HOST_NAME,C.DL_DEFAULT_QUEUE_ID,A.DL_QUEUE_ID,A.DS_RULE_ORIGIN
FROM TA_FORWARD_RULES_MESSAGES A,TA_FORWARD_RULES_QUEUES B, TA_FORWARD_RULES_HOSTS C
WHERE A.DL_QUEUE_ID=B.DL_ID AND A.DL_HOST_ID=C.DL_ID AND A.DL_HOST_ID=:currenthostid
ORDER BY DS_MSG_OID

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':currenthostid',$_REQUEST['frm1hidden3selectedhostid']);			# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

while ($row = $results->fetchArray()) {


$tmpStr3="";
if (isset($_REQUEST['frm3hidden3selectedmessageid'])){
      if ($_REQUEST['frm3hidden3selectedmessageid']==$row[0]){
	  $tmpStr3=" selected";
      }
}


$tmpStr4="";
if (($row[3]=="UNLISTED_HOSTS")&&($row[1]=="UNLISTED_MESSAGES")){
$tmpStr4="(msgs are forwarded to $thisProxyZabbixHostName)";
}


$tmpStr5="";
if (($row[1]=='UNLISTED_MESSAGES')){
$tmpStr5="(Default Queue)";
}


$tmpStr6=$row[6];
if (($tmpStr6!='manual')&&($tmpStr6!='system')){
  $tmpStr6='template '.$tmpStr6;
}



echo "<option id='frm3list1Messages_Item_".$row[0]."' dbid='".$row[0]."'".$tmpStr3.">".$row[1]." => ".$row[3]."$tmpStr4 => ".$row[2].$tmpStr5." [rule origin: ".$tmpStr6."]";

}



}

echo "</select><br>";

echo "<input type='button' name='frm3btn2RemoveMessage' id='frm3btn2RemoveMessage' value='Delete Selected Rule' onClick='frm3ConfirmAndSubmit2();'><br><br>";

echo "<table><tr><td valign='top'>";

echo "Add new SNMP Trap Message Forward Rules here.<br>On destination host<br>";
echo "<input type='text' name='frm3text2CurrentHost' id='frm3text2CurrentHost' value='".$tmpStr1."' size=50 style='background-color:silver;' readonly><br>";
echo "forward SNMP trap messages with OID<br><input type='text' name='frm3text1NewMessage' id='frm3text1NewMessage' size=50><br>";
echo "to queue<br><input type='text' name='frm3text3CurrentQueue' id='frm3text3CurrentQueue' value='".$tmpStr2."' size=50 style='background-color:silver;' readonly><br>";
echo "<input type='button' name='frm3btn1AddNewMessage' id='frm3btn1AddNewMessage' value='Add Rule' onClick='frm3ConfirmAndSubmit1();'>";



echo "</td><td>&nbsp;</td><td valign='top'>";


echo "Select Default Queue here (all unlisted messages will be forwarded to it)<br>For destination host<br>";
echo "<input type='text' name='frm3text4CurrentHost' id='frm3text4CurrentHost' value='".$tmpStr1."' size=50 style='background-color:silver;' readonly><br>";
echo "change Default Queue to<br><input type='text' name='frm3text5CurrentQueue' id='frm3text5CurrentQueue' value='".$tmpStr2."' size=50 style='background-color:silver;' readonly><br>";
echo "<input type='button' name='frm3btn3ChangeDefaultQueue' id='frm3btn3ChangeDefaultQueue' value='Change Now' onClick='frm3ConfirmAndSubmit3();'>";


echo "</td></tr></table>";



echo "<input type='hidden' name='frm3hidden1formaction' id='frm3hidden1formaction' value=0>";
echo "<input type='hidden' name='frm3hidden2selectedmessage' id='frm3hidden2selectedmessage' value=''>";
echo "<input type='hidden' name='frm3hidden3selectedmessageid' id='frm3hidden3selectedmessageid' value=''>";





#echo "</form>";			# end of main form (3 merged into 1, items have split naming)








echo "</td></tr></table>";


echo "</form>";			# end of main form (3 merged into 1, items have split naming)




}








function fnIgnoreList(){
global $coreDatabaseFileName;
global $thisFilename;
global $sqliteBusyTimeout;





$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);
$db->busyTimeout($sqliteBusyTimeout);






## html form post actions handlers



if (isset($_REQUEST['frm7hidden1formaction'])){


$postFrm7Action=$_REQUEST['frm7hidden1formaction'];



if ($postFrm7Action==1){			# # add new ip address to maintenance




$sql1 = <<<DELIMITER1

INSERT INTO TA_MAINTENANCE
(DS_HOST_IP,DT_START,DT_END,DS_NOTE) VALUES (:hostip,:from,:to,:note)

DELIMITER1;

$stmt = $db->prepare($sql1);
$stmt->bindParam(':hostip',$_REQUEST['frm7text1Host']);		# parametrized queries = good protection against SQL injection
$stmt->bindParam(':from',$_REQUEST['frm7text2From']);		# parametrized queries = good protection against SQL injection
$stmt->bindParam(':to',$_REQUEST['frm7text3To']);		# parametrized queries = good protection against SQL injection
$stmt->bindParam(':note',$_REQUEST['frm7text4Note']);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();

}




}








## end - html form post actions handlers



echo getGenericPageHeader1("<b>Ignore List/Maintenance Setup</b> :");



echo "<form name='frm7' id='frm7' action='".$thisFilename."?a=11' method='post'>";	# start of main form for this action

echo "<b>Active Maintenance Configs:</b><br>";

echo "<table border=1>";


echo "<tr>";

echo "<td>Id</td>";
echo "<td>IP</td>";
echo "<td>Start</td>";
echo "<td>End</td>";
echo "<td>Note</td>";


echo "</tr>";



    
$sql1 = <<<DELIMITER1

SELECT A.DL_ID,A.DS_HOST_IP,A.DT_START,A.DT_END,A.DS_NOTE 
FROM TA_MAINTENANCE A 
WHERE A.DL_STATUS=1
AND A.DT_START<datetime('now','localtime')
AND A.DT_END>datetime('now','localtime')
ORDER BY A.DL_ID;

DELIMITER1;

    



$stmt = $db->prepare($sql1);
$results = $stmt->execute();



while ($row = $results->fetchArray()) {


echo "<tr>";
echo "<td>".$row[0]."</td>";
echo "<td>".$row[1]."</td>";
echo "<td>".$row[2]."</td>";
echo "<td>".$row[3]."</td>";
echo "<td>".$row[4]."</td>";

#$tempStr1="";
#if (!IsHostListed($row[2])){
#    $tempStr1="<input type='button' hostname='".$row[2]."' value='Add host to Forwarding Rules Host List' onClick='frm4ConfirmAndSubmit1(this);'>";
#}

#if ($tempStr1!=""){
#echo "<td>".$tempStr1."</td>";
#}

echo "</tr>";

      
    
}


echo "</table>";
echo "<hr>";

echo "<b>New Maintenance Config:</b><br>";

echo "<p>Host IP&nbsp;<input type='text' name='frm7text1Host' id='frm7text1Host' size=20></p>";
echo "<p>Maintenance from <input type='text' name='frm7text2From' id='frm7text2From' size=25 value='".date("Y-m-d H:i:s")."'>&nbsp;to&nbsp;<input type='text' name='frm7text3To' id='frm7text3To' size=25 value='".date("Y-m-d H:i:s",strtotime('+1 hours'))."'></p>";
echo "<p>Note&nbsp;<input type='text' name='frm7text4Note' id='frm7text4Note' size=100></p>";
echo "<input type='button' value='Add Host to Maintenance' onClick='frm7ConfirmAndSubmit1(this);'>";



echo "<input type='hidden' name='frm7hidden1formaction' id='frm7hidden1formaction' value=0>";



echo "</form>";


}












function fnShowLocallyKnownZabbixHosts(){
global $coreDatabaseFileName;
global $thisFilename;
#global $thisProxyZabbixVersionMajor;
#global $genericPageHeader1;
global $sqliteBusyTimeout;


$destZabbixProxy=readSettingFromDatabase1('DESTINATION_ZABBIX_PROXY');

if ( !isset($destZabbixProxy) ) {
	logEvent( 2,
		"DESTINATION_ZABBIX_PROXY does not exist in TA_SETTINGS. Terminating."
	);
	die;
}



echo getGenericPageHeader1("<b>List of Zabbix hostnames known to this agent (list fetched from ".$destZabbixProxy.")</b> :");






## html form post actions handlers



if (isset($_REQUEST['frm4hidden1formaction'])){


$postFrm4Action=$_REQUEST['frm4hidden1formaction'];




if ($postFrm4Action==1){			# add new host to TA_FORWARD_RULES_HOSTS

  InsertNewHostToForwardRulesHostList($_REQUEST['frm4hidden2newhostname']);

}




}



## end - html form post actions handlers




echo "<form name='frm4' id='frm4' action='".$thisFilename."?a=6' method='post'>";	# start of main form for this action

echo "<table border=1>";


echo "<tr>";

echo "<td>Id</td>";
echo "<td>IP</td>";
echo "<td>Zabbix Hostname Mapping</td>";
echo "<td>Record updated</td>";


echo "</tr>";



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);





    
$sql1 = <<<DELIMITER1

SELECT A.DL_HOSTID,A.DS_IP,B.DS_HOST,B.DT_TIMESTAMP
FROM TA_PROXYDATACACHE_INTERFACES A, TA_PROXYDATACACHE_HOSTS B
WHERE A.DL_HOSTID=B.DL_HOSTID
ORDER BY A.DL_HOSTID;

DELIMITER1;

   




$stmt = $db->prepare($sql1);
$results = $stmt->execute();



while ($row = $results->fetchArray()) {


echo "<tr>";
echo "<td>".$row[0]."</td>";
echo "<td>".$row[1]."</td>";
echo "<td>".$row[2]."</td>";
echo "<td>".$row[3]."</td>";

$tempStr1="";
if (!IsHostListed($row[2])){
    $tempStr1="<input type='button' hostname='".$row[2]."' value='Add host to Forwarding Rules Host List' onClick='frm4ConfirmAndSubmit1(this);'>";
}

if ($tempStr1!=""){
echo "<td>".$tempStr1."</td>";
}

echo "</tr>";

      
    
}


echo "</table>";


echo "<br>";
HostAddFwRulesTemplated_GenerateTemplateList();



echo "</form>";


}


function HostAddFwRulesTemplated_GenerateTemplateList(){
global $hostAddFwRulesTemplated_TemplatesDirectory;



echo "Forward Rule Templates available:</br>";
echo "<select name='frm6list1Templates' id='frm6list1Templates' size=10 style='width:300px;' multiple='multiple'>";

foreach (glob($hostAddFwRulesTemplated_TemplatesDirectory."/*.template") as $filename) {
    
      $parts 			= Explode('/', $filename);
      $filenamePart		= $parts[count($parts) - 1];
      
      $parts 			= Explode('.', $filenamePart);
      $filenamePart		= $parts[count($parts) - 2];
      
      echo "<option value='$filenamePart'>$filenamePart</option>";
}



echo "</select>";




echo "<input type='hidden' name='frm4hidden1formaction' id='frm4hidden1formaction' value=0>";
echo "<input type='hidden' name='frm4hidden2newhostname' id='frm4hidden2newhostname' value=0>";



echo "<input type='hidden' name='frm6hidden1selectedtemplates' id='frm6hidden1selectedtemplates' value=''>";



}



function fnShowDiagAndMaintenanceDashboard(){
global $thisFilename;
global $thisProxyZabbixHostName;
#global $genericPageHeader1;


echo getGenericPageHeader1("<b>Diag and Config Dispatch :</b>");
#echo "<b>$genericPageHeader1 - Dashboard :</b><br><br><br>";


echo "<b>CONFIGURATION:</b><br>";

echo "<a href='".$thisFilename."?a=7' target='_blank'>Edit Trap Message Forwarding Rules</a><br>";
echo "<a href='".$thisFilename."?a=11' target='_blank'>Ignore List/Maintenance</a><br>";
echo "<a href='".$thisFilename."?a=4' target='_blank'>View Loaded MIB Conversions</a><br>";
echo "<a href='".$thisFilename."?a=6' target='_blank'>View Locally Known Zabbix Hostnames</a><br>";

echo "<br><b>DIAGNOSTICS:</b><br>";

echo "<a href='".$thisFilename."?a=3' target='_blank'>View SNMPTRAPD Log File</a><br>";
echo "<a href='".$thisFilename."?a=2' target='_blank'>View Core Scripts Log File</a><br>";
echo "<a href='".$thisFilename."?a=10' target='_blank'>View Trap Messages Processed by SNMPTT_HELPER</a><br>";

}



function fnDumpSNMPTTIniFileTrapFilesSection()
{

global $SNMPTTIniFileName;


echo getGenericPageHeader1("<b>Currently Loaded MIB Conversions </b>(shows section [TrapFiles] from ".$SNMPTTIniFileName.") :");
#echo "<b>Currently Loaded MIBS </b>(shows section [TrapFiles] from ".$SNMPTTIniFileName." - more at http://confluence) :<br><br>";



PrintSNMPTTTrapFiles($SNMPTTIniFileName);




}







function fnDumpCoreScriptsLogFile()
{				
global $coreScriptsLogFileName;
#global $genericPageHeader1;

$linesToShow = 30;


echo getGenericPageHeader1("<b>Last ".$linesToShow." lines of ".$coreScriptsLogFileName." </b>(log messages from snmptt_helper.pl, get-data.pl, diag-n-maintain.pl) :");



PrintTextFileLastNLines($coreScriptsLogFileName,$linesToShow);



}







function fnDumpSNMPTTReceivedLogFile()
{				
global $SNMPTTReceivedLogFileName;
#global $genericPageHeader1;


$linesToShow = 30;


echo getGenericPageHeader1("<b>Last ".$linesToShow." lines of ".$SNMPTTReceivedLogFileName." </b> (shows all traps arriving from network to SNMPTRAPD on UDP port default 162) :");


PrintTextFileLastNLines($SNMPTTReceivedLogFileName,$linesToShow);



}





function getGenericPageHeader1($pageTitle){
global $thisProxyZabbixHostName;

return "<table border=0><tr><td width=100%><b>[SNMP trapper V3.1 Zabbix Proxy ".$thisProxyZabbixHostName."] - </b> $pageTitle</td><td><a target=_blank href='https://wiki.lab.com.au/display/ENG/Monitoring+SNMP+Trap+Messages+V2'>Help</a></td></tr></table><br>";
}









function fnSNMPTTHelperTrapsProcessedNavigationListOfRecordedMonths(){
global $coreDatabaseFileName;
global $thisFilename;
global $sqliteBusyTimeout;


$pageHeaderShared="<b>SNMP Trap Messages Processed by SNMPTT_Helper, month breakdown";



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);


$sql1 = <<<DELIMITER1

SELECT MIN(DATE(DT_TIMESTAMP)),date('now','localtime'),COUNT(1)

FROM TA_RECEIVED_TRAP_MSGS

DELIMITER1;


$stmt = $db->prepare($sql1);
$results = $stmt->execute();
$row = $results->fetchArray();



if (!isset($row[0])){				


echo getGenericPageHeader1($pageHeaderShared." :</b>");
echo "<br>Table is empty";


} else {				# if at least one record exists in TA_RECEIVED_TRAP_MSGS





	  $startingDate=$row[1];
	  $endingDate=$row[0];
	  $dbTotalMessageCount=$row[2];



	  echo getGenericPageHeader1($pageHeaderShared." :</b><br>");

	  echo "<table border=1>";


	  echo "<tr style='background-color:#E6E6E6;font-weight:bold;'><td>Month</td><tr>";


	  #$currentDate=date('Y-m-d', strtotime($startingDate. ' + 1 months'));
	  $currentDate=date('Y-m-d', strtotime($startingDate));


	  do {

		#$currentDate=date('Y-m-d', strtotime($currentDate. ' - 1 months'));



		echo "<tr>";
		
		
		
		$currentMonthFirstDay=date('Y-m-d', strtotime(date('Y',strtotime($currentDate))."-".date('n',strtotime($currentDate))."-1"));
		$currentMonthLastDay=date('Y-m-t', strtotime(date('Y',strtotime($currentDate))."-".date('n',strtotime($currentDate))."-1"));
		if ($currentMonthLastDay>$startingDate) {
		  $currentMonthLastDay=$startingDate;
		}

		echo "<td><a target=_blank href='$thisFilename?a=8&a8trg=$currentMonthFirstDay&a8trs=$currentMonthLastDay'>".date('F',strtotime($currentDate))." ".date('Y',strtotime($currentDate))."</a></td>";
		
		

		
		echo "</tr>";


		$currentDate=date('Y-m-d', strtotime($currentDate. ' - 1 months'));


	  #} while ($currentDate>$endingDate);
	  
	  
	  
	  $currentDateInteger=date('n',strtotime($currentDate))+(12*date('Y',strtotime($currentDate)));	# years multiplied by 12 + months	  
	  $endingDateInteger=date('n',strtotime($endingDate))+(12*date('Y',strtotime($endingDate)));	# years multiplied by 12 + months	  
	  
	  
	  } while ($currentDateInteger>=$endingDateInteger);








echo "</table>";

echo "<br>Total message count: ".$dbTotalMessageCount;


}

}

















function fnSNMPTTHelperTrapsProcessedNavigationListByDay(){
global $coreDatabaseFileName;
global $thisFilename;
global $sqliteBusyTimeout;


$pageHeaderShared="<b>SNMP Trap Messages Processed by SNMPTT_Helper, Daily Summary List";



$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);


if (isset($_GET['a8trg'])&&$_GET['a8trg']!=""){
  $startingDate=$_GET['a8trg'];
}


if (isset($_GET['a8trs'])&&$_GET['a8trs']!=""){
  $endingDate=$_GET['a8trs'];
}



$URLParamPersistence1="";
$URLParamPersistence2="";
$URLParamPersistence3="";

if (isset($_GET['a1zfrc'])&&$_GET['a1zfrc']!=""){
    $URLParamPersistence1=$_GET['a1zfrc'];
}

if (isset($_GET['a1ihr'])&&$_GET['a1ihr']!=""){				# action 1, DL_RECOGNIZED_ZABBIX_HOST
    $URLParamPersistence2=$_GET['a1ihr'];
}

if (isset($_GET['a1oidr'])&&$_GET['a1oidr']!=""){
    $URLParamPersistence3=$_GET['a1oidr'];
}







	  echo getGenericPageHeader1($pageHeaderShared." from $endingDate back to $startingDate :</b><br>");

	  echo "<table border=1>";


	  echo "<tr style='background-color:#E6E6E6;font-weight:bold;'><td>Date</td><td>Message Count</td><tr>";


	  $currentDate=date('Y-m-d', strtotime($endingDate. ' + 1 days'));

	  #echo "*".$currentDate."*";
	  
	  # delimiter to end this block has to be at the begin of the line
$sql1 = <<<DELIMITER1

			      SELECT COUNT(1)

			      FROM TA_RECEIVED_TRAP_MSGS
			      
			      WHERE DATE(DT_TIMESTAMP)=:currentdate

DELIMITER1;






$sql2="";




if (isset($_GET['a1zfrc'])&&$_GET['a1zfrc']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE=".$_GET['a1zfrc'];
}





if (isset($_GET['a1ihr'])&&$_GET['a1ihr']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_RECOGNIZED_ZABBIX_HOST=".$_GET['a1ihr'];
}





if (isset($_GET['a1oidr'])&&$_GET['a1oidr']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_RECOGNIZED_BY_SNMPTT=".$_GET['a1oidr'];
}





if ($sql2!=""){
    $sql1=$sql1." AND ".$sql2;
}





		$stmt = $db->prepare($sql1);
		#$stmt->bindParam(':currentdate',$currentDate);			# parametrized queries = good protection against SQL injection


	  

	  do {

	  
	  
		$currentDate=date('Y-m-d', strtotime($currentDate. ' - 1 days'));
		$currentDate=$currentDate."";			# has to be again retyped to text. $stmt->execute() always reevaluates this parameter and if it is date, it would not pass its value correctly to the sql statement

		$stmt->bindParam(':currentdate',$currentDate);			# parametrized queries = good protection against SQL injection
		
		$results = $stmt->execute();
		$row = $results->fetchArray();
		

		echo "<tr>";

		echo "<td>".$currentDate."</td>";
		
		
		#echo "<td>".$sql1."***".$currentDate."</td>";
		
		$tmpStr1="";
		if ($row[0]>0){
		      $tmpStr1="<td align=center><a target=_blank href='$thisFilename?a=1&a1trg=$currentDate&a1trs=$currentDate&a1zfrc=$URLParamPersistence1&a1ihr=$URLParamPersistence2&a1oidr=$URLParamPersistence3'>$row[0]</a></td>";
		} else {
		    $tmpStr1="<td align=center>0</td>";
		}
		
		echo $tmpStr1;
		
		echo "</tr>";


		


	  } while ($currentDate>$startingDate);




echo "</table>";


}






function fnReportSNMPTTHelperTrapsProcessed() {				# report-all traps received
global $coreDatabaseFileName;
global $thisFilename;
#global $trapReportDebugInfo;
global $sqliteBusyTimeout;



$selectedDate="";
$pageHeaderShared="<b>SNMP Trap Messages Processed by SNMPTT_Helper ";



$strTmp1="";
if (isset($_REQUEST['d'])){
$selectedDate=$_REQUEST['d'];
$strTmp1="on ".$selectedDate;
}



echo getGenericPageHeader1($pageHeaderShared.$strTmp1." :</b>");



## report search filter config



echo "<FORM name='frm5' id='frm5' action='".$thisFilename."?a=1' method='post'>";	# start of main form for this action



echo "<table border=1>";


echo "<TR>";

echo "<TD>";

echo "Message Search Conditions :<br><br>";






if (isset($_GET['a1ts'])&&$_GET['a1ts']!=""){
  $_REQUEST['frm5text1SearchConditionTrapSource']=$_GET['a1ts'];	# hack push ULR param value to HTML form field value
}

$tmpStr1="";
if (isset($_REQUEST['frm5text1SearchConditionTrapSource'])&&$_REQUEST['frm5text1SearchConditionTrapSource']!=""){
      $tmpStr1=$_REQUEST['frm5text1SearchConditionTrapSource'];
}








if (isset($_GET['a1toid'])&&$_GET['a1toid']!=""){
  $_REQUEST['frm5text2SearchConditionTrapOID']=$_GET['a1toid'];	# hack push ULR param value to HTML form field value
}

$tmpStr2="";
if (isset($_REQUEST['frm5text2SearchConditionTrapOID'])&&$_REQUEST['frm5text2SearchConditionTrapOID']!=""){
      $tmpStr2=$_REQUEST['frm5text2SearchConditionTrapOID'];
}








if (isset($_GET['a1trg'])&&$_GET['a1trg']!=""){
  $_REQUEST['frm5text3SearchConditionTimeReceivedGreater']=$_GET['a1trg'];	# hack push ULR param value to HTML form field value
}

$tmpStr3="";
if (isset($_REQUEST['frm5text3SearchConditionTimeReceivedGreater'])&&$_REQUEST['frm5text3SearchConditionTimeReceivedGreater']!=""){
      $tmpStr3=$_REQUEST['frm5text3SearchConditionTimeReceivedGreater'];
}









if (isset($_GET['a1trs'])&&$_GET['a1trs']!=""){
  $_REQUEST['frm5text4SearchConditionTimeReceivedSmaller']=$_GET['a1trs'];	# hack push ULR param value to HTML form field value
}

$tmpStr4="";
if (isset($_REQUEST['frm5text4SearchConditionTimeReceivedSmaller'])&&$_REQUEST['frm5text4SearchConditionTimeReceivedSmaller']!=""){
      $tmpStr4=$_REQUEST['frm5text4SearchConditionTimeReceivedSmaller'];
}








if (isset($_GET['a1zfrc'])&&$_GET['a1zfrc']!=""){
  $_REQUEST['frm5text5SearchConditionForwardingResultCode']=$_GET['a1zfrc'];	# hack push ULR param value to HTML form field value
}


$tmpStr5="";
if (isset($_REQUEST['frm5text5SearchConditionForwardingResultCode'])&&$_REQUEST['frm5text5SearchConditionForwardingResultCode']!=""){
      $tmpStr5=$_REQUEST['frm5text5SearchConditionForwardingResultCode'];
}








if (isset($_GET['a1ihr'])&&$_GET['a1ihr']!=""){
  $_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized']=$_GET['a1ihr'];	# hack push ULR param value to HTML form field value
}

$tmpStr6="";
if (isset($_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized'])&&$_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized']!=""){
      $tmpStr6=$_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized'];
}










if (isset($_GET['a1oidr'])&&$_GET['a1oidr']!=""){
  $_REQUEST['frm5text7SearchConditionIsOIDResolved']=$_GET['a1oidr'];	# hack push ULR param value to HTML form field value
}

$tmpStr7="";
if (isset($_REQUEST['frm5text7SearchConditionIsOIDResolved'])&&$_REQUEST['frm5text7SearchConditionIsOIDResolved']!=""){
      $tmpStr7=$_REQUEST['frm5text7SearchConditionIsOIDResolved'];
}






echo " Source IP LIKE <input type='text' name='frm5text1SearchConditionTrapSource' id='frm5text1SearchConditionTrapSource' value='".$tmpStr1."' size=20 >";
echo " AND Trap OID LIKE <input type='text' name='frm5text2SearchConditionTrapOID' id='frm5text2SearchConditionTrapOID' value='".$tmpStr2."' size=40 >";
echo " AND Time Received FROM <input type='text' name='frm5text3SearchConditionTimeReceivedGreater' id='frm5text3SearchConditionTimeReceivedGreater' value='".$tmpStr3."' size=15 >[date part] ";
echo " TO <input type='text' name='frm5text4SearchConditionTimeReceivedSmaller' id='frm5text4SearchConditionTimeReceivedSmaller' value='".$tmpStr4."' size=15 >[date part]<br>";

echo " AND Zabbix Forwarding Operation Result Code IS <input type='text' name='frm5text5SearchConditionForwardingResultCode' id='frm5text5SearchConditionForwardingResultCode' value='".$tmpStr5."' size=5 >";
echo " AND Zabbix Host Identified IS <input type='text' name='frm5text6SearchConditionIsZabbixHostRecognized' id='frm5text6SearchConditionIsZabbixHostRecognized' value='".$tmpStr6."' size=5 >";
echo " AND OID recognized by SNMPTT IS <input type='text' name='frm5text7SearchConditionIsOIDResolved' id='frm5text7SearchConditionIsOIDResolved' value='".$tmpStr7."' size=5 >";




echo "<br><div align=right><input type='button' name='frm5btn2Clear' id='frm5btn2Clear' value='Clear Form' onClick='frm5btn2ClearOnClick();'></div>";

echo "</TD>";

echo "</TR>";


echo "<TD>";

echo "<input type='submit' name='frm5btn1Search' id='frm1btn1Search' value='  Search Now  '>";

echo "</TD>";


echo "</table>";


echo "</FORM>";


#echo "<br>";






## report result



echo "<table border=1>";

echo "<tr style='background-color:#E6E6E6;'><td>#</td><td>Trap Event Detail</td></tr>";






$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);



$sql1 = <<<DELIMITER1

SELECT  DS_GUID,
DT_TIMESTAMP,
DS_SOURCE_HOST,
DS_ZABBIX_SENDER_FORWARDING_HOST,
DS_ZABBIX_SENDER_FORWARDING_QUEUE,
DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE,
DS_ZABBIX_SENDER_FORWARDING_ERROR_DESCRIPTION,
DL_RECOGNIZED_BY_SNMPTT,
DL_RECOGNIZED_ZABBIX_HOST,
DS_SOURCE_IP,
DS_SEVERITY,
DS_NAME,
DS_ADD_INFO,
DS_OID,
(SELECT COUNT(1) FROM TA_RECEIVED_TRAP_MSGS

DELIMITER1;





$sql2="";



if (isset($_REQUEST['frm5text1SearchConditionTrapSource'])&&$_REQUEST['frm5text1SearchConditionTrapSource']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DS_SOURCE_IP LIKE '%".$_REQUEST['frm5text1SearchConditionTrapSource']."%'";
}




if (isset($_REQUEST['frm5text2SearchConditionTrapOID'])&&$_REQUEST['frm5text2SearchConditionTrapOID']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DS_OID LIKE '%".$_REQUEST['frm5text2SearchConditionTrapOID']."%'";
}




if (isset($_REQUEST['frm5text3SearchConditionTimeReceivedGreater'])&&$_REQUEST['frm5text3SearchConditionTimeReceivedGreater']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DATE(DT_TIMESTAMP)>='".$_REQUEST['frm5text3SearchConditionTimeReceivedGreater']."'";
}




if (isset($_REQUEST['frm5text4SearchConditionTimeReceivedSmaller'])&&$_REQUEST['frm5text4SearchConditionTimeReceivedSmaller']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DATE(DT_TIMESTAMP)<='".$_REQUEST['frm5text4SearchConditionTimeReceivedSmaller']."'";
}




if (isset($_REQUEST['frm5text5SearchConditionForwardingResultCode'])&&$_REQUEST['frm5text5SearchConditionForwardingResultCode']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE=".$_REQUEST['frm5text5SearchConditionForwardingResultCode'];
}






if (isset($_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized'])&&$_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_RECOGNIZED_ZABBIX_HOST=".$_REQUEST['frm5text6SearchConditionIsZabbixHostRecognized'];
}







if (isset($_REQUEST['frm5text7SearchConditionIsOIDResolved'])&&$_REQUEST['frm5text7SearchConditionIsOIDResolved']!=""){
	if ($sql2!=""){
	    $sql2=$sql2." AND";
	}
$sql2=$sql2." DL_RECOGNIZED_BY_SNMPTT=".$_REQUEST['frm5text7SearchConditionIsOIDResolved'];
}





if ($sql2!=""){
    $sql1=$sql1." WHERE ".$sql2;
}



$sql1=$sql1.") AS rowcount FROM TA_RECEIVED_TRAP_MSGS ";



if ($sql2!=""){
    $sql1=$sql1." WHERE ".$sql2;
}


$sql1=$sql1." ORDER BY DL_ID DESC";



#echo $sql1."<br>";

$resultRowCounter=-1;



$stmt = $db->prepare($sql1);
$results = $stmt->execute();


while ($row = $results->fetchArray()) {


if ($resultRowCounter==-1){
  $resultRowCounter=$row[14];
  echo $row[14]." messages found (listed from latest) :<br><br>";
}



#echo "<tr><td>".$row[0]."</td>";

echo "<tr><td>&nbsp;#".$resultRowCounter."&nbsp;</td>";



$resultRowCounter=$resultRowCounter-1;



echo "<td style='padding: 3; margin: 0; display: inline;' width=100%>";





if ($row[7]=='1'){		# recognized trap info



echo "<b>Time Received:</b> ".$row[1]."<br>";


echo "<b>Source Host:</b> ";
$tmpStr1=$row[2];
if ($row[2]!=$row[9]){
  $tmpStr1= $row[2]." (".$row[9].")";
}
echo "$tmpStr1<br>";


echo "<b>Event Severity:</b> " .$row[10]."<br>";
echo "<b>Event Name:</b> ".$row[11]."<br>";
echo "<b>Event Detail:</b> ".$row[12]."<br>";;





} else {			# unrecognized trap info




echo "<b>Time Received: </b>".$row[1]."<br>";


echo "<b>Source Host: </b>";
$tmpStr1=$row[2];
if ($row[2]!=$row[9]){
  $tmpStr1= $row[2]." (".$row[9].")";
}
echo $tmpStr1."<br>";

echo "<b>OID: </b>".$row[13]."<br>";
echo "<b>Captured Parameters: </b>".$row[12]."<br>";



}



echo "<b>MsgGUID:</b> $row[0]<br>";
echo "<a target=_blank href='".$thisFilename."?a=9&msgguid=".$row[0]."'>Additional Info</a>";







echo "</td></tr>";

      
    
}






echo "</table>";



}





function PrintTextFileLastNLines($textFileName,$numberOfLinesToShow)
{



$fp = fopen($textFileName, 'r');


$lineCounter = 0;

$pos = -1; // Skip final new line character (Set to -1 if not present)

$lines = array();
$currentLine = '';

while ($lineCounter <= $numberOfLinesToShow && -1 !== fseek($fp, $pos, SEEK_END)) {
    $char = fgetc($fp);
    if (PHP_EOL == $char) {
            $lines[] = $currentLine;
            $currentLine = '';
            $lineCounter++;
    } else {
            $currentLine = $char . $currentLine;
    }
    $pos--;
}

$lines[] = $currentLine; // Grab final line



if ($numberOfLinesToShow>$lineCounter){			# if file is shorter than max we want to print
$numberOfLinesToShow=$lineCounter;
}


for ($i = $numberOfLinesToShow; $i >= 0; $i--) {
    echo htmlspecialchars($lines[$i])."<br>";
}





    #return $num * $num;
}



 



function PrintSNMPTTTrapFiles($SNMPTTIniFileName)
{
$copyMode=0;
$fileNames=array();
$printLine=0;
$mibSectionCounter=0;


$handle = fopen($SNMPTTIniFileName, "r");
if ($handle) {
    while (($line = fgets($handle)) !== false) {
        
     
        if ($printLine==0){                     # currently not displaying lines

    
        if (preg_match("/\[TrapFiles\]/", $line, $matches)){
    
            $printLine=1;
        }
    
    
        } else {                                # currently displaying lines
    
    
        if (preg_match("/\[.*\]/", $line, $matches)){
    
            $printLine=0;
        }
    
    
        }
    
    
    
        if ($printLine==1){
                echo htmlspecialchars($line)."<br>";
                
                
                if (preg_match("/snmptt_conf_files.*=/", $line, $matches)){
		    $copyMode=1;
		}
		 
		if (preg_match("/^END/", $line, $matches)){
		    $copyMode=0;
		}
                
        }
    
	
	
	if ($copyMode==1){
		array_push($fileNames,chop($line,"\n"));
	}

        
    }
    
    
    
} else {
    // error opening the file.
} 


fclose($handle);




for ($i = 1; $i < (count($fileNames)); $i++) {
    #echo "$i:".$fileNames[$i]."*\n";
    #PrintSNMPTTConfFileMIBSections($fileNames[$i]);
    
echo "<br><br><br>* $fileNames[$i] dump :<br><br>";
    
$mibSectionCounter=0;    
$handle = fopen($fileNames[$i], "r");
if ($handle) {
    while (($line = fgets($handle)) !== false) {
        
    
        if (preg_match("/^MIB: /", $line, $matches)){    
	    $mibSectionCounter++;
            echo $mibSectionCounter.": ".$line."<br>";
        }
    
    
    }
    
} else {
    // error opening the file.
} 


fclose($handle);


    
    
    
    
}





}
  

  
  
  
  



//Function to catch no user error handler function errors...
function GlobalShutdownHandler(){

    $error = error_get_last();
    
    echo 'Script shutdown';

#    if($error && ($error['type'] & E_FATAL)){
#        GlobalErrorHandler($error['type'], $error['message'], $error['file'], $error['line']);
#    }


if (!defined(PROGRAM_EXECUTION_SUCCESSFUL)) {
        GlobalErrorHandler($error['type'], $error['message'], $error['file'], $error['line']);
    }


}



function GlobalErrorHandler( $errno, $errstr, $errfile, $errline ) {

    switch ($errno){

        case E_ERROR: // 1 //
            $typestr = 'E_ERROR'; break;
        case E_WARNING: // 2 //
            $typestr = 'E_WARNING'; break;
        case E_PARSE: // 4 //
            $typestr = 'E_PARSE'; break;
        case E_NOTICE: // 8 //
            $typestr = 'E_NOTICE'; break;
        case E_CORE_ERROR: // 16 //
            $typestr = 'E_CORE_ERROR'; break;
        case E_CORE_WARNING: // 32 //
            $typestr = 'E_CORE_WARNING'; break;
        case E_COMPILE_ERROR: // 64 //
            $typestr = 'E_COMPILE_ERROR'; break;
        case E_CORE_WARNING: // 128 //
            $typestr = 'E_COMPILE_WARNING'; break;
        case E_USER_ERROR: // 256 //
            $typestr = 'E_USER_ERROR'; break;
        case E_USER_WARNING: // 512 //
            $typestr = 'E_USER_WARNING'; break;
        case E_USER_NOTICE: // 1024 //
            $typestr = 'E_USER_NOTICE'; break;
        case E_STRICT: // 2048 //
            $typestr = 'E_STRICT'; break;
        case E_RECOVERABLE_ERROR: // 4096 //
            $typestr = 'E_RECOVERABLE_ERROR'; break;
        case E_DEPRECATED: // 8192 //
            $typestr = 'E_DEPRECATED'; break;
        case E_USER_DEPRECATED: // 16384 //
            $typestr = 'E_USER_DEPRECATED'; break;
            
            
            
        default:
	    $typestr = 'UNKNOWN'; break;
        

    }

    #$message = '<b>'.$typestr.': </b>'.$errstr.' in <b>'.$errfile.'</b> on line <b>'.$errline.'</b><br/>';



    #$message = '<b>'.$typestr.': </b>'.$errstr.' in <b>'.$errfile.'</b> on line <b>'.$errline.'</b><br/>';


    ob_end_clean();								# invalidate response buffer
    ob_start();
    
    echo "<div style='background-color:pink;color:black;'>";
    echo "Global PHP exception $typestr occured in $errfile on line $errline: $errstr";
    echo "</div>";
    echo PHP_EOL;
    die;    
       
    
    #if(($errno & E_FATAL) && ENV === 'production'){

    #    header('Location: 500.html');
    #    header('Status: 500 Internal Server Error');

    #}



        
    //Logging error on php file error log...
    #if(LOG_ERRORS)
    #    error_log(strip_tags($message), 0);

}
  
  
  
  
  
  
function logEvent ($eventType, $msg ) {    # method Version: 3
global $coreScriptsLogFileName;
global $loggingLevel;
global $logOutput;
global $thisModuleID;


$t = microtime(true);
$micro = sprintf("%06d",($t - floor($t)) * 1000000);
$d = new DateTime( date('Y-m-d H:i:s.'.$micro,$t) );

$timestamp= $d->format("Y-m-d H:i:s.u"); // note at point on "u"



$eventTypeDisplay = "";

	if ( ( $loggingLevel == 0 ) || ( $logOutput == 0 ) ) {
		return 0;
	}

	
	switch ($eventType){

        case 1: 
            	$eventTypeDisplay = " Debug Info : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}
            break;
                                    
        case 2:             
            	$eventTypeDisplay = " !ERROR! : ";
            	
            break;

        case 3: 
            
            	$eventTypeDisplay = " Warning : ";

			if ( $loggingLevel == 1 ) {
				return 0;
			}
            break;                               
            
    }
	
	

	if ( ( $logOutput == 1 ) || ( $logOutput == 3 ) ) {

		echo "[$thisModuleID] $timestamp$eventTypeDisplay$msg\n";

	}

	if ( ( $logOutput == 2 ) || ( $logOutput == 3 ) ) {
	
		$logFileHandle = fopen($coreScriptsLogFileName,"a+");
		
		
		if (isset($logFileHandle)){
		
			fwrite($logFileHandle,"[$thisModuleID] $timestamp$eventTypeDisplay$msg\n");
			fclose($logFileHandle);
		}
		else {

			echo "Can not open logfile $coreScriptsLogFileName : $!\n";

		}

	}

}  
  
  
  


  
  
function ExecuteShellCommand($cmdLine,&$resultStdOut) {
$actionResult=0;

    $resultStdOut = `$cmdLine`;    # execute shell command

    $resultStdOut = explode("\n", $resultStdOut);
    #$resultStdOut= chop($resultStdOut,"\n");
    
    #echo $resultStdOut;
    
    
    $actionResult=1;


return $actionResult;

}  
  
  
  
#INSERT INTO TA_FORWARD_RULES_MESSAGES (DS_MSG_OID,DL_HOST_ID,DL_QUEUE_ID) SELECT '.1.2.3.4.5',:hostid,B.DL_ID FROM TA_FORWARD_RULES_QUEUES B WHERE B.DS_QUEUE_NAME='SNMPTrap-Queue3' LIMIT 1;
  

function HostAddFwRulesTemplated_LoadFile($templateFileName){
global $hostAddFwRulesTemplated_SQLArray;
global $hostAddFwRulesTemplated_TemplateNameArray;
global $hostAddFwRulesTemplated_TemplatesDirectory;

$handle = fopen($hostAddFwRulesTemplated_TemplatesDirectory.'/'.$templateFileName.'.template', "r");
if ($handle) {


    while (!feof($handle)) {
    
	$line = fgets($handle);
	
	#$line = "INSERT INTO TA_FORWARD_RULES_MESSAGES (DS_MSG_OID,DL_HOST_ID,DL_QUEUE_ID) SELECT '.1.2.3.4.5',:hostid,B.DL_ID FROM TA_FORWARD_RULES_QUEUES B WHERE B.DS_QUEUE_NAME='SNMPTrap-Queue3' LIMIT 1;";
	
	$line = chop($line);
	
	
	$isCommentLine=1;
		
	if (strpos($line,'#')=== false){
	    $isCommentLine=0;
	} else {	
	
	    if (strpos($line,'#')>0){
		$isCommentLine=0;
	     }	
	}
	
	
	if (($line!='')&&($isCommentLine==0)){
	
	    array_push($hostAddFwRulesTemplated_SQLArray, $line);
	    array_push($hostAddFwRulesTemplated_TemplateNameArray, $templateFileName);	    
	
	}
        
    }
    
    
    
} else {
    logEvent( 2,
		"Error 1 in HostAddFwRulesTemplated_LoadFile(). Can not open file $templateFileName"
	);
} 


fclose($handle);


}
  
  
  
function fnShowProcessedMessageDetail(){
global $coreDatabaseFileName;
global $thisFilename;
global $trapReportDebugInfo;
global $sqliteBusyTimeout;


$executeShellCommandResult=array();
$value='';
$msgPid=0;



echo getGenericPageHeader1("<b>Additional Trap Message Info :</b>");


if (isset($_GET['msgguid'])){
      $msgguid=$_GET['msgguid'];
} else {
      echo "Invalid input parameters.";
      exit();
}


echo "<br>";



echo "<table border=1 width=100%> ";

echo "<tr style='background-color:#E6E6E6;'><td>Trap Event Detail</td></tr>";




$db = new SQLite3($coreDatabaseFileName,SQLITE3_OPEN_READONLY);
$db->busyTimeout($sqliteBusyTimeout);



$sql1 = <<<DELIMITER1

SELECT  DS_GUID,
DT_TIMESTAMP,
DS_SOURCE_HOST,
DS_ZABBIX_SENDER_FORWARDING_HOST,
DS_ZABBIX_SENDER_FORWARDING_QUEUE,
DL_ZABBIX_SENDER_FORWARDING_RESULT_CODE,
DS_ZABBIX_SENDER_FORWARDING_ERROR_DESCRIPTION,
DL_RECOGNIZED_BY_SNMPTT,
DL_RECOGNIZED_ZABBIX_HOST,
DS_SOURCE_IP,
DS_SEVERITY,
DS_NAME,
DS_ADD_INFO,
DS_OID,
DS_ZABBIX_SENDER_FORWARDING_PROXY

FROM TA_RECEIVED_TRAP_MSGS 

WHERE DS_GUID=:msgguid;


DELIMITER1;




#echo $sql1."<br>";


$stmt = $db->prepare($sql1);
$stmt->bindParam(':msgguid',$msgguid);		# parametrized queries = good protection against SQL injection
$results = $stmt->execute();





#while ($row = $results->fetchArray()) {

$row = $results->fetchArray();


echo "<tr>";

echo "<td style='padding: 0; margin: 0; display: inline;' width=100%>";









# proxy-generated info


if ($row[7]=='1'){		# recognized trap info



echo "<b>Time Received:</b> ".$row[1]."<br>";


echo "<b>Source Host:</b> ";
$tmpStr1=$row[2];
if ($row[2]!=$row[9]){
  $tmpStr1= $row[2]." (".$row[9].")";
}
echo "$tmpStr1<br>";

echo "<b>Event Severity:</b> " .$row[10]."<br>";
echo "<b>Event Name:</b> ".$row[11]."<br>";
echo "<b>Event Detail:</b> ".$row[12]."<br>";;





} else {			# unrecognized trap info




echo "<b>Time Received: </b>".$row[1]."<br>";


echo "<b>Source Host: </b>";
$tmpStr1=$row[2];
if ($row[2]!=$row[9]){
  $tmpStr1= $row[2]." (".$row[9].")";
}
echo $tmpStr1."<br>";

echo "<b>OID: </b>".$row[13]."<br>";
echo "<b>Captured Parameters: </b>".$row[12]."<br>";



}



echo "<b>MsgGUID:</b> $row[0]<br>";
#echo "<a target=_blank href='".$thisFilename."?a=9&msgguid=".$row[0]."'>Extended Info</a>";




 

echo "</tr>";
echo "</table><br>";





# trap debug info

echo "<table border=1 width=100%><tr style='background-color:#E6E6E6' width=100%>";
echo "<td>Trapper Debug Info</td>";
echo "</tr><tr><td>";

if ($row[7]=='1'){
  echo "</b>OID: </b>".$row[13]."<br>";
}

echo "</b>OID recognized by SNMPTT(1 = yes): </b>".$row[7]."<br>";
echo "</b>Zabbix host identified by IP(1 = yes): </b>".$row[8]."<br>";
echo "</b>Forwarded to Zabbix proxy: </b>".$row[14]."<br>";
echo "</b>Forwarded to Zabbix host: </b>".$row[3];
if ($row[8]!='1'){
echo " (surrogate)";
}
echo "<br>";


echo "</b>Forwarded to queue(key): </b>".$row[4]."<br>";
echo "</b>Forwarding operation result code(1 = ok): </b>".$row[5]."<br>";

if ($row[5]!=1){
echo "</b>Forwarding operation error message: </b>".$row[6]."<br>";
}



echo "</td></tr>";
echo "</table>";
echo "<br>";




# Associated MIB Object Dump

echo "<table border=1 width=100%><tr style='background-color:#E6E6E6'>";
echo "<td>Associated MIB Object Dump</td>";
echo "</tr><tr><td>";




ExecuteShellCommand("snmptranslate -m ALL -On -Td ".$row[13],$executeShellCommandResult);

#print_r($executeShellCommandResult);


$arr_length = count($executeShellCommandResult);

if ($arr_length==1&&$executeShellCommandResult[0]==""){
	echo "No matching MIB record found. Please fix this by installing the relevant MIB on this trapper.<br>";
} else {

	for($i=0;$i<$arr_length;$i++)
	{
	    echo $executeShellCommandResult[$i];
	    
	    if ($i<($arr_length-1)){
	      echo "<br>";
	    }
	    
	}

}

echo "</td></tr></table>";




echo "<br><br><a target=_blank href='https://www.google.com/search?q=OID+".$row[13]."'>Search on Google for OID ".$row[13]."</a>";

#$currentDate=date('Y-m-d',strtotime($row[1]));
echo "<br><br><a target=_blank href='".$thisFilename."?a=1&a1ts=$row[9]&a1toid=$row[13]'>List all messages with OID $row[13] received from $row[9]</a>";




}



    
  
  
  
# eof- Service functions  
#################################################################################3
  
  
?>


</SPAN>                                                                                                                                                              


</body>

</html>


<?php
define('PROGRAM_EXECUTION_SUCCESSFUL', true);		# helps to detect the global shutdown handler whether script was completed successfully
?>