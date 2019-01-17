CREATE VIEW [dbo].[appdev_active_clinics] AS
SELECT 
	pr.practice_id
	, pr.practice_name
	, l.location_id
	, location_name
	, replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(location_name,'Nextcare ',''), 'Dr J Express Care ',''), 'The Urgency Room ',''), 'Access Medical Center ',''), 'Primacare ',''), ' Clinic',''), 'CTUC ',''), 'Impact Urgent Care ',''), 'OhioHealth Urgent Care ',''), 'Providence Urgent Care ','') AS location_name_simple
	, ilm1.external_rec_id AS geocode
	, ilm2.external_rec_id AS epm_resource_id 
	, va.[LabCorp], va.[Quest QLS], va.[Sonora Quest], va.[CPL]
FROM location_mstr l
INNER JOIN practice_location_xref x ON l.location_id=x.location_id
INNER JOIN practice pr ON x.practice_id=pr.practice_id
LEFT OUTER JOIN intrf_location_mstr ilm1 ON l.location_id=ilm1.internal_rec_id AND ilm1.external_system_id=(SELECT external_system_id FROM external_system WHERE external_system_name='Google Geocode')
LEFT OUTER JOIN intrf_location_mstr ilm2 ON l.location_id=ilm2.internal_rec_id AND ilm2.external_system_id=(SELECT external_system_id FROM external_system WHERE external_system_name='NextGen Resource')
LEFT OUTER JOIN (
	SELECT location_id, [LabCorp],[Quest QLS],[Sonora Quest],[CPL]
	FROM (
		SELECT external_system_name, v.location_id, v.mapped_value 
		FROM external_system es
		INNER JOIN intrf_ext_mapped_value v ON v.ext_system_id=es.external_system_id
	) AS av PIVOT( MIN(mapped_value) FOR external_system_name IN ([LabCorp],[Quest QLS],[Sonora Quest],[CPL])) AS av_pivoted
) va ON va.location_id=l.location_id
WHERE location_schedulable_ind='Y'
AND l.delete_ind='N'
AND pr.delete_ind='N'
--HARD EXCLUDE 
AND pr.practice_id NOT IN ('0004')
AND l.location_name NOT IN ('Lumberton Clinic','NextCare Mallard')