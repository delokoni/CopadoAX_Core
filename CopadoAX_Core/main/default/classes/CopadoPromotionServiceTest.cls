/**
 * Due to the way salesforce works the test-class needs to run with ability to access actual salesforce data
 */

@IsTest
private class CopadoPromotionServiceTest {

    private static copado__Org__c sourceOrgCredential;
    private static copado__Org__c targetOrgCredential;
    private static copado__Environment__c sourceEnv;
    private static copado__Environment__c targetEnv;
    private static copado__Git_Repository__c repo;
    private static copado__Static_Code_Analysis_Settings__c scas;
    private static List<copado__Static_Code_Analysis_Rule__c> scars;
    private static copado__Deployment_Flow__c flow;
    private static copado__Project__c project;
    private static CopadoKeys__c oldProjectId;
    private static copado__User_Story__c userStory;
    private static Attachment att;
    private static User runningUser;
    private static User adminUser;
    private static Id copadoPermissionSet;
    private static copado.GlobalAPI.UserLicense restoreUser;
    private static CopadoLicenseUtility clu;


    private static void setUp(){
        //create admin user for creating running user
        adminUser = CopadoTestDataFactory.createAdminUser();
        insert adminUser;
        
        System.runAs(adminUser){
            //create running user
            runningUser = CopadoTestDataFactory.createStandardUser();
            runningUser.ProfileId = adminUser.ProfileId;
            insert runningUser;
            
            //get copado permission set
            copadoPermissionSet = CopadoTestDataFactory.getCopadoUserPermissionSet().Id;
            
            //assign permission set to user
            PermissionSetAssignment psa = new PermissionSetAssignment
                (
                    PermissionSetId = copadoPermissionSet, 
                    AssigneeId = runningUser.Id
                );
            insert psa;
            
            //assign copado licenses to running User
            clu = new CopadoLicenseUtility();
            
            //store the Id of the old user, as we need it to restore licenses later, if required.
            //it can be null. if null, an existing non used license was used.
            restoreUser = clu.assignLicenseForTestRun(runningUser.Id);
        }
        
        System.runAs(runningUser){
            sourceEnv = CopadoTestDataFactory.createEnvironment();
            sourceEnv.copado__Org_ID__c = sourceEnv.copado__Org_ID__c.left(17) + 'Z';
            insert sourceEnv;
            
            targetEnv = CopadoTestDataFactory.createEnvironment();
            targetEnv.Name = 'ProdUnitTest';
            targetEnv.copado__Org_ID__c = targetEnv.copado__Org_ID__c.left(17) + 'Y';
            insert targetEnv;
            
            sourceOrgCredential = CopadoTestDataFactory.createOrgCredential(sourceEnv);
            insert sourceOrgCredential;
            
            targetOrgCredential = CopadoTestDataFactory.createOrgCredential(targetEnv);
            insert targetOrgCredential;
            
            repo = CopadoTestDataFactory.createGitRepo();
            insert repo;
            
            scas = CopadoTestDataFactory.createStaticCodeAnalysisSettings();
            insert scas;
            
            scars = new List<copado__Static_Code_Analysis_Rule__c>();
            scars.add(CopadoTestDataFactory.createStaticCodeAnalysisRule(scas));
            insert  scars;
            
            flow = CopadoTestDataFactory.createDeploymentFlow(scas,repo);
            flow.copado__Active__c = false;
            insert flow;
            
            
            flow.copado__Active__c = true;
            system.debug(flow);
            update flow;
            
            copado__Deployment_Flow_Step__c dfs = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id,sourceEnv.Id, targetEnv.Id);
            insert dfs;
            
            project = CopadoTestDataFactory.createProject(flow);

            if(CopadoTestDataFactory.hasCopadoIntegration){
                // create setting record
                SObject setting = CopadoTestDataFactory.createIntegrationSetting();
                Type sType = Type.forName('Copado_Integration_Setting__c');
                Database.insertImmediate(setting);

                project = CopadoTestDataFactory.addIntegrationSetting(project, (String) setting.Id);

                insert project;
            } else{
                insert project;
            }
            
            userStory = CopadoTestDataFactory.createUserStory(project, sourceEnv, sourceOrgCredential);
            userStory.copado__Promote_Change__c = true;
            insert userStory;
            
            att = CopadoTestDataFactory.createUserStoryGitAttachment(userStory.Id);
            insert att;
            
            if(CopadoKeys__c.getInstance('CopadoApiKey') == null) {
                CopadoKeys__c cap = CopadoTestDataFactory.createApiKeyCustomSetting();
                insert cap;
            }
            
            if(CopadoKeys__c.getInstance('ProjectId') == null) {
                CopadoKeys__c cpk = CopadoTestDataFactory.createProjectIdCustomSetting(String.valueOf(project.Id));
                insert cpk;
            } else{
                oldProjectId = CopadoKeys__c.getInstance('ProjectId');
                oldProjectId.Value__c = project.Id;
                update oldProjectId;
            }
        }

    }

    static testMethod void testCreateForwardPromotion() {
        setUp();

        System.runAs(runningUser) {
            Test.startTest();
            copado__Promotion__c newpromotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);

            insert newpromotion;
            Test.stopTest();

            newpromotion = [SELECT Id, Name, copado__Source_Environment__c, copado__Destination_Environment__c, copado__Back_Promotion__c FROM copado__Promotion__c];
            System.debug('new promotion created: ' + newpromotion);
            System.assertEquals(false, newpromotion.copado__Back_Promotion__c);
            System.assertEquals(sourceEnv.Id, newpromotion.copado__Source_Environment__c);
            System.assertEquals(targetEnv.Id, newpromotion.copado__Destination_Environment__c);
        }
    }

    static testMethod void testGetPromotion(){
        setUp();

        System.runAs(runningUser){

            copado__Promotion__c promotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);
            insert promotion;

            Test.startTest();

            copado__Promotion__c thisPromotion = CopadoPromotionService.getPromotion(promotion.Id);

            Test.stopTest();

            System.assertEquals(promotion.Id, thisPromotion.Id);
        }
    }

    static testMethod void testCreateBackwardPromotion(){
        setUp();
        System.runAs(runningUser) {
            Test.startTest();
            copado__Promotion__c newpromotion = CopadoPromotionService.createBackPromotion(targetEnv.Id, project.Id);

            insert newpromotion;
            Test.stopTest();

            newpromotion = [SELECT Id, Name, copado__Source_Environment__c, copado__Destination_Environment__c, copado__Back_Promotion__c FROM copado__Promotion__c];
            System.debug('new promotion created: ' + newpromotion);

            System.assertEquals(true, newpromotion.copado__Back_Promotion__c);
            System.assertEquals(targetEnv.Id, newpromotion.copado__Destination_Environment__c);
        }
    }

    static testMethod void testAttachUserStoryToPromotionByProject(){
        setUp();
        System.runAs(runningUser) {

            copado__Promotion__c newpromotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);

            insert newpromotion;

            Test.startTest();
            List<copado__Promoted_User_Story__c> pus = CopadoPromotionService.attachUserStoriesBasedOnProject(newpromotion.Id);
            insert pus;

            Test.stopTest();

            pus = [SELECT Id, Name, copado__User_Story__c, copado__Promotion__c FROM copado__Promoted_User_Story__c];

            System.debug('those stories have been attached: ' + pus);
            //check if it has been correctly attached
            System.assertEquals(userStory.Id, pus[0].copado__User_Story__c);
        }
    }

    static testMethod void testAttachUserStoryToPromotionByByPromotion(){
        setUp();
        System.runAs(runningUser) {

            copado__Promotion__c oldPromotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);
            insert oldPromotion;

            copado__Promotion__c newpromotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);
            insert newpromotion;

            List<copado__Promoted_User_Story__c> pus = CopadoPromotionService.attachUserStoriesBasedOnProject(oldPromotion.Id);
            insert pus;

            Test.startTest();

            List<copado__Promoted_User_Story__c> newPus = CopadoPromotionService.attachStoriesFromPromotions(new List<Id>{oldPromotion.Id}, new List<Id>{newpromotion.Id});
            insert newPus;

            Test.stopTest();

            //check if it has been correctly attached
            System.assertEquals(pus.size(),newPus.size());
        }
    }

    static testMethod void testDeployPromotion(){
        setUp();

        CopadoWebhookCalloutMock calloutMock = new CopadoWebhookCalloutMock();
        calloutMock.mockCreatePromotionAndDeployCall();

        Test.setMock(HttpCalloutMock.class, calloutMock);


        System.runAs(runningUser) {

            copado__Promotion__c promotion = CopadoPromotionService.createForwardPromotion(sourceEnv.Id, project.Id);
            insert promotion;

            Test.startTest();
            CopadoPromotionService.deployPromotion(promotion.Id, Constants_Core.noTestRun, true,false);
            Test.stopTest();

            //check if it has been correctly attached
            System.assertEquals('2019', CopadoPromotionService.callResponse.getStatus() );
        }
    }
}