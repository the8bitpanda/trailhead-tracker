public without sharing class TrailheadTrackerBadgesController {
    
      
    public Boolean batchesProcessing{get;set;}
    
    public String searchKeyword {get;set;}
    public String sortByValue {get;set;}
    
    public List<BadgeData> listBadgesDisplayed {get;set;}
    List<Trailhead_User__c> allTrailheadUsers;
        
    public boolean isWeekend {get;set;}
    
    public Integer currentPageNumber {get;set;}
    public Integer totalPages {get;set;}
    public Integer pageLimit {get;set;}

    public TrailheadTrackerBadgesController()
    {
        List<AsyncApexJob> asyncApexJobList  = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob 
                                                where ApexClass.Name = 'BatchToUpdateTrailheadStats' 
                                                AND (Status != 'Aborted' AND Status != 'Completed' AND Status != 'Failed')];       
        
        batchesProcessing = !asyncApexJobList.isEmpty();
        
        isWeekend = (((DateTime)  date.today()).format('E') == 'Sat' || ((DateTime)  date.today()).format('E') == 'Sun')?true:false;
        
        pageLimit = 50;
        currentPageNumber = 1;
        
       	allTrailheadUsers = [Select Id, Name, Profile_Picture_URL__c, Trailhead_Id__c, Streak__c from Trailhead_User__c];
        
        
        
        String searchParam = Apexpages.currentPage().getParameters().get('viewBadge');
        searchKeyword = (searchParam == null)?'':searchParam.trim();
        sortByValue = '';
        getBadges();
       
    }
    
    public void setSeachKeyword()
    {
        String searchParam = (Apexpages.currentPage().getParameters().get('searchInput')).trim();
        searchKeyword = (searchParam == null)?'':searchParam.trim();
        sortByValue = '';
        currentPageNumber = 1;
        getBadges();
    }
    
    public void getBadges()
    {
        listBadgesDisplayed = new List<BadgeData>();
        
        String query = 'Select Id, Name, Title__c, URL__c, Icon_URL__c, Badge_Type__c, CreatedDate, (Select Trailhead_User__c from Badges_Achieved__r) from Trailhead_Badge__c';
        
        if(searchKeyword != null && searchKeyword  != '' && searchKeyword.length() > 0)
            query = query + ' where Name LIKE \'%' + searchKeyword + '%\'';
        
        if(sortByValue == 'Newest')
            query = query + ' order by CreatedDate DESC';
        else if(sortByValue == 'Name')
            query = query + ' order by Name ASC';
        else if(sortByValue == 'Completed By Count')
            query = query + ' order by Total_Achievers__c DESC';
        else if(sortByValue == 'Type')
            query = query + ' order by Type__c DESC';
        
        query = query + ' LIMIT ' + pageLimit + ' OFFSET ' + ((currentPageNumber-1)*pageLimit);
        
        List<Trailhead_Badge__c> allTrailheadBadges = Database.query(query);
        
        String totalBadgesQuery = 'Select Count() from Trailhead_Badge__c';
        
        if(searchKeyword != null && searchKeyword  != '' && searchKeyword.length() > 0)
            totalBadgesQuery = totalBadgesQuery + ' where Name LIKE \'%' + searchKeyword + '%\'';
        
        integer count= database.countQuery(totalBadgesQuery);
        
        totalPages = Integer.valueOf(Math.ceil(Decimal.valueOf(count).divide(pageLimit, 5)));
        
        for(Trailhead_Badge__c trailheadBadge : allTrailheadBadges)
        {
            
            List<UserData> completedBy = new List<UserData>();
            List<UserData> remainingUsers = new List<UserData>();
            
            Set<Id> usersThatCompletedtTrailheadBadge = new Set<Id>();
            for(Badge_Achieved__c badgeAchieved : trailheadBadge.Badges_Achieved__r)
            {
                usersThatCompletedtTrailheadBadge.add(badgeAchieved.Trailhead_User__c);
            }
            
            for(Trailhead_User__c trailheadUser : allTrailheadUsers)
            {
                if(usersThatCompletedtTrailheadBadge.contains(trailheadUser.Id))
                {
                    completedBy.add(new UserData(trailheadUser.Name, trailheadUser.Profile_Picture_URL__c, trailheadUser.Id, trailheadUser.Trailhead_Id__c, trailheadUser.Streak__c));
                }
                else
                {
                    remainingUsers.add(new UserData(trailheadUser.Name, trailheadUser.Profile_Picture_URL__c, trailheadUser.Id, trailheadUser.Trailhead_Id__c, trailheadUser.Streak__c));
                }
            }
            
            BadgeData varBadgeData = new BadgeData();
            varBadgeData.name = trailheadBadge.Title__c;
            varBadgeData.apiName = (trailheadBadge.Name).replaceAll('&','amp;');
            varBadgeData.path = trailheadBadge.URL__c;
            varBadgeData.imageSRC = trailheadBadge.Icon_URL__c;  
            varBadgeData.type = trailheadBadge.Badge_Type__c.capitalize();
            varBadgeData.completedBy = completedBy; 
            varBadgeData.remainingUsers = remainingUsers; 
            varBadgeData.createdDate = (trailheadBadge.CreatedDate).date();
            listBadgesDisplayed.add(varBadgeData);
        }
    }
    
    public PageReference reRunBatch()
    {
         List<AsyncApexJob> asyncApexJobList  = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob 
                                                where ApexClass.Name = 'BatchToUpdateTrailheadStats' 
                                                AND (Status != 'Aborted' AND Status != 'Completed' AND Status != 'Failed')];       
        
        if(asyncApexJobList.isEmpty())
        {   
            BatchToUpdateTrailheadStats batchToUpdateTrailheadStats = new BatchToUpdateTrailheadStats(); 
            database.executebatch(batchToUpdateTrailheadStats, 1);
        }
        
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;
    }
    
    public void reSortBadges()
    {
        sortByValue = Apexpages.currentPage().getParameters().get('sortByValue');
        currentPageNumber = 1;
        getBadges();
    }
    
    public void setPreviousPage()
    {
        if(currentPageNumber > 1)
        {
            currentPageNumber--;
        }
        getBadges();
    }
    
    public void setNextPage()
    {
        if(currentPageNumber < totalPages)
        {
            currentPageNumber++; 
        }   
        getBadges();
    }
    
   
    // Wrapper class UserData
    public class UserData {
        
        public String name { get; set; }
        public String profilePicture { get; set; }
        public String id { get; set; }
        public String trailheadId {get;set;}
        public Decimal streak {get;set;}
        
        public userData(String name, String profilePicture, String id, String trailheadId, Decimal streak) {
            this.Name = Name;
            this.ProfilePicture = ProfilePicture;
            this.Id = Id;  
            this.trailheadId = trailheadId;
            this.streak = streak;
        }
    }   
    
    // Wrapper class BadgeData
    public class BadgeData {
        
        public String name { get; set; }
        public String apiName { get; set; }
        public String path { get; set; }
        public String imageSRC { get; set; }
        public String type { get; set; }
        public List<UserData> completedBy {get;set;}
        public List<UserData> remainingUsers {get;set;}
        public Date createdDate { get; set; }
        
    }   
}