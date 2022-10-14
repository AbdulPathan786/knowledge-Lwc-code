/**
    * @description get records that match the given criteria or recently viewed
    * @param  objectName       Name of sobject to search
    * @param  objectLabelField field to search
    * @param  searchString     string to search for
    * @return                  return List of matching data results
*/

public with sharing class CustomLookupController{ 
    
    @AuraEnabled
    public static List<LookupSearchResult> searchLookupRecords(String searchTerm, List<String> selectedIds, String sObjectName, String field, String subField, Integer maxResults, String filterCondition) {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName;
        strQuery += ' WHERE '+field+' LIKE \'' + searchTerm + '%\' AND '; 
        strQuery += String.isNotBlank(filterCondition) ? filterCondition : '';                                                         
        strQuery += ' Id NOT IN :selectedIds ORDER BY '+field+' LIMIT :maxResults';
        
        List<sObject> searchResults = Database.query(strQuery);   
        if(searchResults != NUll && !searchResults.isEmpty()){
            for(sObject sObj : searchResults){
                LookupSearchResult res = new LookupSearchResult();
                res.Id = sObj.Id;
                res.title = String.valueOf(sObj.get(field));
                if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                    res.subtitle = String.valueOf(sObj.get(subField));
                }else{
                    res.subtitle = sObjectName;
                }
                results.add(res);
            } 
        }
        return results;        
    }
    
    @AuraEnabled
    public static List<LookupSearchResult> getRecentlyViewed(List<String> selectedIds, String sObjectName, String field, String subField, Integer maxResults, String filterCondition){
        
        List<sObject> searchResults = new List<sObject>();  
        /* String objectType = '\''+ sObjectName + '\'';

String strQuery = '';
strQuery = 'SELECT Id, Name FROM RecentlyViewed WHERE Type = '+ objectType;
strQuery += String.isNotBlank(filterCondition) ? ' AND ' + filterCondition : ' AND ';                                                        
strQuery += ' Id NOT IN :selectedIds ORDER BY '+field+' LIMIT :maxResults';
System.debug('#strQuery_1: '+ strQuery);
searchResults =  Database.query(strQuery);*/
        
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName;
        strQuery += String.isNotBlank(filterCondition) ? ' WHERE ' + filterCondition  : ' WHERE ';                                                     
        strQuery += ' Id NOT IN :selectedIds ORDER BY CreatedDate DESC LIMIT :maxResults';
        
        //System.debug('#strQuery_2: '+ strQuery);
        
        searchResults =  Database.query(strQuery);
        
        return fillLookupSearchResult(searchResults, sObjectName, field, subField);
    }
    
    private static List<LookupSearchResult> fillLookupSearchResult(List<sObject> allRecords,String sObjectName, String field, String subField){
        
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        if(allRecords != NUll && !allRecords.isEmpty()){
            for(sObject sObj : allRecords){
                LookupSearchResult res = new LookupSearchResult();
                res.Id = sObj.Id;
                res.title = String.valueOf(sObj.get(field));
                if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                    res.subtitle = String.valueOf(sObj.get(subField));
                }
                results.add(res);
            } 
        }
        return results; 
    }
    
    @AuraEnabled
    public static LookupSearchResult getRecentlyCreatedRecord(String sObjectName, String recordId, String field, String subField) {
        //System.debug('sObjectName '+sObjectName);
        LookupSearchResult result = new LookupSearchResult();
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName +' WHERE Id =:recordId LIMIT 10';
        List<sObject> searchResults = Database.query(strQuery);   
        if(searchResults != NUll && !searchResults.isEmpty()){
            sObject sObj = searchResults.get(0);
            LookupSearchResult res = new LookupSearchResult();
            result.Id = sObj.Id;
            result.title = String.valueOf(sObj.get(field));
            if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                result.subtitle = String.valueOf(sObj.get(subField));
            }else{
                result.subtitle = sObjectName;
            }
        }
        return result;        
    }
    
    public class LookupSearchResult {
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String subtitle{get;set;}
    }
}