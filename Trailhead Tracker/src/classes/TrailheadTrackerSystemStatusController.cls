public without sharing class TrailheadTrackerSystemStatusController {
    
    public List<AsyncApexJob> batchJobsList{get;set;}
    public Id batchToUpdateTrailheadStatsId {get;set;}
    public boolean batchesProcessing {get;set;}
    
    public TrailheadTrackerSystemStatusController()
    {   
        //batchJobsList = new List<AsyncApexJob>();
        batchJobsList = [SELECT ApexClass.Name, CreatedDate, Status, ExtendedStatus, TotalJobItems, NumberOfErrors FROM AsyncApexJob where ApexClass.Name = 'BatchToUpdateTrailheadStats' OR ApexClass.Name = 'ScheduleToCreateTrailheadChatterPosts' ORDER BY CreatedDate DESC limit 10];
        
        List<AsyncApexJob> asyncApexJobList  = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob 
                                                where ApexClass.Name = 'BatchToUpdateTrailheadStats' 
                                                AND JobType = 'BatchApex'
                                                AND (Status != 'Aborted' AND Status != 'Completed' AND Status != 'Failed')];       
        
        if(!asyncApexJobList.isEmpty())
        {
            
            batchToUpdateTrailheadStatsId = asyncApexJobList[0].Id;
            batchesProcessing = true;
        }
        
    }
    
    public PageReference abortJob()
    {
        System.AbortJob(batchToUpdateTrailheadStatsId);
        PageReference pageRef = new PageReference('/trailheadtrackersystemstatus');
        return pageRef;
        
    }
}