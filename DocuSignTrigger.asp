/*
* @Name: DocuSignTrigger
* @Author: iBirds 
* @Date: 21 June, 2022
*/
trigger DocuSignTrigger on ntportal__DocuSign_Status_Fake__c (After Insert, After Update) {
    
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        DocuSignTriggerHelper.onAfterInsertOrUpdate(trigger.new, trigger.oldMap, trigger.isUpdate);
    }
    
}
------------
/*
* @Name: DocuSignTriggerHelper
* @Author: iBirds
* @Date: 21 June, 2022
*/
public class DocuSignTriggerHelper {
    
     
    private static final Map<String, String> DOCU_SIGN_AND_APPLICATION_STATUS_MAP = new Map<String, String>{
            'Sent' => 'Documents Out to Customer',
            'Delivered' => 'Documents Out to Customer',
            'Voided' => 'Documents Generated',
            'Delivery Failure' => 'Documents Generated',
            'Expired' => 'Documents Generated',
            'Authentication Failed' => 'No Status Change',
            'Completed' => 'Documents In',
            'Declined' => 'Not including in OOB Design'
     };
    
    public static void onAfterInsertOrUpdate(List<ntportal__DocuSign_Status_Fake__c> newList, Map<Id, ntportal__DocuSign_Status_Fake__c> OldMap, Boolean isUpdate){
        
        Map<String, ntportal__DocuSign_Status_Fake__c> applicationIdWithDocuSignMap = new Map<String, ntportal__DocuSign_Status_Fake__c>();
        
        for(ntportal__DocuSign_Status_Fake__c obj: newList){
            if(obj.ntportal__Envelope_Status__c != null && obj.ntportal__Application__c != null){
                if(isUpdate &&  (OldMap.get(obj.Id).ntportal__Envelope_Status__c != obj.ntportal__Envelope_Status__c)){
                    applicationIdWithDocuSignMap.put(obj.ntportal__Application__c, obj);
                }else if(!isUpdate){
                    applicationIdWithDocuSignMap.put(obj.ntportal__Application__c, obj);
                }
                
            }
        }
        
        if(!applicationIdWithDocuSignMap.isEmpty()){
            updateApplicationRecords(applicationIdWithDocuSignMap);
        }
    }
    
    private static void updateApplicationRecords(Map<String, ntportal__DocuSign_Status_Fake__c> applicationIdWithDocuSignMap){
        List<ntportal__Application__c> updateApplications = new  List<ntportal__Application__c>();
        
        List<ntportal__Application__c> applicationsRecords = [SELECT Id, ntportal__Status__c,
                                                              (SELECT Id, ntportal__Envelope_Status__c, ntportal__Application__c FROM ntportal__DocuSign_Status_Fake__r) 
                                                              FROM ntportal__Application__c WHERE Id IN : applicationIdWithDocuSignMap.keyset()];
        if(applicationsRecords != null && !applicationsRecords.isEmpty()){
            for(ntportal__Application__c objApplication : applicationsRecords){ 
                for(String applicationId: applicationIdWithDocuSignMap.keySet()){
                    String docuSingStatus = applicationIdWithDocuSignMap.get(applicationId).ntportal__Envelope_Status__c;
                    
                    if(DOCU_SIGN_AND_APPLICATION_STATUS_MAP.containsKey(docuSingStatus)){
                        objApplication.ntportal__Status__c = DOCU_SIGN_AND_APPLICATION_STATUS_MAP.get(docuSingStatus);    
                        updateApplications.add(objApplication);
                    }
                    
                } 
            }
        }  
        if(!updateApplications.isEmpty()){
            update updateApplications;
        }
    }
}