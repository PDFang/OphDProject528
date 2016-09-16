public with sharing class CaseAttachment 
{
	public Attachment Attach {get;set;}
	public boolean IsPublic {get;set;}
	public Id CaseId {get;set;}
	public string FileName {public get;private set;}
	public string Description {public get;private set;}
	public string LastModifiedBy {public get;private set;}
	public datetime LastModifiedDate {public get;private set;}
	public string AttachmentId;
	
	public CaseAttachment()
	{
		Attach = new Attachment();
	}
	
	public CaseAttachment(Attachment attachRecord, boolean isPublicAttach, id caseIdRecord)
	{
		Attach = new Attachment();
		Attach = attachRecord;
		IsPublic = isPublicAttach;
		CaseId = caseIdRecord;	
		FileName = attachRecord.Name;
		Description = attachRecord.Description;
		LastModifiedBy = attachRecord.LastModifiedBy.Name;	
		LastModifiedDate = attachRecord.LastModifiedDate;
		AttachmentId = attachRecord.Id;
	}
	
	public void SaveAttachment()
	{
		if(Attach.Id == null)
		{
			if(IsPublic)
			{
				Attach.ParentId = CaseId;
				try
				{
					insert Attach;
				}
				catch(Exception ex)
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				}
			}
			else
			{
				InternalAttachment__c ia = new InternalAttachment__c();
				ia.Case__c = CaseId;
				ia.FileName__c = Attach.Name;
				
				 
				try
				{
					insert ia;
					Attach.ParentId = ia.Id;
					insert Attach;
				}
				catch(Exception ex)
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				}
			}
		}
		else
		{
			string objectType = Attach.ParentId.getSObjectType().getDescribe().getName();
			Attachment newAttach = Attach.clone(false, true);
				
			if(objectType == 'InternalAttachment__c' && IsPublic)
			{
				InternalAttachment__c ia = new InternalAttachment__c(Id = Attach.ParentId);
				newAttach.ParentId = caseId;
								
				try
				{
					delete Attach;
					delete ia;
					insert newAttach;
				}
				catch(Exception ex)
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				}
			}
			
			if(objectType == 'Case' && !IsPublic)
			{
				InternalAttachment__c ia = new InternalAttachment__c();
				ia.Case__c = caseId;
				ia.FileName__c = Attach.Name;
				
				try
				{
					insert ia;
					newAttach.ParentId = ia.Id;
					insert newAttach;
					delete Attach;
				}
				catch(Exception ex)
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				}
			}
		}
	}
	
	public static void DeleteCaseAttachment(Id attachmentId)
	{
		Attachment a = [SELECT Id, ParentId FROM Attachment WHERE Id = :attachmentId];
		
		string objectType = a.ParentId.getSObjectType().getDescribe().getName();
		
		delete a;
		
		if(objectType == 'InternalAttachment__c')
		{
			InternalAttachment__c ia = new InternalAttachment__c(Id=a.ParentId);
			delete ia;
		}
	}
	
	public static List<CaseAttachment> SelectCaseAttachments(Id caseId)
	{
		List<CaseAttachment> attachments = new List<CaseAttachment>();
		
		Attachment[] publicAttachments = [SELECT Id, ContentType, ParentId, Body, Name, Description, LastModifiedDate, LastModifiedBy.Name FROM Attachment WHERE ParentId = :caseId];
		Attachment[] internalAttachments = [SELECT Id, ContentType, ParentId, Body, Name, Description, LastModifiedDate, LastModifiedBy.Name FROM Attachment WHERE Parent.Type = 'InternalAttachment__c' AND ParentId IN (SELECT ID FROM InternalAttachment__c WHERE Case__c = :caseId)];
		
		if(!publicAttachments.isEmpty())
		{
			for(Attachment a:publicAttachments)
			{
				CaseAttachment ca = new CaseAttachment(a,true, caseId);
				ca.Attach = null;
				attachments.add(ca);
			}	
		}
		
		if(!internalAttachments.isEmpty())
		{
			for(Attachment a:internalAttachments)
			{
				CaseAttachment ca = new CaseAttachment(a,false, caseId);
				ca.Attach = null;
				attachments.add(ca);
			}	
		}
		
		return attachments;
	}

}