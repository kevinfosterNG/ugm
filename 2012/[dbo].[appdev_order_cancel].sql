CREATE PROCEDURE [dbo].[appdev_order_cancel]                    
 @pi_practice_id CHAR(4)=null,                    
 @pi_location_name CHAR(40)=null,                    
 @pi_actClass CHAR(10)=null,                    
 @pi_user_id CHAR(5)=null,        
 @pi_cutoff_date CHAR(10)=null                  
AS                      
DECLARE @enterprise_id CHAR(5)                    
SELECT @enterprise_id='00001'                    
-- =============================================                    
-- Author:  Kevin Foster & Drew Richards                    
-- Create date: 10/17/2014                  
-- Description: Stored procedure to cancel                    
-- orders for a specific time period.                  
-- =============================================                    
-- Example:  EXEC appdev_order_cancel '0001','NextCare Calle Santa Cruz','R','2600','20061231'               
DECLARE @orders_canceled_count INT
DECLARE @TEMP TABLE       
(      
 actClass  VARCHAR(50)                    
 ,actStatus  VARCHAR(50)                 
 ,actTextDisplay VARCHAR(500)                  
 ,person_id  VARCHAR(50)                
 ,last_name  VARCHAR(75)                 
 ,first_name  VARCHAR(75)                  
 ,DOB   VARCHAR(50)             
 ,locationname VARCHAR(100)                  
 ,enc_date  VARCHAR(50)          
 ,enc_date_sort VARCHAR(50)           
 ,payer   VARCHAR(500)            
 ,Age   VARCHAR(50)      
 ,privacy_level VARCHAR(1)
)      
      
INSERT INTO @TEMP (actClass,actStatus,actTextDisplay,person_id,last_name,first_name,DOB,locationname,enc_date,enc_date_sort,payer,Age,privacy_level)      
EXEC appdev_order_mgmt 1,@pi_practice_id,@pi_location_name,@pi_actClass,@pi_user_id      
  
/*Added Join for User Master Table, Fixed the cancelled by to include the first and last name of the user cancelling, Corrected the Time to show the time the correction was done */      
UPDATE o SET modified_by=@pi_user_id,modify_timestamp=GETDATE(),actStatus='cancelled', cancelled=1, cancelledReason='User Request Cancel',cancelledBy=um.first_name+' '+um.last_name,cancelledDate=CONVERT(VARCHAR(8),GETDATE(),112),cancelledTime=RIGHT(GETDATE(),8)      
FROM @temp t      
INNER JOIN order_ o WITH(NOLOCK) ON o.actClass=t.actClass AND o.actStatus=t.actStatus AND o.actTextDisplay=t.actTextDisplay AND o.person_id=t.person_id AND o.locationName=t.locationname      
INNER JOIN patient_encounter pe WITH(NOLOCK) ON o.encounterID=pe.enc_id AND CONVERT(VARCHAR(8),pe.enc_timestamp,112)=t.enc_date_sort      
INNER JOIN user_mstr um WITH(NOLOCK) ON @pi_user_id=um.user_id      
WHERE enc_date_sort <= @pi_cutoff_date       

--Capture the number of rows affected by the update statement.
SELECT @orders_canceled_count = @@ROWCOUNT        
----------------------------------------------------------------------------------------------------------------------------------      
/*Declare variables used for passing values to the dbmail call*/    
DECLARE @sub VARCHAR(200)    
SELECT @sub='Order Management Cancel Request ('+db_name()+')'    

DECLARE @body VARCHAR(MAX)    
SELECT @body=    
 'Practice:'+char(9)+(SELECT practice_name FROM practice WHERE practice_id=@pi_practice_id)+char(10)+    
 'Location:'+char(9)+@pi_location_name+char(10)+    
 'Order type:'+char(9)+@pi_actClass+char(10)+    
 'User:'+CHAR(9)+char(9)+(SELECT first_name+' '+last_name FROM user_mstr WHERE user_id=@pi_user_id)+CHAR(10)+    
 'Date cutoff:'+char(9)+CONVERT(VARCHAR(10),CONVERT(DATE,@pi_cutoff_date),101)+CHAR(10)+CHAR(10)+
 '('+CONVERT(VARCHAR(10),@orders_canceled_count)+' rows(s) affected)'

EXEC msdb.dbo.sp_send_dbmail     
 @profile_name='Services',    
 @recipients='emr@nextcare.com',    
 @body=@body,    
 @subject=@sub;