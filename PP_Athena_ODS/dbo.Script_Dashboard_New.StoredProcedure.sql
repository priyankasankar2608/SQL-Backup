USE [PP_Athena_ODS]
GO

/****** Object:  StoredProcedure [dbo].[Script_Dashboard_New]    Script Date: 7/28/2026 1:40:55 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO










CREATE PROCEDURE [dbo].[Script_Dashboard_New]
as
/*****************************************************************************************************************************************************
Object		:     Clinical_Dashboard
Created By	:     NK
Created on	:     12/09/2021
Description	:	  Patient Clinical Dashboard

History:          MM/DD/YYYY  Modified User   Request Content
                  03/03/2022  NK              Initial creation

				  Added this comment by priyanka
*******************************************************************************************************************************************************/
begin

							
							IF OBJECT_ID('tempdb..#Liberty') IS NOT NULL
									DROP TABLE #Liberty
						
							

TRUNCATE TABLE PBIR_ScriptDashboard_New


select 
  P.PATIENTID as Athena_PatientID
 ,(P.Firstname+' '+P.lastname) as PatientName
 ,P.DateOfBirth as Date_Of_Birth
 ,(year(getdate())-year(P.DateOfBirth)) as Age
 ,CASE WHEN P.Gender='m' THEN'Male' WHEN P.Gender='F' THEN 'Female'  ELSE 'Others' END Patient_Gender
,P.GlobalId
,D.DrugId
,D.[Name] as DrugName
,D.Generic
,D.Is340B
,ST.ScriptNumber
,RI.ScriptNumber as RI_scriptnumber
,ST.Agency
,ST.ChargeCode
,(RI.Copay) as copay
,(RI.PrimaryIns+RI.SecondaryIns) as Total
,ST.QuantityDispensed as Drug_QTY
,ST.RequestedACQ
,ST.Cost
,ST.RequestedAWP
,ST.RequestedFee
,ST.RphInitials AS Modifiedby
,ST.DateDispensedSQL
,ST.RefillNumber
,st.Source_Indicator
,CASE WHEN st.ChargeCode in ('Y','N') THEN ST.Total  ELSE 0.00
 END AS ChargeCodeYN_Copay
into #Liberty
FROM PP_ODS..rxqDrug as D (NOLOCK)
INNER JOIN PP_ODS..rxqScriptBase as SB (NOLOCK) on
D.DrugId=SB.DrugKey and D.source_indicator=SB.Source_Indicator
INNER JOIN PP_ODS..rxqPatient as P (NOLOCK) on
P.PatientId=SB.PatientId and P.Source_Indicator=SB.Source_Indicator
INNER JOIN PP_ODS..rxqScriptTransaction AS ST (NOLOCK) on 
SB.ScriptNumber=ST.ScriptNumber and SB.Source_Indicator=ST.Source_Indicator
LEFT JOIN PP_ODS..RxInsurance as RI (nolock) on ST.scriptnumber=RI.ScriptNumber and st.RefillNumber=RI.RefillNumber 
and ST.Source_Indicator=RI.Source_Indicator
WHERE st.DateDispensedSQL >= DATEFROMPARTS(YEAR(GETDATE()) - 2, 1, 1) 



INSERT INTO PBIR_ScriptDashboard_New
SELECT 
Athena_PatientID
,PatientName
,Date_Of_Birth
,Age
,Patient_Gender
,GlobalId
,DrugId
,DrugName
,Generic
,Is340B
,ScriptNumber
,RI_scriptnumber
,Agency
,ChargeCode
,copay
,Total
,Drug_QTY
,RequestedACQ
,Cost
,RequestedAWP
,RequestedFee
,Modifiedby
,DateDispensedSQL
,RefillNumber
,Source_Indicator
,ChargeCodeYN_Copay
from #Liberty


end
GO


