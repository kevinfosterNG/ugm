

CREATE PROCEDURE [dbo].[appdev_order_mgmt]
 @DESIGN BIT,
 @pi_practice_id CHAR(4)=null,
 @pi_location_name CHAR(40)=null,
 @pi_actClass CHAR(10)=null,
 @pi_user_id CHAR(5)=null
AS 
DECLARE @enterprise_id CHAR(5)
SELECT @enterprise_id='00001'
-- =============================================
-- Author: Kevin Foster
-- Create date: 07/26/2012
-- Description: Stored procedure to view all
-- orders for execution outside of the office.
-- =============================================
-- Example: EXEC appdev_order_mgmt 1,'0001','NextCare McKellips','A','2600'
--Create a custom index for template performance
IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = 'inx_order_locationName')
 CREATE INDEX [inx_order_locationName] ON [dbo].[order_] ([enterprise_id],[practice_id],[locationName])

--Define how far back to look in the order table
DECLARE @cutoff DATETIME = '2012-07-13'

--Define max number of order results to return
DECLARE @row_limit INT = 5000

--Define which actClass values correspond to the radio button filter
DECLARE @actClassList TABLE (value VARCHAR(15))
IF @pi_actClass = 'L' 
 INSERT INTO @actClassList (value) VALUES('Lab'),('Lab Office'),('WETMOUNT')
IF @pi_actClass = 'E' 
 INSERT INTO @actClassList (value) VALUES('DME'), ('MEDSUPPLY')
IF @pi_actClass = 'D' 
 INSERT INTO @actClassList (value) VALUES('PUL'),('DIAGSTUDY'),('DIAGIMG'),('XRAY'),('CARD'),('EKG'),('GI'),('DIAG'),('ENT'),('GYN')
IF @pi_actClass = 'O' 
 INSERT INTO @actClassList (value) VALUES('OTHER'),('OB'),('GYN'),('PHYS'),('PT'),('TRANSPORT')
IF @pi_actClass IN ('R', 'W', 'RD')
 INSERT INTO @actClassList (value) VALUES('REFR'),('PT'),('REFR_INIT')
IF @pi_actClass = 'C' 
 INSERT INTO @actClassList (value) VALUES('CCB')
IF @pi_actClass IN ('A','H')
 INSERT INTO @actClassList (value) VALUES('CCB'),('OTHER'),('OB'),('GYN'),('OV'),('PHYS'),('PT'),('TRANSPORT'),('Lab'),('Lab Office')
 ,('DME'),('MEDSUPPLY'),('PUL'),('DIAGSTUDY'),('DIAGIMG'),('XRAY'),('CARD'),('EKG'),('GI'),('DIAG'),('ENT'),('GYN'),('REFR'),('REFR_INIT'),('PT')
IF @pi_actClass = 'B' 
 INSERT INTO @actClassList (value) VALUES('CBO') 
IF @pi_actClass = 'DOT' 
 INSERT INTO @actClassList (value) VALUES('DOT') 
 
--Define the actStatus values to filter out of the order result
DECLARE @actStatusList TABLE (value VARCHAR(10))
INSERT INTO @actStatusList (value) VALUES('complete'),('completed'),('cancel'),('canceled'),('cancelled'),('delete'),('deleted')

DECLARE @referToSpecialtyList TABLE (value VARCHAR(200))
INSERT INTO @referToSpecialtyList (value) VALUES ('Diagnostic Radiology'),('Radiology'),('Roentgenology,Radiology, DO'),('Outpatient Lab')

--Find current user's privacy level, default to zero 
DECLARE @user_privacy_level INT = (SELECT ISNULL(privacy_level,0) FROM user_mstr WHERE user_id=@pi_user_id)

--Determine if current user is part of the show all group
DECLARE @show_all_locations CHAR(1) 
 IF EXISTS (SELECT view_all FROM order_management_prac_conf_ WHERE (view_all='Y' AND practice_id=@pi_practice_id AND user_id=@pi_user_id)) OR @pi_actClass IN ('B','DOT')
	SELECT @show_all_locations = 'Y'
ELSE
	SELECT @show_all_locations = 'N'

