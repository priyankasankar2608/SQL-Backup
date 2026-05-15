USE [msdb]
GO

/****** Object:  Job [Snowflake Password change Reminder]    Script Date: 5/15/2026 1:28:00 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/15/2026 1:28:00 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Snowflake Password change Reminder', 
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
/****** Object:  Step [Check whether password date expired]    Script Date: 5/15/2026 1:28:00 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check whether password date expired', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @LastChangedDate DATE, @NextDueDate DATE, @ReminderDate DATE;

SELECT @LastChangedDate = LastChangedDate
FROM dbo.SnowflakePwdChangeTracker;

-- Next due date = LastChangedDate + 2 months
SET @NextDueDate = DATEADD(MONTH, 2, @LastChangedDate);

-- Adjust if weekend (Saturday or Sunday → shift to Friday)
IF DATENAME(WEEKDAY, @NextDueDate) = ''Saturday''
    SET @ReminderDate = DATEADD(DAY, -1, @NextDueDate);
ELSE IF DATENAME(WEEKDAY, @NextDueDate) = ''Sunday''
    SET @ReminderDate = DATEADD(DAY, -2, @NextDueDate);
ELSE
    SET @ReminderDate = @NextDueDate;

-- If today = reminder date → fail and run reminder
-- Else exit with success and no action needed
---IF CAST(GETDATE() AS DATE) = ''2025-08-19''
IF CAST(GETDATE() AS DATE) =  @ReminderDate
    RAISERROR(''Run Reminder package'', 16, 1) WITH NOWAIT;
ELSE
    RAISERROR(''Skip Reminder  package'', 10, 1) WITH NOWAIT;', 
		@database_name=N'PP_Athena_Landing', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Reminder Mail]    Script Date: 5/15/2026 1:28:00 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Reminder Mail', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/ISSERVER "\"\SSISDB\Job Completion SentMailTask\JobDoneUpdate-MAIL\Package.dtsx\"" /SERVER PPLUSDW /Par "\"$Project::EmailSubject\"";"\"Snowflake Password Change Reminder Job Succeeded\"" /Par "\"$Project::EmailTo\"";"\"saiabhilash@sightspectrum.com;mathiyarasu@sightspectrum.com;jayashankarp@sightspectrum.com;ramyav@sightspectrum.com\"" /Par "\"$Project::JobName\"";"\"Snowflake Password Change Reminder\"" /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily Check', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20251111, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'8728da82-eee9-4720-926f-b807faa0664c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


