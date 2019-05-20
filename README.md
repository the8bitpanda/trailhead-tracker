# post deployment
### New Group: Trailblazers
### Populate custom settings values
### Assign Permissions
### Batch Job
	ScheduleBatchToUpdateTrailheadStats schObj = new ScheduleBatchToUpdateTrailheadStats();
	String cron = '0 30 1/4 ? * MON-FRI';  //Every 4 hours starting 1:30 AM (US Time)
	String jobID = system.schedule('BatchToUpdateTrailheadStats', cron, schObj);    
### Schedule ScheduleToCreateTrailheadChatterPosts
	ScheduleToCreateTrailheadChatterPosts schObj = new ScheduleToCreateTrailheadChatterPosts();
	String cron = '0 30 23 ? * MON-FRI';
    String jobID = system.schedule('TrailheadChatterPosts', cron, schObj);    
### Activate site
