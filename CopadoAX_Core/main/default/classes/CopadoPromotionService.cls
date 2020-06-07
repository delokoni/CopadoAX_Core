/**
 * Created by kheidt on 17/04/2018.
 * to invoque a promotion deployment through another apex class: CopadoPromotionService.createAndDeployForwardPromotion('NameOfEnvironment', 'NameOfProject');
 * to invoque a promotion validation through another apex class: CopadoPromotionService.createAndValidateForwardPromotion('NameOfEnvironment', 'NameOfProject');
 */

public with sharing class CopadoPromotionService {

    public static copado__Promotion__c queriedPromotion = new copado__Promotion__c();
    public static HttpResponse callResponse;
   	public static Boolean hasApexCode = false;
    
    //create the promotion, but do not attach any stories
    public static copado__Promotion__c createForwardPromotion(
            Id sourceEnvId,
            Id projectId
    ){
        copado__Promotion__c promotion = new copado__Promotion__c();
        promotion.copado__Project__c = projectId;
        promotion.copado__Source_Environment__c = sourceEnvId;
        return promotion;
    }

    //create the promotion backwards, but do not attach any stories
    public static copado__Promotion__c createBackPromotion(
            Id targetEnvId,
            Id projectId
    ){
        copado__Promotion__c promotion = new copado__Promotion__c();
        promotion.copado__Back_Promotion__c = true;
        promotion.copado__Project__c = projectId;
        promotion.copado__Destination_Environment__c = targetEnvId;
        return promotion;
    }

    public static List<copado__Promotion__c> createBackwardPromotions(
            List<Id> targetEnvironments,
            Id projectId
    ){
        List<copado__Promotion__c> promotions = new List<copado__Promotion__c>();
        for(Id envID : targetEnvironments){
            promotions.add(createBackPromotion(envID, projectId));
        }
        return promotions;
    }

    public static List<copado__Promoted_User_Story__c> attachStoriesFromPromotions(
            List<Id> finishedPromotionId,
            List<Id> newPromotionIds
    ){
        Set<Id> uniqueset = new Set<Id>(finishedPromotionId);
        uniqueset.addAll(newPromotionIds);
        Map<Id, List<Id>> promotionStoryIdMap = CopadoUserStoryService.getStoriesFromPromotions(new List<Id>(uniqueset));

        //equalize the list
        Set<Id> uniqueStoryIds = convertIdMapToSet(promotionStoryIdMap);
        System.debug('there will be the following number of stories in the new promotions' + uniqueStoryIds.size());

        //create promoted user story records
        List<copado__Promoted_User_Story__c> newPus = new List<copado__Promoted_User_Story__c>();
        for(Id pId : newPromotionIds){
            for(Id usId : uniqueStoryIds){
                newPus.add(new copado__Promoted_User_Story__c(
                        copado__User_Story__c = usId,
                        copado__Promotion__c = pId
                ));
            }
        }
        return newPus;
    }

    //attach stories to an existing promotion
    public static List<copado__Promoted_User_Story__c>  attachUserStoriesBasedOnProject(
            String promId
    ){
        copado__Promotion__c promotion = getPromotion(promId);
        Map<Id, copado__User_Story__c> stories = CopadoUserStoryService.getUserStoriesToBePromoted(
                promotion.copado__Project__c,
                promotion.copado__Source_Environment__c
        );
        Set<Id> storyIds = stories.keySet();
        
		Boolean listHasApexCode = false;
        List<copado__Promoted_User_Story__c> pus = new List<copado__Promoted_User_Story__c>();
        for(Id sid:storyIds){
            pus.add(new copado__Promoted_User_Story__c(
                    copado__User_Story__c = sid,
                    copado__Promotion__c = promotion.Id
            ));
            
            //check if some stories have classes to set the test level accordingly later on
            if(stories.get(sid).copado__Has_Apex_Code__c == true){
                listHasApexCode = true;
            }            
        }
        
      	hasApexCode = listHasApexCode;
        
        return pus;
    }

    public static copado__Promotion__c getPromotion(String promId){
        if(queriedPromotion == null || queriedPromotion.Id != promId){
            queriedPromotion = [
                    SELECT
                            Id,
                            Name,
                            copado__Source_Environment__c,
                            copado__Source_Environment__r.Name,
                            copado__Source_Org_Credential__c,
                            copado__Destination_Environment__c,
                            copado__Destination_Environment__r.Name,
                            copado__Destination_Org_Credential__c,
                            copado__Project__c,
                            copado__Project__r.copado__Deployment_Flow__c,
                            copado__Release__c,
                            copado__Back_Promotion__c
                    FROM
                            copado__Promotion__c
                    WHERE Id = :promId
            ];
        }
        return queriedPromotion;
    }

    //deploy an existing promotion with a webhook
    @future(callout=true)
    public static void deployPromotion(
            String promId,
            String testLevel,
            Boolean isValidation,
            Boolean stopExecution
    ){
        copado__Promotion__c promotion = CopadoPromotionService.getPromotion(promId);

        String deploymentName = 'deploymentName=AutoDeployFrom'+promotion.copado__Source_Environment__r.Name + 'To' +promotion.copado__Destination_Environment__r.Name;
        if(stopExecution == true){
            System.debug('deployment should be paused before start');
            deploymentName += Constants_Core.pauseDeploymentString;
        }
        String urlBase = Constants_Core.webhookBase + Constants_Core.deployPromotionBase;
        String testParameter = 'testLevel=' + testLevel;
        String apiKeyParameter = 'api_key=' + Constants_Core.apiKey;
        String validationParameter = 'checkOnly=' + String.valueOf(isValidation);

        String hookURL = urlBase;
        hookURL += promotion.Id + '/process';
        hookURL += '?' + validationParameter;
        hookURL += '&' + testParameter;
        hookURL += '&' + apiKeyParameter;
        hookURL += '&' + deploymentName;

        System.debug('webhook URL: ' + hookURL);
        System.debug('will we stop deployment? ' + stopExecution);
        callResponse = CopadoWebhookService.callWebhook('POST', hookURL, null);
        System.debug(callResponse);
        //return promotion;
    }

    /** helpers **/
    Public static Set<Id> convertIdMapToSet(Map<Id, List<Id>> inputMap ){
        Set<Id> uniqueStoryIds = new Set<Id>();
        for(List<Id> usIdList : inputMap.values()){
            for(Id usId : usIdList){
                uniqueStoryIds.add(usId);
            }
        }
        return uniqueStoryIds;
    }

}