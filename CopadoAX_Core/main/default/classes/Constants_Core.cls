/**
 * Created by kheidt on 2019-04-12.
 */

public with sharing class Constants_Core {

    public static final String webhookBase = 'https://copado.herokuapp.com';
    public static final String analyseStaticCodeBase = '/json/v1/webhook/analyseStaticCode/';
    public static final String deployPromotionBase= '/json/v1/webhook/promotions/';

    //apiKeys are security relevant, so if you store them outside of the page, please make sure only certain users can access it.
    //custom setting as it will change with each environment.
    public Static final String apiKey = CopadoKeys__c.getInstance('CopadoApiKey').Value__c;

    //test level strings
    // https://resources.docs.salesforce.com/sfdc/pdf/salesforce_migration_guide.pdf
    public static final String runAllTests = 'RunAllTestsInOrg';
    public static final String runSelectedTests = 'RunSpecifiedTests';
    public static final String runLocalTests = 'RunLocalTests';
    public static final String noTestRun = 'NoTestRun';

    public static final String successfulPromotionStatus = 'Completed';

    public static final String scratchOrgType = 'Scratch Org';

    //Deployment Parameters. this is important
    public static final String pauseDeploymentString = '@pauseDeploymentExecution';
}