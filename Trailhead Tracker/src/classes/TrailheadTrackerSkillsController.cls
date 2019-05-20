public class TrailheadTrackerSkillsController {
    
    public boolean batchesProcessing{get;set;}
    public boolean isWeekend{get;set;}
    
    public boolean toggleMatrix{get;set;}
    public String skillChosen{get;set;}
    public String sortBy{get;set;}
    public Map<String, List<SkillsUserData>> mapSkillUsers {get;set;}
    public List<String> listSkills {get;set;}
    public List<SkillsUserData> listUsers {get;set;}
    public Map<String, Map<String, Integer>> mapUsersSkillsMatrix {get;set;}
    public Map<String, Map<String, String>> mapUserSkillColorCoding {get;set;}
    
    public TrailheadTrackerSkillsController()
    {
        if(Apexpages.currentPage().getParameters().get('skill') != null)
        {
            skillChosen = (Apexpages.currentPage().getParameters().get('skill')).escapeJava();
            toggleMatrix = false;
        }
        else
        {
            toggleMatrix = true;
        }
        sortBy = 'Name';
        
        
        
        List<AsyncApexJob> asyncApexJobList  = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob 
                                                where ApexClass.Name = 'BatchToUpdateTrailheadStats' 
                                                AND (Status != 'Aborted' AND Status != 'Completed' AND Status != 'Failed')];       
        
        batchesProcessing = !asyncApexJobList.isEmpty();
        isWeekend = (((DateTime)  date.today()).format('E') == 'Sat' || ((DateTime)  date.today()).format('E') == 'Sun')?true:false;
        
        getData();
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
    
    public void setSkill()
    {
        skillChosen = (Apexpages.currentPage().getParameters().get('skillChosen'));
    }
    
    public void setInteractiveTable()
    {
        toggleMatrix = false;
        getData();
    }
    
    public void setSkillMatrix()
    {
        toggleMatrix = true;
        getData();
    }
    
    public void getData()
    {
        if(toggleMatrix)
            getSkillMatrixData();
        else
            getInteractiveTableData();
    }
    
    public void getInteractiveTableData()
    {
        mapSkillUsers = new Map<String, List<SkillsUserData>>();
        for(Trailhead_User__c trailheadUserRaw : [Select Id, Name, Skills__c, Streak__c, Trailhead_Id__c from Trailhead_User__c])
        {
            if(trailheadUserRaw.Skills__c!=null)
            {
                Map<String, Object> userSkillsMap = (Map<String, Object>)JSON.deserializeUntyped(trailheadUserRaw.Skills__c);
                
                for(String skillLabel : userSkillsMap.keySet())
                {
                    SkillsUserData varSkillUser = new SkillsUserData();
                    varSkillUser.id = trailheadUserRaw.Id;
                    varSkillUser.name = trailheadUserRaw.Name;
                    varSkillUser.trailheadId = trailheadUserRaw.Trailhead_Id__c;
                    varSkillUser.streak = trailheadUserRaw.Streak__c;
                    varSkillUser.count = Integer.valueOf(userSkillsMap.get(skillLabel));
                    
                    if(mapSkillUsers.containsKey(skillLabel))
                    {
                        mapSkillUsers.get(skillLabel).add(varSkillUser);
                    }
                    else
                    {
                        mapSkillUsers.put(skillLabel, new List<SkillsUserData>{varSkillUser});
                    }
                }
            }
        }
        
        for(String varSkill : mapSkillUsers.keySet())
        {
            List<SkillsUserData> listSkillsUserData = mapSkillUsers.get(varSkill);
            
            Integer i, j;
            SkillsUserData temp;
            Integer n = listSkillsUserData.size();
            boolean swapped; 
            for (i = 0; i < n - 1; i++)  
            { 
                swapped = false; 
                for (j = 0; j < n - i - 1; j++)  
                { 
                    if (listSkillsUserData[j].count < listSkillsUserData[j + 1].count)  
                    { 
                        temp = listSkillsUserData[j]; 
                        listSkillsUserData[j] = listSkillsUserData[j + 1]; 
                        listSkillsUserData[j + 1] = temp; 
                        
                        swapped = true; 
                    } 
                } 
                
                if (swapped == false) 
                    break; 
            } 
        }
    }
    
    public void getSkillMatrixData()
    {
        listSkills = new List<String>();
        listUsers = new List<SkillsUserData>();
        Set<String> tempSet = new Set<String>();
        mapUsersSkillsMatrix = new Map<String, Map<String, Integer>>();
        mapUserSkillColorCoding = new Map<String, Map<String, String>>();
        for(Trailhead_User__c trailheadUserRaw : [Select Id, Name, Skills__c, Streak__c, Trailhead_Id__c from Trailhead_User__c])
        {
            SkillsUserData varUserData = new SkillsUserData();
            varUserData.id = trailheadUserRaw.Id;
            varUserData.name = trailheadUserRaw.Name;
            varUserData.trailheadId = trailheadUserRaw.Trailhead_Id__c;
            varUserData.streak = trailheadUserRaw.Streak__c;
            listUsers.add(varUserData);
            
            Map<String, Integer> mapSkillCount = new Map<String, Integer>();
            if(trailheadUserRaw.Skills__c!=null)
            {
                Map<String, Object> userSkillsMap = (Map<String, Object>)JSON.deserializeUntyped(trailheadUserRaw.Skills__c);
                for(String skillLabel : userSkillsMap.keySet())
                {
                    tempSet.add(skillLabel);
                    mapSkillCount.put(skillLabel, Integer.valueOf(userSkillsMap.get(skillLabel)));
                }
            }
            mapUsersSkillsMatrix.put(trailheadUserRaw.Id, mapSkillCount);
        }
        for(String skill : tempSet)
        {
            for(String userId : mapUsersSkillsMatrix.keySet())
            {
                if(!mapUsersSkillsMatrix.get(userId).keySet().contains(skill))
                {
                    mapUsersSkillsMatrix.get(userId).put(skill, 0);
                }
            }
        }
        listSkills.addAll(tempSet);
        listSkills.sort();
        setColorCoding();
        sortUser();
    }
    
    public void setColorCoding()
    {
        for(String skill : listSkills)
        {
            
            for(SkillsUserData varUser : listUsers)
            {
                varUser.count = mapUsersSkillsMatrix.get(varUser.id).get(skill);
            }
            
            Integer i, j;
            SkillsUserData temp;
            Integer n = listUsers.size();
            boolean swapped; 
            for (i = 0; i < n - 1; i++)  
            { 
                swapped = false; 
                for (j = 0; j < n - i - 1; j++)  
                { 
                    if (listUsers[j].count < listUsers[j + 1].count)  
                    { 
                        temp = listUsers[j]; 
                        listUsers[j] = listUsers[j + 1]; 
                        listUsers[j + 1] = temp; 
                        
                        swapped = true; 
                    } 
                } 
                
                if (swapped == false) 
                    break; 
            }
            Integer highestCount = listUsers[0].count;
            Integer totalUsers = listUsers.size();
            for(Integer x=0; x<totalUsers; x++)
            {
                SkillsUserData varUser = listUsers[x];
                if(mapUserSkillColorCoding.containsKey(varUser.Id))
                {
                    if(varUser.count < highestCount)
                    {
                        if(varUser.count > 0)
                        {
                            if(x<=((totalUsers-1)/3))
                                mapUserSkillColorCoding.get(varUser.Id).put(skill, '#56B643'); //green
                            else if(x<=(((totalUsers-1)*2)/3))
                                mapUserSkillColorCoding.get(varUser.Id).put(skill, '#FFA500'); //orange
                            else
                                mapUserSkillColorCoding.get(varUser.Id).put(skill, '#d8000c'); //red
                        }
                        else
                            mapUserSkillColorCoding.get(varUser.Id).put(skill, '#444444'); //dark grey
                    }
                    else
                    {
                        mapUserSkillColorCoding.get(varUser.Id).put(skill, '#1798c1'); //blue
                    }
                }
                else
                {
                    if(varUser.count < highestCount)
                    {
                        if(varUser.count > 0)
                        {
                            if(x<=((totalUsers-1)/3))
                                mapUserSkillColorCoding.put(varUser.Id, new Map<String, String>{skill => '#56B643'});
                            else if(x<=(((totalUsers-1)*2)/3))
                                mapUserSkillColorCoding.put(varUser.Id, new Map<String, String>{skill => '#FFA500'});
                            else
                                mapUserSkillColorCoding.put(varUser.Id, new Map<String, String>{skill => '#d8000c'});
                        }
                        else
                            mapUserSkillColorCoding.put(varUser.Id, new Map<String, String>{skill => '#444444'});
                    }
                    else
                    {
                        mapUserSkillColorCoding.put(varUser.Id, new Map<String, String>{skill => '#1798c1'});
                    }
                }
            }
        }
        
    }
    
    public void sortUser()
    {
        if(Apexpages.currentPage().getParameters().get('sortBy') != null && Apexpages.currentPage().getParameters().get('sortBy') != '' && Apexpages.currentPage().getParameters().get('sortBy') != 'Name')
        {
            sortBy = Apexpages.currentPage().getParameters().get('sortBy');
            //listSkills.sort();
            //listSkills.remove(listSkills.indexOf(sortBy));
            //listSkills.add(0, sortBy);
            
            for(SkillsUserData varUser : listUsers)
            {
                varUser.count = mapUsersSkillsMatrix.get(varUser.id).get(sortBy);
            }
        }
        else
        {
            sortBy = 'Name';
            //listSkills.sort();
            for(SkillsUserData varUser : listUsers)
            {
                varUser.count = 0;
            }
            
        }
        
        Integer i, j;
        SkillsUserData temp;
        Integer n = listUsers.size();
        boolean swapped; 
        for (i = 0; i < n - 1; i++)  
        { 
            swapped = false; 
            for (j = 0; j < n - i - 1; j++)  
            { 
                if ((sortBy == 'Name' && listUsers[j].name > listUsers[j + 1].name) || 
                    (sortBy != 'Name' && listUsers[j].count < listUsers[j + 1].count))  
                { 
                    temp = listUsers[j]; 
                    listUsers[j] = listUsers[j + 1]; 
                    listUsers[j + 1] = temp; 
                    
                    swapped = true; 
                } 
            } 
            
            if (swapped == false) 
                break; 
        }
        
        
    }
    
    
    public class SkillsUserData 
    {
        public String id { get; set; }
        public String name { get; set; }
        public String trailheadId { get; set; }
        public Decimal streak { get; set; }
        public Integer count {get;set;}
    }
}