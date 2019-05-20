/*
* Trailhead Tracker Application
* Shashwat Nandan
* 28/1/2019
*/
global class BatchToUpdateTrailheadStats implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    global final String query;
    global final Date dateToday;
    
    global BatchToUpdateTrailheadStats(){
        dateToday = Date.today();
        query='Select Trailhead_Id__c, Streak__c, Streak_Updated__c, Skills__c from Trailhead_User__c';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bC){
        
        List<Daily_Stats__c> dailyStatsList = [Select Id from Daily_Stats__c where Date__c =: dateToday];
        Database.DeleteResult[] sr = Database.delete(dailyStatsList, false);
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bC, List<sObject> scopeList){
        
        List<String> trailheadUserIds = new  List<String>();
        List<String> trailheadUserTrailheadIds = new  List<String>();
        Map<Id, Trailhead_User__c> mapIdTrailheadUser = new   Map<Id, Trailhead_User__c>();
        for(sobject scope : scopeList)
        {
            Trailhead_User__c trailheadUser = (Trailhead_User__c) scope;
            trailheadUserIds.add(trailheadUser.Id);
            trailheadUserTrailheadIds.add(trailheadUser.Trailhead_Id__c);
            mapIdTrailheadUser.put(trailheadUser.Id, trailheadUser);
        }
        TrailheadTrackerHelper.saveTrailheadStats(trailheadUserIds, trailheadUserTrailheadIds, mapIdTrailheadUser);
    }
    
    global void finish(Database.BatchableContext bC){
        system.debug('Batch Completed');
        List<AsyncApexJob> batchJobsListRaw = [SELECT CreatedDate, Status, ExtendedStatus, TotalJobItems, NumberOfErrors FROM AsyncApexJob where ApexClass.Name = 'BatchToUpdateTrailheadStats' ORDER BY CreatedDate DESC LIMIT 1];
        if(batchJobsListRaw != null && !batchJobsListRaw.isEmpty() )
        {
            AsyncApexJob latestBatchJob = batchJobsListRaw.get(0);
            if(latestBatchJob.NumberOfErrors > 0 /*&& latestBatchJob.ExtendedStatus.containsIgnoreCase('Read timed out')*/)
            {
                system.debug('Batch Failed. Re-Running');
                BatchToUpdateTrailheadStats batchToUpdateTrailheadStats= new BatchToUpdateTrailheadStats(); 
                database.executebatch(batchToUpdateTrailheadStats, 1);
            }
        }
    }
}