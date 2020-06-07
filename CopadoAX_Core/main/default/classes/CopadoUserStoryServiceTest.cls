/**
 * Created by kheidt.
 */

@IsTest
private class CopadoUserStoryServiceTest {

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
    
    static testmethod void testSetUp(){
        setUp();
    }

    static testMethod void testGetUserStory() {
        
        setUp();
        
        System.runAs(runningUser){
            Test.startTest();
            
            copado__User_Story__c us = CopadoUserStoryService.getUserStory(userStory.Id);
            
            Test.stopTest();
            
            System.assertEquals(userStory.Id, us.Id);
            
            //clean up license assignment. remove from run test user. assign to old user
            clu.deleteLicenseForTestRun(runningUser.Id, restoreUser);
        }

    }

    static testMethod void testGetPromotableUserStory(){
        setUp();
        System.runAs(runningUser){
            Test.startTest();
            Map<Id, copado__User_Story__c> uss = CopadoUserStoryService.getUserStoriesToBePromoted(project.Id, sourceEnv.Id);
            Test.stopTest();
            
            System.assertEquals(userStory.Id, uss.values()[0].Id);
            
            clu.deleteLicenseForTestRun(runningUser.Id, restoreUser);
        }
    }
}