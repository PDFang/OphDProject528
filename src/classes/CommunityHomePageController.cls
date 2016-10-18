public class CommunityHomePageController {
	public string AccountName{get; set;}
    public string logoURL{get;set;} 
    public string imageClass{get; set;}
    public list<Idea> ideas {get; private set;}
    public Idea ideaDetail{get; set;}
	public list<IdeaComment> lstComments {get; private set;}
    public boolean showModal{get; set;}
    public map<string, string> Ispromotedideas {get; private set;}
    public map<string, string> IspromotedComments {get; private set;}
    public string ideaTitle {get; set;}
    public string ideaDescription {get; set;}
    public list<Idea> similarIdeas{get; set;}
    public string ideaComment{get; set;}
	public Boolean isIncontact{get;Set;}
    public string phoneNumber {get; Set;}
	public string headerStyle  {get; Set;}
	public String footerStyle {get; Set;}
	public string hideHeaderElement{get;Set;}
	public string phoneNumberStyle{get;Set;}
	public String totalIdeaCount{get;Set;}
    public String cachedValue{get;Set;}

    public CommunityHomePageController(){
       doLoad();
		getIdeas();
		if (!isIncontact)
			phoneNumber = '1.855.512.4822';
		else
			phoneNumber = '1.888.826.0080';
        showModal = false;
       similarIdeas = new List<Idea>();
        user U = [select UserRoles__c From User where UserName = :UserInfo.getUserName()];
        
        cachedValue = U.UserRoles__c;                
        system.debug('cachedValue ==>' + cachedValue);
    }    
    
    public void addToCache(){
        
        String paramValue = ApexPages.currentPage().getParameters().get('AccountId');
        Cache.SessionPartition partition = Cache.Session.getPartition('local.TESTPARTITION');
        system.debug(partition.contains('AccountId'));
        if(partition.contains('AccountId') == false){
        	//partition.put('AccountId', paramValue);
        }
        
    }
    
  public static User getUserName() {
       system.debug('username = >' + userinfo.getUserName());
      
    return [select Id, FirstName, Lastname, Contact.Account.Name from User where  Username =: userinfo.getUserName()];
     
  }
   
    public List<Account> getAccounts(){
        
        return [select Id, Name from Account LIMIT 10];
    }
   public void doLoad()
   {
		isIncontact = true;
		headerStyle = 'margin-left: 1.75%;';
		footerStyle = 'float-left; margin-left:8%;';
		hideHeaderElement = 'display : none;';
		phoneNumberStyle = 'padding-left:30px;';
        if(userinfo.getUserType() != 'Standard'){
              List<User> lstacct = [select Contact.Account.Name, Contact.Account.CadebillAccountNo__c from User where  Username =: userinfo.getUserName() Limit 1];
			  AccountName = lstacct[0].Contact.Account.CadebillAccountNo__c  + ' - ' + lstacct[0].Contact.Account.Name;
    
            if(AccountName.containsIgnoreCase('Verizon')){
                imageClass = 'verizonImage';
				isIncontact = false;
				hideHeaderElement = '';
                logoURL = '/supportsite/resource/verizonlogo';
				headerStyle = 'margin-left: 7.75%;';
				footerStyle = 'float-left; margin-left:13%;';
				phoneNumberStyle = 'padding-left : 0px;';
            }
            else {
                imageClass ='incontactImage'; 
                logoURL = '/supportsite/resource/incontactHeaderLogo';
            }
        }
        else {
                imageClass ='incontactImage'; 
                logoURL = '/supportsite/resource/incontactHeaderLogo';
            }
   }


    @AuraEnabled
    public static List<Case> getCases() {
        String [] caseFields = new String []		 {'Id',
                                                       'Subject',
                                                       'ContactId',
                                                       'AccountId',
                                                       'CaseNumber',
													   'Status',
                                                       'CreatedDate'
                                                       };

                                                           

    // Obtain the field name/token map for the Expense object
    Map<String,Schema.SObjectField> m = Schema.SObjectType.Case.fields.getMap();

    for (String fieldToCheck : caseFields) {

        // Check if the user has access to view field
        if (!m.get(fieldToCheck).getDescribe().isAccessible()) {

            // Pass error to client
            throw new System.NoAccessException();
           // Suppress editor logs
           return null;
        }
    }
 
    // Query the object safely
    return [SELECT Id, Subject, Contact.FirstName, Contact.LastName, Account.Name, Status,
            CaseNumber, CreatedDate FROM Case where Contact.Email =: userInfo.getUserEmail()];       
    } 

	@AuraEnabled
	public static String getBodyStyle(){
		 List<User> lstacct = [select Contact.Account.Name, Contact.Account.CadebillAccountNo__c from User where  Username =: userinfo.getUserName() Limit 1];
		 string bodyStyle = 'margin-left : 6.5%;';
		 if(lstacct[0].Contact.Account.Name.containsIgnoreCase('Verizon')){
               bodyStyle = 'margin-left : 11.5%;';
            }
			return bodyStyle;
	}

    public void getIdeas(){
        
        Community community = [ SELECT Id FROM Community WHERE Name = 'Uptivity Products' ];
        ideas = new list<Idea>();
		totalIdeaCount = '[Count = 0]';
         Ispromotedideas = new map<string, string>(); 
        set<Id> stIdeas = new set<Id>();
        for(Idea temp : [select Id, Title, Body, CreatorName,CreatorSmallPhotoUrl, NumComments, VoteTotal from Idea where Id != null and CommunityId =: community.Id order by VoteTotal desc]){
            ideas.add(temp);
            stIdeas.add(temp.Id);
       }
	   totalIdeaCount = '[Count = ' + ideas.size() + ']';
       Ispromotedideas = new map<string, string>(); 
	   Ispromotedideas = getPromotedIdeasComments(stIdeas, 'Idea');
        
    }
    
    public void getIdeaDetails(){
         string ideaId = Apexpages.currentPage().getParameters().get('ideaId');
        
        ideaDetail = new Idea();
     
        set<id> stIdeas = new set<Id>();
        
        if(ideaId != null && ideaId != '')
        {
         
            stIdeas.add(ideaId);
           ideaDetail = [select Id, Title, Body, CreatorName,CreatorSmallPhotoUrl, NumComments, VoteTotal from Idea where Id =: ideaId];           
           Ispromotedideas = new map<string, string>(); 
	   	   Ispromotedideas = getPromotedIdeasComments(stIdeas, 'Idea');
		   System.debug('Ispromotedideas ==>' + Ispromotedideas);	
           loadComments(ideaId); 

        }
    }
    
    public void loadComments(Id ideaId){
          lstComments = new list<IdeaComment>();
          set<id> stComments = new set<Id>();
          for(IdeaComment temp : [Select id,CommentBody, CreatorName, UpVotes from IdeaComment where IdeaId =: ideaId order By CreatedDate desc]){
            		lstComments.add(temp);
            	    stComments.add(temp.Id);
       	  }  
          showModal = true;
          IspromotedComments = new map<string, string>();   
          IspromotedComments =  getPromotedIdeasComments(stComments, 'IdeaComment');   
        
    }
    
    
    public  map<string, string> getPromotedIdeasComments(set<Id> stParentIds, string parentType){
      // public map<string, string> Ispromotedideas {get; private set;}
      // public map<string, string> IspromotedComments {get; private set;}
       
       
       map<string, string> Ispromoted = new map<string, string>();        
        
         for(Vote v : [select Id, ParentId,CreatedById,Type from Vote where Parent.Type =: parentType]){
            string createdId = string.valueOf(v.CreatedById);
            
            if(stParentIds.contains(v.ParentId) && createdId.startswith(userinfo.getUserId())){
                if(ispromoted.containsKey(v.ParentId))
                    ispromoted.remove(v.ParentId);
                
                Ispromoted.put(v.ParentId, 'Inactive');
            }
            else
                if(!ispromoted.containsKey(v.ParentId))
              		  Ispromoted.put(v.ParentId, 'Active');
            
        }
        
        for(Id parentId : stParentIds){
            if(!Ispromoted.containsKey(parentId)){
                 Ispromoted.put(parentId, 'Active');
            }
        }
            
        
        
       return Ispromoted;
        
    }
    
    
    public void saveIdeas(){
        try{
            Community community = [ SELECT Id FROM Community WHERE Name = 'Community Ideas' ];
            Idea newIdea = new Idea();
            newIdea.Title = ideaTitle;
            newIdea.Body = ideaDescription;    
            newIdea.CommunityId = community.Id;
            insert newIdea;
			ideaTitle = '';
			ideaDescription = '';
			doLoad();
            getIdeas();
        }
        catch(Exception ex){
           // ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + ex.getMessage());
         //   ApexPages.addMessage(myMsg);
        }
    }
    
    public void similarFind(){
        similarIdeas = new List<Idea>();
        Idea newIdea = new Idea();
        newIdea.Title = ideaTitle;
        ID[] results = System.Ideas.findSimilar(newIdea);
        similarIdeas = [select Id, Title from Idea where Id = :results];
        system.debug('similarideas ==>' + similarIdeas);
    
    }
    
    public void addComments(){
        IdeaComment ic = new IdeaComment();
        ic.CommentBody = ideaComment;
        ic.IdeaId = ideaDetail.Id;
        insert ic;
		ideaComment = '';
       	loadComments(ideaDetail.Id);
		doLoad();
        getIdeas();
        
    } 
    
  	@RemoteAction
    public static void UpdateVotes(string parentId) {
        system.debug(parentId);
        
        
    }  
    
   
}