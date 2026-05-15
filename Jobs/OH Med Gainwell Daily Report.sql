USE [msdb]
GO

/****** Object:  Job [OH Med Gainwell Daily Report]    Script Date: 5/15/2026 1:20:14 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/15/2026 1:20:14 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'OH Med Gainwell Daily Report', 
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
/****** Object:  Step [Check if Job:RunPrimaryPlussJobsInSequence ran succesfully]    Script Date: 5/15/2026 1:20:14 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check if Job:RunPrimaryPlussJobsInSequence ran succesfully', 
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
  
    EXEC msdb.dbo.sp_stop_job N''OH Med Gainwell Daily Report'';
END
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Daily OHMedGainwellClaims SP]    Script Date: 5/15/2026 1:20:14 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Daily OHMedGainwellClaims SP', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Today DATE = CAST(GETDATE() AS DATE); --''2025-09-22'';    
DECLARE @StartDate DATE;    
DECLARE @EndDate DATE;    
    
IF DATEPART(WEEKDAY, @Today) = 2  -- 2 = Monday (assuming default DATEFIRST = 7 where Sunday=1, Monday=2)    
BEGIN    
    SET @StartDate = DATEADD(DAY, -3, @Today);  -- Friday    
    SET @EndDate   = DATEADD(DAY, -1, @Today);  -- Sunday    
END    
ELSE    
BEGIN    
    SET @StartDate = DATEADD(DAY, -1, @Today);  -- Yesterday    
    SET @EndDate   = DATEADD(DAY, -1, @Today);  -- Yesterday    
END;    
SELECT @StartDate AS StartDate, @EndDate AS EndDate;    
Exec Sp_DailyOHMedGainwellClaims @StartDate,@EndDate  ', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send the Report to Users]    Script Date: 5/15/2026 1:20:14 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send the Report to Users', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\OH MED Gainwell Report\GainwellReport\GainwellReport.dtsx\"" /SERVER PPLUSDW /Par EmailBCC;"\"saiabhilash@sightspectrum.com;priyankas@sightspectrum.com\"" /Par EmailTo;"\"mustardk@primaryplus.net;staffordm@primaryplus.net\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PrimaryPlus'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekdays Run', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20251030, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'492d8296-e680-4fbe-b4e7-63e34d3c645d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


