/**
 * Created by kheidt.
 */

public with sharing class CopadoUserStoryService {

    public static boolean hasApexCode = false;

    public static Map<Id, copado__User_Story__c> getUserStoriesToBePromoted(String projectId, String envId){
        Map<Id,copado__User_Story__c> stories = new Map<Id, copado__User_Story__c>([
                SELECT
                        Id,
                        Name,
                        copado__Environment__c,
                        copado__Org_Credential__c,
            			copado__Has_Apex_Code__c 
                FROM copado__User_Story__c
                WHERE
                        copado__Project__c = :projectId AND
                        copado__Environment__c = :envId AND
                        copado__Promote_Change__c = TRUE
        ]);

        return stories;
    }

    public static copado__User_Story__c getUserStory(String usId){
        copado__User_Story__c us = [
                SELECT
                        Id,
                        Name,
                        copado__Org_Credential__c,
                        copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__c,
                        copado__Project__r.copado__Deployment_Flow__r.copado__Static_Code_Analysis_Settings__c,
            			copado__Has_Apex_Code__c 
                FROM copado__User_Story__c
                WHERE Id = :usId
                LIMIT 1
        ];
        return us;
    }

    public static Map<Id, List<Id>> getStoriesFromPromotions(List<Id> promoIds){
        Map<Id,List<Id>> promotionStoriesMap = new Map<Id, List<Id>>();
        List<copado__Promoted_User_Story__c> pus = new List<copado__Promoted_User_Story__c>([
                SELECT Id, Name, copado__Promotion__c, copado__User_Story__c, copado__User_Story__r.copado__Has_Apex_Code__c
                FROM copado__Promoted_User_Story__c
                WHERE copado__Promotion__c IN :promoIds
        ]);

        for(copado__Promoted_User_Story__c pusItem : pus){
            if(promotionStoriesMap.get(pusItem.copado__Promotion__c) == null){
                promotionStoriesMap.put(pusItem.copado__Promotion__c, new List<Id>());
            }
            promotionStoriesMap.get(pusItem.copado__Promotion__c).add(pusItem.copado__User_Story__c);
            if(pusItem.copado__User_Story__r.copado__Has_Apex_Code__c){
                hasApexCode = true;
            }
        }

        return promotionStoriesMap;
    }
}