----standardized order_ query that populates the datagrid
IF @pi_actClass IN ('L','E','D','O','R','C','A','W','H','B','DOT','RD')
 SELECT TOP (@row_limit) UPPER(actClass) AS actClass
	 , actStatus
	 , actTextDisplay
	 , CASE WHEN @user_privacy_level < pt.privacy_level THEN '00000000-0000-0000-0000-000000000000' ELSE p.person_id END AS person_id
	 , CASE WHEN @user_privacy_level < pt.privacy_level THEN '**Restricted**' ELSE p.last_name END AS last_name 
	 , CASE WHEN @user_privacy_level < pt.privacy_level THEN '**Restricted**' ELSE p.first_name END AS first_name 
	 , CONVERT(VARCHAR(10),CONVERT(datetime,p.date_of_birth),101) AS DOB 
	 , ISNULL(o.locationname,'') AS location
	 , CONVERT(VARCHAR(10),CONVERT(datetime,o.encounterDate),101) AS enc_date
	 , o.encounterDate AS enc_date_sort 
	 , ISNULL(pm.payer_name,'Self pay') AS payer
	 , CASE
	 WHEN DATEDIFF(hh,CONVERT(DATE,date_of_birth),CONVERT(DATE,GETDATE()))/8766>0 
	 THEN CONVERT(VARCHAR(50),DATEDIFF(hh,CONVERT(DATE,date_of_birth),CONVERT(DATE,GETDATE()))/8766)+' y'
	 ELSE CONVERT(VARCHAR(50),DATEDIFF(m,CONVERT(datetime,p.date_of_birth),GETDATE()))+' m'
	 END AS Age 
	 , pt.privacy_level 
	 FROM patient_encounter pe WITH(NOLOCK)
	 INNER JOIN order_ o WITH(NOLOCK) ON pe.enc_id=o.encounterID AND pe.practice_id=o.practice_id AND pe.enterprise_id=o.enterprise_id AND pe.person_id=o.person_id
	 AND o.actClass IN (SELECT value FROM @actClassList)
	 INNER JOIN person p WITH(NOLOCK) ON pe.person_id=p.person_id
	 INNER JOIN patient pt WITH(NOLOCK) ON pe.person_id=pt.person_id AND pe.practice_id=pt.practice_id
	 LEFT OUTER JOIN master_im_ mim WITH(NOLOCK) ON pe.enc_id=mim.enc_id 
	 LEFT OUTER JOIN encounter_payer ep WITH(NOLOCK) ON pe.enc_id=ep.enc_id and ep.cob=1 
	 LEFT OUTER JOIN payer_mstr pm WITH(NOLOCK) ON ep.payer_id=pm.payer_id 
	 LEFT OUTER JOIN mstr_lists ml WITH(NOLOCK) ON pm.financial_class=ml.mstr_list_item_id AND mstr_list_type = 'fin_class'
	 WHERE o.enterprise_id=@enterprise_id
	 AND o.practice_id=@pi_practice_id
	 AND o.actStatus NOT IN (SELECT value FROM @actStatusList)
	 --view all for particular @pi_user_id
	 AND (
	 o.locationName=@pi_location_name 
	 OR @show_all_locations='Y'
	)
	 --AND ISNULL(o.actMood,'')<>'RMD'
	 AND pe.enc_timestamp>@cutoff
	 AND (
	 (@pi_actClass='W' AND ISNULL(mstr_list_item_desc,'') = 'Workers Compensation') OR 
	 (@pi_actClass='R' AND ISNULL(mstr_list_item_desc,'') != 'Workers Compensation' AND o.referToSpecialty NOT IN (SELECT value FROM @referToSpecialtyList)) OR
	 (@pi_actClass='RD' AND ISNULL(mstr_list_item_desc,'') != 'Workers Compensation' AND o.referToSpecialty IN (SELECT value FROM @referToSpecialtyList)) OR
	 (@pi_actClass NOT IN ('R','W','RD'))
	 ) 
	 AND ( 
	 (@pi_actClass='H' AND mim.txt_template_set='Family Practice') --mim.visit_type='Preventive Medicine' 
	 OR 
	 (@pi_actClass!='H' AND ISNULL(mim.txt_template_set,'')!='Family Practice') 
	 OR 
	 (@pi_actClass='C') 
	 ) 
	ORDER BY enc_date_sort, last_name, first_name, date_of_birth 
	OPTION (OPTIMIZE FOR (@show_all_locations = 'N'))
--used to prepopulate the data grid with no info, as well as used for template editor building
ELSE 
 SELECT TOP 1 
 CONVERT(VARCHAR(50),'') AS actClass
 , CONVERT(VARCHAR(50),'') AS actStatus
 , CONVERT(VARCHAR(50),'') AS actTextDisplay
 , CONVERT(VARCHAR(50),'') AS person_id
 , CONVERT(VARCHAR(50),'') AS last_name
 , CONVERT(VARCHAR(50),'') AS first_name
 , CONVERT(VARCHAR(50),'') AS DOB 
 , CONVERT(VARCHAR(50),'') AS location 
 , CONVERT(VARCHAR(50),'') AS enc_date 
 , CONVERT(VARCHAR(50),'') AS enc_date_sort 
 , CONVERT(VARCHAR(50),'') AS payer
 , CONVERT(VARCHAR(50),'') AS Age
 , CONVERT(VARCHAR(50),'') AS privacy_level

