-----Trigger----------------------
Trigger ContacTrigger on Contact(After Insert,After update){
    if(Trigger.isAfter && Trigger.isInsert){
    	EnquiryTriggerHelper.onAfterInsert(Trigger.new);
    }
}
----------------Helper-----------

//Added By Abdul Pathan || 27 July 2023
public static void onAfterInsert(List<Opportunity> enquiryRecords){
    Map<Id, Id> enquiryIdAccountIdMap = new Map<Id, Id>();
    
    if(enquiryRecords.size() > 0){
        for(Opportunity opportunityRec : enquiryRecords){
            if(opportunityRec.AccountId != null){
                enquiryIdAccountIdMap.put(opportunityRec.Id, opportunityRec.AccountId);
            }
        }
    }
    if(enquiryIdAccountIdMap.size() > 0 ){
        createEnquiryClientContactRecords(enquiryIdAccountIdMap);
    }
}
------
//Create Enquiry Client Contact Records
private static void createEnquiryClientContactRecords(Map<Id, Id> enquiryIdAndAccountIdMap){
    Map<Id, List<Contact>>  accountContactMap = new   Map<Id, List<Contact>> ();
    List<Enquiry_Client_Contact__c> enquiryClientContactList = new List<Enquiry_Client_Contact__c>();
    
    List<Contact> contactRecords = [SELECT Id, AccountId FROM Contact 
                                    WHERE AccountId IN : enquiryIdAndAccountIdMap.values()
                                   ];
    if(contactRecords.size() > 0){
        for(Contact contactRecs: contactRecords){
            if(!accountContactMap.containsKey(contactRecs.AccountId)){
                accountContactMap.put(contactRecs.AccountId, new List<Contact>{contactRecs});
            }else{
                accountContactMap.get(contactRecs.AccountId).add(contactRecs);
            }
        }
    }
    if(enquiryIdAndAccountIdMap.size() > 0 && accountContactMap.size() > 0){
        for(Id opportunityId : enquiryIdAndAccountIdMap.keyset()){
            Id accId = enquiryIdAndAccountIdMap.get(opportunityId);
            if(accountContactMap.containsKey(accId)) {
                for(Contact contactRecord: accountContactMap.get(accId)){
                    enquiryClientContactList.add(new Enquiry_Client_Contact__c(Enquiry__c = opportunityId , Client_Contact__c = contactRecord.Id ));
                }
            }
        }
    }
    if(enquiryClientContactList.size()> 0){
        INSERT enquiryClientContactList;
    }
}

=========================================================

----ContactTrigger----------
//Added by Abdul Vahid || 31 July 2023
if(Trigger.isAfter && Trigger.isInsert){ 
    ContactTriggerHelper.onAfterInsert(trigger.new);
}
//Added by Abdul Vahid || 31 July 2023
if(Trigger.isAfter && Trigger.isUpdate){ 
    ContactTriggerHelper.onAfterUpdate(trigger.new, trigger.oldMap);
}
------Helper------

//Added by Abdul Vahid || 31 July 2023
public static void onAfterInsert(List<Contact> contactRecords){
    Map<Id, List<Contact>> accountIdContactListMap = new Map<Id, List<Contact>>();
    
    if(!contactRecords.isEmpty()){
        for(Contact cntRecord : contactRecords){
            if(cntRecord.KeyContactIdentifier__c == 'BOD' && cntRecord.AccountId != null){
                if(accountIdContactListMap.containsKey(cntRecord.AccountId)){
                    accountIdContactListMap.get(cntRecord.AccountId).add(cntRecord);    
                }else{
                    accountIdContactListMap.put(cntRecord.AccountId, new List<Contact>{cntRecord});
                }
            }
        }
    }
    if(!accountIdContactListMap.isEmpty()){
        createEnquiryClientContactRecords(accountIdContactListMap);
    }
}

//Added by Abdul Vahid || 31 July 2023
public static void onAfterUpdate(List<Contact> contactRecords, Map<Id, Contact> oldMap){
    Map<Id, List<Contact>> accountIdContactListMap = new Map<Id, List<Contact>>();
    Set<Id> contactIds = new Set<Id>();
    
    if(!contactRecords.isEmpty()){
        for(Contact cntRecord : contactRecords){
            if(oldMap != null && oldMap.get(cntRecord.Id).KeyContactIdentifier__c != cntRecord.KeyContactIdentifier__c &&  cntRecord.AccountId != null){
                if(cntRecord.KeyContactIdentifier__c == 'BOD'){
                    if(accountIdContactListMap.containsKey(cntRecord.AccountId)){
                        accountIdContactListMap.get(cntRecord.AccountId).add(cntRecord);    
                    }else{
                        accountIdContactListMap.put(cntRecord.AccountId, new List<Contact>{cntRecord});
                    }                        
                }else if(oldMap.get(cntRecord.Id).KeyContactIdentifier__c == 'BOD'){
                    contactIds.add(cntRecord.Id);
                }
            } 
        }
    }
    
    if(!contactIds.isEmpty()){
        deleteEnquiryClientContactRecords(contactIds);
    }
    if(!accountIdContactListMap.isEmpty()){
        createEnquiryClientContactRecords(accountIdContactListMap);
    }
}

//This method is creating Enquiry Client Contact records whenever Client Contact is created
private static void createEnquiryClientContactRecords(Map<Id, List<Contact>> accountIdAndContactRecords){
    List<Enquiry_Client_Contact__c> enquiryContactRecords = new List<Enquiry_Client_Contact__c>();
    
    List<Opportunity> enquiryRecords = [SELECT Id, AccountId FROM Opportunity
                                        WHERE AccountId IN : accountIdAndContactRecords.keySet()
                                       ];
    if(!enquiryRecords.isEmpty()){
        for(Opportunity enquiry: enquiryRecords){
            if(accountIdAndContactRecords.containsKey(enquiry.AccountId)){
                for(Contact contactObj : accountIdAndContactRecords.get(enquiry.AccountId)){
                    enquiryContactRecords.add(new Enquiry_Client_Contact__c(Client_Contact__c = contactObj.Id,  Enquiry__c = enquiry.Id));               
                }
            }            
        }
    }        
    if(!enquiryContactRecords.isEmpty()){
        INSERT enquiryContactRecords; 
    }        
}
//delete contact record related to enquiry client contact records
private static void deleteEnquiryClientContactRecords(Set<Id> contactIds){
    
    List<Enquiry_Client_Contact__c> enquiryClientContactRecords = [SELECT Id, Client_Contact__c FROM Enquiry_Client_Contact__c WHERE Client_Contact__c IN: contactIds];
    
    if(!enquiryClientContactRecords.isEmpty()){
        delete enquiryClientContactRecords;
    }        
}

========================