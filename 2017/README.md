# Client Innovation 2017

## Summary
Part of NextCare Holding's submission for the Client Innovation Contest session at the NextGen User Group Meeting 2017.  The template, ngkbm_dtd_view, provides a location-centric breakdown of door to door times.  

### Visit Status
The underlying view [dbo].[appdev_dtd_metric] provides several metrics calculated.  The template provides access to the door to door (dtd_min) and door to provider (dtp_min) time and a calculation of the number of minutes between the two timestamps. 
 + DTD = EPM Check-in to EHR "Ready for Checkout" or "needs follow up appt scheduled" status
 + DTP = EPM Check-in to EHR "Ready for Provider"

![NextGen Template](https://github.com/kevinfosterNG/ugm/blob/master/2017/dtd_preview.png)

### Installation

#### Template(s)
Import templates and images from this folder. 

#### Reports
Copy the dtd_template.rpt file to the nextgenroot custom folder defined in universal preferences.

#### SQL
Have a database administrator / IT staff with access to the SQL create the files in the /sql/ folder. 
