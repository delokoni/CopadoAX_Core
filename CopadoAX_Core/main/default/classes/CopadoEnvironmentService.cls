public class CopadoEnvironmentService {
	
    //get an environment Id based on the name
    public static copado__Environment__c getEnvironementByName(String envName){
        copado__Environment__c env = [
                SELECT
                        Id,
                        Name,
            			copado__Org_ID__c
                FROM copado__Environment__c
                WHERE Name = :envName AND
                copado__Type__c != :Constants_Core.scratchOrgType

                LIMIT 1
        ];
        return env;
    }
    
    //get an environment based on the external Id; 18 digits
    public static copado__Environment__c getEnvironmentByOrgId(String orgId){
        copado__Environment__c env = [
                SELECT
                        Id,
                        Name,
            			copado__Org_ID__c 
                FROM copado__Environment__c
                WHERE Id IN (
                        SELECT copado__Environment__c
                        FROM copado__Org__c
                        WHERE Id = :orgId
                ) AND
                copado__Type__c != :Constants_Core.scratchOrgType

                LIMIT 1
        ];
        return env;
    }

    //get an environment based on the external Id; 18 digits
    public static copado__Environment__c getEnvironmentBySFOrgId(String orgId){
        copado__Environment__c env = [
                SELECT
                        Id,
                        Name,
            			copado__Org_ID__c
                FROM copado__Environment__c
                WHERE copado__Org_ID__c = :orgId AND
                copado__Type__c != :Constants_Core.scratchOrgType

                LIMIT 1
        ];
        return env;
    }
}