

CREATE VIEW [dbo].[appdev_dtd_metric] AS
SELECT pr.practice_name, l.location_name, 
p.person_nbr, p.first_name, p.last_name, CONVERT(Date, p.date_of_birth,112) as date_of_birth, 
pe.person_id, pe.enc_id, pe.enc_nbr, 
pe.enc_timestamp, 
--dbo.GetLocalDatetime(pe.enc_timestamp, pe.enc_timestamp_tz) AS enc_timestamp,
apt.begintime, e.event, pm.description,
ISNULL(RTRIM(im.chiefcomplaint1),'')+ISNULL(', '+RTRIM(im.chiefcomplaint2),'')+ISNULL(', '+RTRIM(im.chiefcomplaint3),'')+ISNULL(', '+RTRIM(im.chiefcomplaint4),'')+ISNULL(', '+RTRIM(im.chiefcomplaint5),'')+ISNULL(', '+RTRIM(im.chiefcomplaint6),'') AS chief_complaints,
dbo.GetLocalDatetime(pe.checkin_datetime, pe.checkin_datetime_tz) AS epm_checkin_datetime,
[Ready for Triage] AS ready_triage_datetime, 
[Triage Template] AS triage_template_datetime,
[With Back Office] AS with_triage_datetime, 
[Ready for Provider] AS ready_provider_datetime, 
[Provider Template] AS provider_template_datetime,
[With Provider] AS with_provider_datetime,
[Ready for Checkout] AS ready_for_checkout_datetime,
dbo.GetLocalDatetime(pe.checkout_datetime, pe.checkout_datetime_tz) AS epm_checkout_datetime,
DATEDIFF(mi, dbo.GetLocalDatetime(pe.checkin_datetime, pe.checkin_datetime_tz), [Ready for Triage]) AS 'ctw_min',
DATEDIFF(mi, [Ready for Triage], [Triage Template]) AS 'wtt_min',
DATEDIFF(mi, [Triage Template], [Ready for Provider]) AS 'withback_min',
DATEDIFF(mi, [Ready for Provider], [Provider Template]) AS 'waitprovider_min',
DATEDIFF(mi, [Provider Template], [Ready for Checkout]) AS 'withprovider_min',
DATEDIFF(mi, [Ready for Checkout], dbo.GetLocalDatetime(pe.checkout_datetime, pe.checkout_datetime_tz)) AS 'ptc_min',
DATEDIFF(mi, dbo.GetLocalDatetime(pe.checkin_datetime, pe.checkin_datetime_tz), [Ready for Provider]) AS 'dtp_min',
DATEDIFF(mi, [Provider Template], [Ready for Checkout]) AS 'provider_min',
DATEDIFF(mi, [Ready for Checkout], dbo.GetLocalDatetime(pe.checkout_datetime, pe.checkout_datetime_tz)) AS 'ptd_min',
DATEDIFF(mi, dbo.GetLocalDatetime(pe.checkin_datetime, pe.checkin_datetime_tz), [Ready for Checkout]) AS 'dtd_min',
DATEDIFF(mi, [Ready for Triage], [Ready for Checkout]) AS 'ehr_dtd',
	CASE 
		WHEN /*CONVERT(TIME,[Ready for Checkout])>='12:00AM' AND*/ CONVERT(TIME,[Ready for Checkout])<'8:00AM'	THEN '"Before 8"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='8:00AM'  AND CONVERT(TIME,[Ready for Checkout])<'10:00AM'	THEN '"8-10"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='10:00AM' AND CONVERT(TIME,[Ready for Checkout])<'12:00PM'	THEN '"10-Noon"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='12:00PM' AND CONVERT(TIME,[Ready for Checkout])<'2:00PM'	THEN '"Noon-2"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='2:00PM'  AND CONVERT(TIME,[Ready for Checkout])<'4:00PM'	THEN '"2-4"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='4:00PM'  AND CONVERT(TIME,[Ready for Checkout])<'6:00PM'	THEN '"4-6"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='6:00PM'  AND CONVERT(TIME,[Ready for Checkout])<'8:00PM'	THEN '"6-8"'
		WHEN CONVERT(TIME,[Ready for Checkout])>='8:00PM' /*AND CONVERT(TIME,[Ready for Checkout])<='12:00AM'*/	THEN '"8-Midnight"'
	--	ELSE 'Afterhours'
	END AS 'time_interval'
FROM patient_encounter pe
INNER JOIN appointments apt ON pe.enc_id=apt.enc_id
INNER JOIN events e ON apt.event_id=e.event_id
INNER JOIN practice pr ON pe.practice_id=pr.practice_id
INNER JOIN location_mstr l ON pe.location_id=l.location_id
INNER JOIN person p ON pe.person_id=p.person_id
INNER JOIN provider_mstr pm ON pe.rendering_provider_id=pm.provider_id
LEFT OUTER JOIN master_im_ im ON pe.enc_id=im.enc_id
INNER JOIN --Pivot to aggregate multiple records into a single row 
(
	SELECT 
		enc_id, 
		CASE txt_status 
			WHEN 'Ready for Checkout' THEN MAX(dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz))
			WHEN 'needs follow up appt scheduled' THEN MAX(dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz))
			ELSE MIN(dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz))
		END as status_at,
		REPLACE(REPLACE(REPLACE(REPLACE(txt_status,'--PE',''),'--URGENT',''),'-PRIORITY',''),'needs follow up appt scheduled','ready for checkout') AS txt_status
	FROM pat_apt_status_hx_
	GROUP BY enc_id, txt_status--REPLACE(txt_status,'needs follow up appt scheduled','ready for checkout')
	UNION
	SELECT enc_id, dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz), 'Triage Template' 
	FROM ng_ov_intake_
	UNION 
	SELECT enc_id, dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz), 'Provider Template'
	FROM ng_ov_soap_
	UNION 
	SELECT enc_id, dbo.GetLocalDatetime(create_timestamp, create_timestamp_tz), 'Provider Template'
	FROM ng_ov_summary_
) AS patientTracking_min
PIVOT (MIN(status_at) FOR txt_status IN ([Ready for Triage],[With Back Office], [Ready for Provider], [With Provider],[Ready for Checkout],[Triage Template],[Provider Template] )) AS piv ON pe.enc_id=piv.enc_id
WHERE apt.delete_ind = 'N'
AND apt.cancel_ind = 'N'
AND apt.appt_type = 'U';