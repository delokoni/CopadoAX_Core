/**
 * Created by kheidt on 2019-05-28.
 */
@istest
public with sharing class CopadoProjectServiceTest {
    private static copado__Org__c sourceOrgCredential1;
    private static copado__Org__c sourceOrgCredential2;
    private static copado__Org__c sourceOrgCredential3;
    private static copado__Org__c targetOrgCredential;
    private static copado__Environment__c sourceEnv1;
    private static copado__Environment__c sourceEnv2;
    private static copado__Environment__c sourceEnv3;
    private static copado__Environment__c targetEnv;
    private static copado__Git_Repository__c repo;
    private static copado__Static_Code_Analysis_Settings__c scas;
    private static List<copado__Static_Code_Analysis_Rule__c> scars;
    private static copado__Deployment_Flow__c flow;
    private static copado__Project__c project;
    private static CopadoKeys__c oldProjectId;
    private static copado__User_Story__c userStory1;
    private static copado__User_Story__c userStory2;
    private static Attachment att1;
    private static Attachment att2;
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
            sourceEnv1 = CopadoTestDataFactory.createEnvironment();
            sourceEnv1.copado__Org_ID__c = sourceEnv1.copado__Org_ID__c.left(17) + 'W';
            sourceEnv1.Name += '1';
            insert sourceEnv1;

            sourceEnv2 = CopadoTestDataFactory.createEnvironment();
            sourceEnv2.copado__Org_ID__c = sourceEnv2.copado__Org_ID__c.left(17) + 'X';
            sourceEnv2.Name += '2';
            insert sourceEnv2;

            sourceEnv3 = CopadoTestDataFactory.createEnvironment();
            sourceEnv3.copado__Org_ID__c = sourceEnv3.copado__Org_ID__c.left(17) + 'Y';
            sourceEnv3.Name += '3';
            insert sourceEnv3;

            targetEnv = CopadoTestDataFactory.createEnvironment();
            targetEnv.Name = 'ProdUnitTest';
            targetEnv.copado__Org_ID__c = targetEnv.copado__Org_ID__c.left(17) + 'Z';
            insert targetEnv;

            sourceOrgCredential1 = CopadoTestDataFactory.createOrgCredential(sourceEnv1);
            insert sourceOrgCredential1;

            sourceOrgCredential2 = CopadoTestDataFactory.createOrgCredential(sourceEnv2);
            insert sourceOrgCredential2;

            sourceOrgCredential3 = CopadoTestDataFactory.createOrgCredential(sourceEnv3);
            insert sourceOrgCredential3;

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

            copado__Deployment_Flow_Step__c dfs1 = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id,sourceEnv1.Id, targetEnv.Id);
            dfs1.copado__Branch__c = 'dev1';
            dfs1.copado__Destination_Branch__c = 'uat';
            dfs1.copado__Destination_Environment__c = targetEnv.Id;
            insert dfs1;

            copado__Deployment_Flow_Step__c dfs2 = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id,sourceEnv2.Id, targetEnv.Id);
            dfs2.copado__Branch__c = 'dev2';
            dfs1.copado__Destination_Branch__c = 'uat';
            dfs1.copado__Destination_Environment__c = targetEnv.Id;
            insert dfs2;

            copado__Deployment_Flow_Step__c dfs3 = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id,sourceEnv3.Id, targetEnv.Id);
            dfs3.copado__Branch__c = 'dev3';
            dfs1.copado__Destination_Branch__c = 'uat';
            dfs1.copado__Destination_Environment__c = targetEnv.Id;
            insert dfs3;

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

            userStory1 = CopadoTestDataFactory.createUserStory(project, sourceEnv1, sourceOrgCredential1);
            userStory1.copado__Promote_Change__c = true;
            insert userStory1;

            userStory2 = CopadoTestDataFactory.createUserStory(project, sourceEnv1, sourceOrgCredential1);
            userStory2.copado__Promote_Change__c = true;
            insert userStory2;

            att1 = CopadoTestDataFactory.createUserStoryGitAttachment(userStory1.Id);
            insert att1;

            att2 = CopadoTestDataFactory.createUserStoryGitAttachment(userStory2.Id);
            insert att2;

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

    public static testMethod void testGetProjectByName(){
        setUp();

        System.runAs(runningUser){
            Test.startTest();

            copado__Project__c prj = CopadoProjectService.getProjectByName(project.Name);

            Test.stopTest();

            System.assertEquals(project.Id,prj.Id);
        }
    }
}