**************************************************************************************************
PROGRAM: SQL TSA Claims Case Study Solution
CREATED BY: Peter Styliadis
DATE CREATED: 5/2/2019
PROGRAM PURPOSE: Solution code to the SQL Essentials course case study. Goal of the case study is for learners
                 to follow the directions and access/explore/prepare data using SQL. Once complete, they
                 will run the code given to them from the analyze stage to create a static dashboard. The code in the 
                 analyze stage is to show them some visuals using SAS to confirm the answers. They are out of scope 
                 of the SQL course. Comments are throughout the program. The code is broken up into the SAS Programming 
                 Process:
		            - Access -> Explore -> Prepare -> Analyze -> Export

***************************************************************************************;
* THE FOLLOWING STEP BY STEP SOLUTION CORRESPONDS TO THE CASE STUDY - GUIDED VERSION  *; 
***************************************************************************************;

*******************;
*ACCESS DATA      *;
*******************;
****************************************************************************************;
* All tables are located in the SQ library for this case study. The code below will set*; 
* the path to the data and the library for you. Data must reside in the home           *;
* directory -> ESQ1M6. This will work for SAS OnDemand for Academics. Path will        *; 
* need to be changed if using another SAS interface.                                   *;           
****************************************************************************************;
%let path=~/ESQ1M6;
libname sq "&path/data";



*******************;
*EXPLORE DATA     *;
*******************;
/*2. Preview the first 10 rows and descriptor portion of the following tables*/
*********;
* NOTES *; 
******************************************************************************************************************;
* a. Year is character in the enplanement table, numeric in the boarding table.                                  *;
* b. The number of passengers is called enplanement in the enplanement table, and boarding in the boarding table *;
******************************************************************************************************************;
proc sql outobs=10;
title "Table: CLAIMSRAW";
describe table sq.claimsraw;
select * 
    from sq.claimsraw;
title "Table: ENPLANEMENT2017";
describe table sq.enplanement2017;
select * 
    from sq.enplanement2017;
title "Table: BOARDING2013_2016";
describe table sq.boarding2013_2016;
select * 
    from sq.boarding2013_2016;
title;
quit;


/*3. Count the number of nonmissing values in the following:*/
/* TotalRow  TotalAirportCode  TotalClaimSite TotalDisposition  TotalClaimType TotalDateReceived  TotalIncidentDate
   42,528    42,179            42,295         33,469            42,303         42,528             42,528             */
title "Total Nonmissing Rows";
proc sql;
select count(*) as TotalRow format=comma16.,
       count(Airport_Code) as TotalAirportCode format=comma16.,
       count(Claim_Site) as TotalClaimSite format=comma16.,
       count(Disposition) as TotalDisposition format=comma16.,
       count(Claim_Type) as TotalClaimType format=comma16.,
       count(Date_Received) as TotalDateReceived format=comma16.,
	  count(Incident_Date) as TotalIncidentDate format=comma16.
    from sq.claimsraw;
quit;
title;


/*4. View percentage of missing values in the columns*/
/*Create a macro variable with the total number of rows - 42,528*/
proc sql noprint;
select count(*)
    into :TotalRows trimmed
    from sq.claimsraw;
quit;
%put &=TotalRows;

/*PctAirportCode PctClaimSite PctDisposition PctClaimType PctDateReceived PctIncidentDate 
  0.82%          0.55%        21.3%          0.53%        0.00%           0.00%*/
title "Percentage of Missing Rows";
proc sql;
select 1-(count(Airport_Code)/&TotalRows) as PctAirportCode 
                                             format=percent7.2, 
       1-(count(Claim_Site)/&TotalRows) as PctClaimSite 
                                             format=percent7.2,
       1-(count(Disposition)/&TotalRows) as PctDisposition 
                                            format=percent7.2,
       1-(count(Claim_Type)/&TotalRows) as PctClaimType 
                                           format=percent7.2,
       1-(count(Date_Received)/&TotalRows) as PctDateReceived 
                                              format=percent7.2,
       1-(count(Incident_Date)/&TotalRows) as PctIncidentDate 
                                              format=percent7.2
    from sq.claimsraw;
quit;
title;


