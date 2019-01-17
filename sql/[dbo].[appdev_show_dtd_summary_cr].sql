CREATE PROCEDURE [dbo].[appdev_show_dtd_summary_cr]  
 @pi_location_name VARCHAR(40)=null,          
 @enc_date_start VARCHAR(52)=null,    
 @enc_date_stop VARCHAR(52)=null    
AS      
DECLARE @pi_practice_name VARCHAR(50)    
SELECT @pi_practice_name=practice_name FROM practice pr   
INNER JOIN practice_location_xref x ON pr.practice_id=x.practice_id  
INNER JOIN location_mstr l ON x.location_id=l.location_id    
WHERE l.location_name=@pi_location_name    

EXEC appdev_show_dtd_summary '1', @pi_practice_name, @pi_location_name, @enc_date_start, @enc_date_stop 