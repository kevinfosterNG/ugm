

/*request for template view of DTD times requires SP to call sql view*/  
--EXEC appdev_show_dtd_summary '1','NextCare Urgent Care','NextCare 43rd','20101029','20141029'  
CREATE PROCEDURE [dbo].[appdev_show_dtd_summary]  
 @design BIT,  
 @practice_name VARCHAR(40),  
 @location_name VARCHAR(40),  
 @enc_date_start VARCHAR(52),  
 @enc_date_stop VARCHAR(52)  
AS  
SET NOCOUNT ON;  
SET ANSI_WARNINGS OFF;  
  
DECLARE @enc_datetime_start DATETIME = CONVERT(DATETIME,REPLACE(REPLACE(@enc_date_start,'Yesterday',CONVERT(VARCHAR(8),GETDATE()-1,112)),'Today',CONVERT(VARCHAR(8),GETDATE(),112)))  
DECLARE @enc_datetime_stop DATETIME = CONVERT(DATETIME,REPLACE(REPLACE(@enc_date_stop,'Yesterday',CONVERT(VARCHAR(8),GETDATE()-1,112)),'Today',CONVERT(VARCHAR(8),GETDATE(),112)))+1  
    
SELECT ISNULL(CONVERT(VARCHAR(100),CONVERT(DATE, enc_timestamp)),'') AS enc_date, enc_nbr, person_nbr,   
ISNULL(CONVERT(VARCHAR(100),epm_checkin_datetime),'') AS epm_checkin_datetime,   
ISNULL(CONVERT(VARCHAR(100),epm_checkout_datetime),'') AS epm_checkout_datetime,   
ISNULL(CONVERT(VARCHAR(100),ready_triage_datetime),'') AS ready_triage_datetime,   
ISNULL(CONVERT(VARCHAR(100),ready_provider_datetime),'') AS ready_provider_datetime,   
ISNULL(CONVERT(VARCHAR(100),ready_for_checkout_datetime),'') AS ready_for_checkout_datetime,   
CONVERT(INT,dtd_min) AS dtd_min,   
CONVERT(INT,dtp_min) AS dtp_min,   
ISNULL(CONVERT(VARCHAR(100),time_interval), '') AS time_interval,   
ISNULL(CONVERT(VARCHAR(500),chief_complaints), '') AS chief_complaints,  
ISNULL(CONVERT(VARCHAR(100),description), '') AS rendering_provider,  
last_name+', '+first_name AS patient_name,  
person_id  
FROM appdev_dtd_metric   
WHERE practice_name=@practice_name   
AND location_name=@location_name   
AND enc_timestamp BETWEEN @enc_datetime_start AND @enc_datetime_stop  
ORDER BY 1,2