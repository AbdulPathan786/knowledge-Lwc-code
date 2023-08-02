trigger enquiryTrigger on Opportunity (after insert) {
	 if(Trigger.isAfter && Trigger.isInsert){
     	EnquiryTriggerHelper.onAfterInsert(Trigger.new);
     }
}
------EnquiryTriggerHelper----------------
public class EnquiryTriggerHelper {
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
            createEnquiryJointVentureRecords(enquiryIdAccountIdMap);
        }
    }
-------------createEnquiryJointVentureRecords-------------------
    //When an enquiry is created, child record of the account (Joint_Venture__c), Enquiry Joint Venture is created automatically
    //Create Enquiry Joint Venture Records
    private static void createEnquiryJointVentureRecords(Map<Id, Id> enquiryIdAndAccountIdMap){
        Map<Id, List<Joint_Venture__c>>  accountJointVentureMap = new   Map<Id, List<Joint_Venture__c>> ();
        List<Enquiry_Joint_Venture__c> enquiryJointVentureList = new List<Enquiry_Joint_Venture__c>();
        
        List<Joint_Venture__c> jointVentureRecords = [SELECT Id, Client__c FROM Joint_Venture__c 
                                                      WHERE Client__r.id IN : enquiryIdAndAccountIdMap.values()
                                                     ];
        if(jointVentureRecords.size() > 0){
            for(Joint_Venture__c jointVentureObj: jointVentureRecords){
                if(!accountJointVentureMap.containsKey(jointVentureObj.Client__c)){
                    accountJointVentureMap.put(jointVentureObj.Client__c, new List<Joint_Venture__c>{jointVentureObj});
                }else{
                    accountJointVentureMap.get(jointVentureObj.Client__c).add(jointVentureObj);
                }
            }
        }
        if(enquiryIdAndAccountIdMap.size() > 0 && accountJointVentureMap.size() > 0){
            for(string enquiryId: enquiryIdAndAccountIdMap.keySet()){
                Id accId = enquiryIdAndAccountIdMap.get(enquiryId);
                if(accountJointVentureMap.containsKey(accId)) {
                    for(Joint_Venture__c jointVentureRecord: accountJointVentureMap.get(accId)){
                        enquiryJointVentureList.add(new Enquiry_Joint_Venture__c(Enquiry__c = enquiryId , Joint_Venture__c = jointVentureRecord.Id ));
                    }
                }
            }
        }
        if(enquiryJointVentureList.size()> 0){
            INSERT enquiryJointVentureList;
        }
    }
}
===============END==============================