/*
* Name: LeaveApprovedBatch
* Date: 07th March 2024
* Description: This batch class send a consolidate email to HR and Leave for leave approved.
*/
global class LeaveApprovedBatch implements Database.Batchable<sObject>, Database.Stateful{
    global Set<Id> setleaveRecordIds = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Employee__c, Leave_Approved_Adjusted__c, Employee__r.Reporting_Person__c, Employee__r.Email 
                                         FROM Leave__c 
                                         WHERE Employee__r.recordtype.name = 'Employee' AND  Employee__r.active__c = true AND 
                                         Approved_Rejected__c IN ('Approved','Adjusted')  AND Leave_Approved_Adjusted__c = FALSE
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Leave__c> leaveRecords){
        Map<Id, List<Leave__c>> employeeIdsLeavesMap = new Map<Id, List<Leave__c>>();// Map to group leave records by employee ID
        Map<Id, Id> reportingMap = new Map<Id, Id>();
        
        if(!leaveRecords.isEmpty()){
            for (Leave__c leave : leaveRecords) {
                if(!employeeIdsLeavesMap.containsKey(leave.Employee__c)){
                    employeeIdsLeavesMap.put(leave.Employee__c, new List<Leave__c>{leave});
                }else{
                    employeeIdsLeavesMap.get(leave.Employee__c).add(leave);
                }
                reportingMap.put(leave.Employee__c, leave.Employee__r.Reporting_Person__c); 
            } 
        }
        
        // If there are leave records in the map
        if (!employeeIdsLeavesMap.isEmpty()) {
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();  
            
            List<OrgWideEmailAddress> orgWideAdd = [SELECT Id FROM OrgWideEmailAddress WHERE displayname = 'iBirds Services'];
            
            Id orgWideId;
            if(!orgWideAdd.isEmpty()){
                orgWideId = orgWideAdd.get(0).Id;
            }  
            
            Id templateId;
            List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Leave_Notification_Approved'];
            if(!templates.isEmpty()){
                templateId = templates.get(0).id;
            }
            
            for (Id empId : employeeIdsLeavesMap.keySet()) { 
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSaveAsActivity(false);
                mail.setTemplateId(templateId);
                mail.setWhatId(empId);
                mail.setTargetObjectId(empId);// Set the target object ID
                mail.setToAddresses(new List<String>{employeeIdsLeavesMap.get(empId)[0].Employee__r.Email});// Set the TO address                
                List<String> ccAddresses = new List<String>();// Set the CC address
                if(reportingMap.containsKey(empId) && reportingMap.get(empId) != null){
                    ccAddresses.add(reportingMap.get(empId));
                }
                ccAddresses.addAll(label.hrms_admin_email.split(','));
                mail.setCCAddresses(ccAddresses);
                
                if(orgWideId != NULL) {
                    mail.setOrgWideEmailAddressId(orgWideId); 
                }
                emailList.add(mail); 
                
                for (Leave__c leave : employeeIdsLeavesMap.get(empId)) {
                    setleaveRecordIds.add(leave.Id); // Add leave IDs to the set to be updated
                }
            }
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(emailList, false);                                                  
        }
    }
    
    global void finish(Database.BatchableContext BC) {        
        if (!setleaveRecordIds.isEmpty()) {
            List<Leave__c> updateleaveRecords = new List<Leave__c>();
            for (Id leaveId : setleaveRecordIds) {
                updateleaveRecords.add(new Leave__c(Id = leaveId, Leave_Approved_Adjusted__c = TRUE));
            }
            if(!updateleaveRecords.isEmpty()){
                UPDATE updateleaveRecords;
            }
        }
    } 
}