/*5. View the distinct values and frequencies*/
title "Column Distinct Values";
proc sql number;
/*Claim_Site*/
title2 "Column: Claim_Site";
select distinct Claim_Site
    from sq.claimsraw
    order by Claim_Site;
/*Disposition*/
title2 "Column: Disposition";
select distinct Disposition
    from sq.claimsraw
    order by Disposition;
/*Claim_Type*/
title2 "Column: Claim_Type"; 
select distinct Claim_Type
    from sq.claimsraw
    order by Claim_Type;
/*Date_Received*/
title2 "Column: Date_Received";
select distinct put(Date_Received, year4.) as Date_Received
    from sq.claimsraw
    order by Date_Received;
/*Incident_Date*/
title2 "Column: Incident_Date";
select distinct put(Incident_Date, year4.) as Incident_Date
    from sq.claimsraw
    order by Incident_Date;
quit;
title;


/*6. Count the number of rows where Incident_Date occurs AFTER Date_Recieved - 65 rows*/;
title "Number of Claims where Incident Date Occurred After the Date Received";
proc sql;
select count(*) label="Date Needs Review"
    from sq.claimsraw
    where Incident_Date > Date_Received;
quit;
title;


/*7. Run a query to view all rows and columns where Incident_Date occurs AFTER Date_Received. 
What assumption can you make about the dates in your results?*/
proc sql;
select Claim_Number, Date_Received, Incident_Date 
    from sq.claimsraw
    where Incident_Date > Date_Received;
quit;


*******************;
*PREPARE DATA     *;
*******************;
/*8. Create a new table named Claims_NoDup that removes entirely duplicated rows. 
     A duplicate claim exists if every value is duplicated.*/
/*
NOTE: The data set work.CLAIMS_NODUP has 42524 observations and 13 variables.
*/
proc sql;
create table Claims_NoDup as 
select distinct * 
    from sq.claimsraw;
quit;



/*9. Prepare Data*/
proc sql;
create table sq.Claims_Cleaned as
select 
/*a. Select the Claim_Number, Incident Date columns.*/
       Claim_Number label="Claim Number",
       Incident_Date format=date9. label="Incident Date",
/*b. Fix the 65 date issues you identified earlier by replacing the year 2017 with 2018 in the Date_Received column.*/
	   case 
		    when Incident_Date > Date_Received then intnx("year",Date_Received,1,"sameday")
			else Date_Received
	   end as Date_Received label="Date Received" format=date9.,
/*c. Select the Airport_Name column*/
	   Airport_Name label="Airport Name",
/*d. Replace missing values in the Airport_Code column with the value Unknown.*/
       case 
            when Airport_Code is null then "Unknown"
	        else Airport_Code
	   end as Airport_Code label="Airport Code",
/*e1. Clean the Claim_Type column.*/
       case 
           when Claim_Type is null then "Unknown"
		   else scan(Claim_Type,1,"/","r") /*If I find a '/', scan and retrieve the first word*/
       end as Claim_Type label="Claim Type",
/*e2. Clean the Claim_Site column.*/
       case 
           when Claim_Site is null then "Unknown" 
           else Claim_Site 
       end as Claim_Site label="Claim Site",
/*e3. Clean the Disposition column.*/
       case 
           when Disposition is null then "Unknown"
           when Disposition="Closed: Canceled" then "Closed:Canceled"
           when Disposition="losed: Contractor Claim" then "Closed:Contractor Claim" 
           else Disposition
       end as Disposition,
/*f. Select the Close_Amount column.*/
       Close_Amount format=Dollar20.2 label="Close Amount", 
/*g. Select the State column and upper case all values.*/
       upcase(State) as State,
/*h. Select the StateName, County and City column. Proper case all values.*/
	   propcase(StateName) as StateName label="State Name",
       propcase(County) as County,
       propcase(City) as City
	from Claims_NoDup
/*i. Remove all rows where year of Incident_Date occurs after 2017. */
    where year(Incident_Date) <= 2017
/*j. Order the results by Airport_Code, Incident_Date.*/
    order by Airport_Code, Incident_Date;
quit;


/***************Validate the Prepared Data***************/
proc sql;
select count(*) as TotalRows
    from sq.claims_cleaned;
quit;

