USE [msdb]
GO

/****** Object:  Job [ESP 340 B Report]    Script Date: 5/15/2026 1:17:31 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/15/2026 1:17:31 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ESP 340 B Report', 
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
/****** Object:  Step [Load ESP Weekly Data]    Script Date: 5/15/2026 1:17:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load ESP Weekly Data', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @StartDate DATE, @EndDate   DATE;

-- Get today
DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- Find current week''s Monday
DECLARE @CurrentWeekMonday DATE =
    DATEADD(DAY, -((DATEPART(WEEKDAY, @Today) + 5) % 7), @Today);

-- Previous week''s Monday
SET @StartDate = DATEADD(DAY, -7, @CurrentWeekMonday);
-- Previous week''s Sunday
SET @EndDate = DATEADD(DAY, 6, @StartDate);

SELECT @StartDate AS StartDate, @EndDate AS EndDate;

Exec Sp_340B_ESPMFPReport  @StartDate,@EndDate', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Lilly 340B Data]    Script Date: 5/15/2026 1:17:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Lilly 340B Data', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @StartDate DATE, @EndDate   DATE;

-- Get today
DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- Find current week''s Monday
DECLARE @CurrentWeekMonday DATE =
    DATEADD(DAY, -((DATEPART(WEEKDAY, @Today) + 5) % 7), @Today);

-- Previous week''s Monday
SET @StartDate = DATEADD(DAY, -7, @CurrentWeekMonday);
-- Previous week''s Sunday
SET @EndDate = DATEADD(DAY, 6, @StartDate);

SELECT @StartDate AS StartDate, @EndDate AS EndDate;

Exec Sp_Lilly340bESPClaimsReport  @StartDate,@EndDate', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Novo Nord 340B data]    Script Date: 5/15/2026 1:17:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Novo Nord 340B data', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @StartDate DATE, @EndDate   DATE;

-- Get today
DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- Find current week''s Monday
DECLARE @CurrentWeekMonday DATE =
    DATEADD(DAY, -((DATEPART(WEEKDAY, @Today) + 5) % 7), @Today);

-- Previous week''s Monday
SET @StartDate = DATEADD(DAY, -7, @CurrentWeekMonday);
-- Previous week''s Sunday
SET @EndDate = DATEADD(DAY, 6, @StartDate);

SELECT @StartDate AS StartDate, @EndDate AS EndDate;

Exec Sp_NovoNord340bESPClaimsReport  @StartDate,@EndDate', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Astra Zeneca 340 B]    Script Date: 5/15/2026 1:17:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Astra Zeneca 340 B', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @StartDate DATE, @EndDate   DATE;      
      
-- Get today      
DECLARE @Today DATE = CAST(GETDATE() AS DATE);      
      
-- Find current week''s Monday      
DECLARE @CurrentWeekMonday DATE =      
    DATEADD(DAY, -((DATEPART(WEEKDAY, @Today) + 5) % 7), @Today);      
      
-- Previous week''s Monday      
SET @StartDate = DATEADD(DAY, -7, @CurrentWeekMonday);      
-- Previous week''s Sunday      
SET @EndDate = DATEADD(DAY, 6, @StartDate);      
      
SELECT @StartDate AS StartDate, @EndDate AS EndDate;      
      
Exec Sp_AstraZeneca340bESPClaimsReport  @StartDate,@EndDate      
      
', 
		@database_name=N'PP_ODS', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Mail to End Users]    Script Date: 5/15/2026 1:17:31 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Mail to End Users', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\ESP 340B Report\ESP 340B Report\340B ESP Report.dtsx\"" /SERVER PPLUSDW /Par EmailBCC;"\"saiabhilash@sightspectrum.com;priyankas@sightspectrum.com\"" /Par EmailTo;"\"mustardk@primaryplus.net;BlevinsA@primaryplus.net\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'PrimaryPlus'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly 7.30 Am', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20260303, 
		@active_end_date=99991231, 
		@active_start_time=73000, 
		@active_end_time=235959, 
		@schedule_uid=N'a019a3ea-f4a9-4a35-8589-6d5288d50925'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


