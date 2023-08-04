/*************************** 
* @Name        JointVentureTrigger  
* @Author      Ayushi Sethi
* @Date        27/07/2023
****************************** */

trigger JointVentureTrigger on Joint_Venture__c (after insert){
    if(Trigger.isInsert && Trigger.isAfter){
        //this method is creating Enquiry Joint Venture records whenever Joint Venture is created
        JointVentureTriggerHelper.createEnquiryJointVenture(Trigger.new);
    }
}

/*************************** 
* @Name        JointVentureTriggerHelper  
* @Author      Ayushi Sethi
* @Date        27/07/2023
****************************** */

public class JointVentureTriggerHelper{
    //this method is creating Enquiry Joint Venture records whenever Joint Venture is created
    public static void createEnquiryJointVenture(List<Joint_Venture__c> jointVentures){
        Map<Id,List<Joint_Venture__c>> accountIdJointVentures = new Map<Id,List<Joint_Venture__c>>();
        for(Joint_Venture__c jointVenture : jointVentures){
            if(jointVenture.Client__c != null){
                if(!accountIdJointVentures.containsKey(jointVenture.Client__c)){
                     accountIdJointVentures.put(jointVenture.Client__c,new List<Joint_Venture__c>());
                }
                accountIdJointVentures.get(jointVenture.Client__c).add(jointVenture);               
            }
        }
        List<Opportunity> enquiries = new List<Opportunity>([SELECT Id,AccountId from Opportunity where AccountId IN : accountIdJointVentures.keySet()]);
        List<Enquiry_Joint_Venture__c> enquiryJointVentures = new List<Enquiry_Joint_Venture__c>();
        for(Opportunity enquiry: enquiries){
            String accountId = enquiry.AccountId;
            if(accountIdJointVentures.containsKey(accountId)){
                for(Joint_Venture__c jointVenture : accountIdJointVentures.get(enquiry.AccountId)){
                    enquiryJointVentures.add(new Enquiry_Joint_Venture__c(
                        Joint_Venture__c = jointVenture.Id,
                        Enquiry__c = enquiry.Id));               
                }
            }
            
        }
        system.debug('enquiryJointVentures.size() '+enquiryJointVentures.size());
        if(enquiryJointVentures.size() > 0)
        	INSERT enquiryJointVentures;
    }
}