title "SQL Distinct Values Validation";
proc sql;
/*Claim_Site*/
title2 "Column: Claim_Site";
select distinct Claim_Site
    from sq.claims_cleaned
    order by Claim_Site;
/*Disposition*/
title2 "Column: Disposition";
select distinct Disposition
    from sq.claims_cleaned
    order by Disposition;
/*Claim_Type*/
title2 "Column: Claim_Type"; 
select distinct Claim_Type
    from sq.claims_cleaned
    order by Claim_Type;
/*Date_Received*/
title2 "Column: Date_Received";
select distinct put(Date_Received, year4.) as Date_Received
    from sq.claims_cleaned
    order by Date_Received;
/*Incident_Date*/
title2 "Column: Incident_Date";
select distinct put(Incident_Date, year4.) as Incident_Date
    from sq.claims_cleaned
    order by Incident_Date;
quit;
title;
/***************End Validation****************************************/




/*10. Use the sq.Claims_Cleaned table to create a view named TotalClaims to count the number of claims for each Airport_Code and Year.*/
/*NOTE: View work.TOTALCLAIMS created, with 1491 rows and 5 columns.*/
proc sql;
create view TotalClaims as
select Airport_Code, Airport_Name, City, State, 
       year(Incident_date) as Year, 
       count(*) as TotalClaims
    from sq.claims_cleaned
    group by Airport_Code, Airport_Name, City, State, calculated Year
    order by Airport_Code, Year;
quit;


/*11. Create a view name TotalEnplanements by using the OUTER UNION set operator to concatenate the enplanement2017 and boarding2013_2016 tables.*/
proc sql;
create view TotalEnplanements as
select LocID, Enplanement, input(Year,4.) as Year
    from sq.enplanement2017 
    outer union corr
select LocID, Boarding as Enplanement, Year
    from sq.boarding2013_2016
    order by Year, LocID;
quit;

/*12. Create a table named sq.ClaimsByAirport by joining the TotalClaims and TotalEnplanements views.*/
proc sql;
create table sq.ClaimsByAirport as
select t.Airport_Code,t.Airport_Name, t.City, t.State, 
       t.Year, t.TotalClaims, e.Enplanement, 
       TotalClaims/Enplanement as PctClaims format=percent10.4
    from TotalClaims as t inner join
	     TotalEnplanements as e
	on t.Airport_Code = e.LocID and 
       t.Year = e.Year
	order by Airport_Code, Year;
quit;



**************************************************************************;
*  ALTERNATIVE: SOLVE STEPS 10-12 USING ONE QUERY WITH IN-LINE VIEWS     *; 
**************************************************************************;
/*
proc sql;
create table sq.ClaimsByAirport as
select t.Airport_Code,t.Airport_Name, t.City, t.State, 
       t.Year, t.TotalClaims, e.Enplanement, 
       TotalClaims/Enplanement as PctClaims format=percent10.4
    from (select Airport_Code, Airport_Name, City, State, 
                 year(Incident_date) as Year, 
                 count(*) as TotalClaims
              from sq.claims_cleaned
              group by Airport_Code, Airport_Name, City, State, calculated Year) as t inner join
	     (select LocID, Enplanement, input(Year,4.) as Year
              from sq.enplanement2017 
              outer union corr
          select LocID, Boarding as Enplanement, Year
              from sq.boarding2013_2016) as e
	on t.Airport_Code = e.LocID and 
       t.Year = e.Year
	order by Airport_Code, Year;
quit;
*/
**************************************************************************;


*******************;
*EXPORT & ANALYSIS*;
*******************;
**************************************************************************************************;
* Run the following when complete. The statement runs the AnalysisProgram.sas to create the      *;
* FinalResults.html in the location of the caseStudyFilesPath macro variable set at the top of   *;
* this program.                                                                                  *;
**************************************************************************************************;
****************************************************************************************;
* Specify the location of the AnalysisProgram.sas program. This is also the location   *;
* for the FinalReport.html report output. The case study files must reside in the home *;
* directory -> ESQ1M6 -> caseStudy. This will work for SAS OnDemand for Academics. Path*; 
* will need to be changed if using another SAS interface.                              *;           
****************************************************************************************;
%include "~/ESQ1M6/caseStudy/AnalysisProgram.sas";