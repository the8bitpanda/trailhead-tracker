public class TrailheadUserTriggerHelper {
    
    public static void triggerHelper()
    {
        if(trigger.isAfter)
        {
            if(trigger.isInsert)
            {
                TrailheadUserTriggerHelper.afterInsert(trigger.new);
            }
        }
    }
    
    public static void afterInsert(List<Trailhead_User__c> triggerNew)
    {
        //save trailhead stats for today
        TrailheadUserTriggerHelper.initSaveDailyStats(trigger.new);
    }
    public static void initSaveDailyStats(List<Trailhead_User__c> triggerNew)
    {
        List<Id> trailheadUserIds = new  List<Id>();
        
        for(Trailhead_User__c trailheadUser : triggerNew) 
        {
            trailheadUserIds.add(trailheadUser.Id);
        }
        saveDailyStats(trailheadUserIds);
    }
    
    @Future(callout=true)	
    public static void saveDailyStats(List<Id> trailheadUserIdsList)
    {
        List<String> trailheadUserIds = new  List<String>();
        List<String> trailheadUserTrailheadIds = new  List<String>();
        Map<Id, Trailhead_User__c> mapIdTrailheadUser = new   Map<Id, Trailhead_User__c>();
        for(Trailhead_User__c trailheadUser : [Select Trailhead_Id__c, Streak__c, Streak_Updated__c, Skills__c from Trailhead_User__c where Id in :trailheadUserIdsList])
        {
            trailheadUserIds.add(trailheadUser.Id);
            trailheadUserTrailheadIds.add(trailheadUser.Trailhead_Id__c);
            mapIdTrailheadUser.put(trailheadUser.Id, trailheadUser);
        }
        TrailheadTrackerHelper.saveTrailheadStats(trailheadUserIds, trailheadUserTrailheadIds, mapIdTrailheadUser);
    }
}