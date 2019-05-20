public class TrailheadTrackerErrorPageController {
    
    public boolean showReportIssuePanel{get;set;}
    public boolean showThankYouPanel{get;set;}
    
    public TrailheadTrackerErrorPageController()
    {
        showReportIssuePanel = false;
        showThankYouPanel = false;
    }
    
    public void sendReport()
    {
		String page = ApexPages.currentPage().getHeaders().get('Host') + Apexpages.currentPage().getUrl();
         
        String comments = (Apexpages.currentPage().getParameters().get('comments')).escapeJava();
        String name = (Apexpages.currentPage().getParameters().get('name')).escapeJava();
        String email = (Apexpages.currentPage().getParameters().get('email')).escapeJava();
        showThankYouPanel = true;
        
        try
        {
            Trailhead_Tracker__c tt = Trailhead_Tracker__c.getInstance();
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { tt.Admin_Email__c};
                message.subject = 'Trailhead Tracker Error Report';            
            message.plainTextBody = 'Comments: ' + comments + '\n\nCurrent Page: '  + page + '\n\nRegards, ' + name + '\n' + email;
            Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
                if(!Test.isRunningTest()) { Messaging.SendEmailResult[] results = Messaging.sendEmail(messages); }
        }
        catch(Exception e)
        {
            system.debug('Send Email Failed');
        }
    }
    
}