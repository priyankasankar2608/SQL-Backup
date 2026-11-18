USE [msdb]
GO

/****** Object:  Job [Monthly ESP Reports]    Script Date: 11/18/2026 1:54:32 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/18/2026 1:54:32 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monthly ESP Reports', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'LEWISCO\saiabhilash', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check if RunPrimaryPlussJobsInSequence succeeded for the day]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check if RunPrimaryPlussJobsInSequence succeeded for the day', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @job2_name NVARCHAR(128) = N''RunPrimaryPlussJobsInSequence'';

IF EXISTS (
    SELECT TOP 1 1
    FROM msdb.dbo.sysjobhistory h
    INNER JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id
    WHERE j.name = @job2_name
      AND h.step_id = 0
      AND h.run_status = 1
      AND CONVERT(DATE, msdb.dbo.agent_datetime(h.run_date, h.run_time)) = CAST(GETDATE() AS DATE)
    ORDER BY msdb.dbo.agent_datetime(h.run_date, h.run_time) DESC
)
BEGIN
    select 1 
END
ELSE
BEGIN
  
    EXEC msdb.dbo.sp_stop_job N''Monthly ESP Reports'';
END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Provider In House 340B stats]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Provider In House 340B stats', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @StartDate DATE, @EndDate DATE;

-- Get today''s date
DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- First day of previous month
SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);

-- Last day of previous month
SET @EndDate = EOMONTH(@Today, -1);

SELECT @StartDate AS StartDate, @EndDate AS EndDate;

EXEC Sp_ProviderInHouse340BStatsReport @StartDate, @EndDate; ', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Provider Inhouse 340b stats report to users]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Provider Inhouse 340b stats report to users', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\ESP 340B Report\ESP 340B Report\ProviderInHouse340BStats.dtsx\"" /SERVER PPLUSDW /Par EmailTo;"\"mustardk@primaryplus.net;BlevinsA@primaryplus.net\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PrimaryPlus'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Medicare D Repository Data]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Medicare D Repository Data', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @StartDate DATE, @EndDate DATE;

-- Get today''s date
DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- First day of previous month
SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);

-- Last day of previous month
SET @EndDate = EOMONTH(@Today, -1);

SELECT @StartDate AS StartDate, @EndDate AS EndDate;

EXEC Sp_Medicare340bESPClaimsReport @StartDate, @EndDate; ', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Medicare D Repository 340B Report to End Users]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Medicare D Repository 340B Report to End Users', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\ESP 340B Report\ESP 340B Report\Medicare Part D 340 claims.dtsx\"" /SERVER PPLUSDW /Par EmailTo;"\"mustardk@primaryplus.net\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PrimaryPlus'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Success Mail]    Script Date: 11/18/2026 1:54:32 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Success Mail', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Job Completion SentMailTask\JobDoneUpdate-MAIL\Package.dtsx\"" /SERVER PPLUSDW /Par "\"$Project::EmailSubject\"";"\"Provider 340B stats and Medicare D Monthly Report Jobs Succeeded\"" /Par "\"$Project::EmailTo\"";"\"saiabhilash@sightspectrum.com;jayashankarp@sightspectrum.com;ramyav@sightspectrum.com\"" /Par "\"$Project::JobName\"";"\"Provider 340B stats and Medicare D Monthly Report\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PrimaryPlus'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'1st day of Every month', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20261019, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'1b6b8ed1-b92b-4278-ae29-e55d0efc9524'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


