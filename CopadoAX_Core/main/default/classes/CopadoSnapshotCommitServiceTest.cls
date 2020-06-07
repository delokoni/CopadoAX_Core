/**
 * Created by kheidt on 2019-05-28.
 */

@IsTest
private class CopadoSnapshotCommitServiceTest {
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
    private static copado__Git_Backup__c gitSnapshot;
    private static copado__Git_Org_Commit__c snapshotCommit;
    private static copado__User_Story_Commit__c userStoryCommit;
    private static UserService userService = new UserService();


    private static void setUp(){
        //create admin user for creating running user
        adminUser = CopadoTestDataFactory.createAdminUser();
        insert adminUser;

        System.runAs(adminUser){
            //create running user
            runningUser = CopadoTestDataFactory.createStandardUser();
            runningUser.ProfileId = userService.getProfile('System Administrator').Id;
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

            scas = CopadoTestDataFactory.createStaticCodeAnalysisSettings();
            insert scas;

            scars = new List<copado__Static_Code_Analysis_Rule__c>();
            scars.add(CopadoTestDataFactory.createStaticCodeAnalysisRule(scas));
            insert  scars;

            repo = CopadoTestDataFactory.createGitRepo();
            insert repo;

            flow = CopadoTestDataFactory.createDeploymentFlow(scas,repo);
            flow.copado__Active__c = false;
            insert flow;

            flow.copado__Active__c = true;
            update flow;

            copado__Deployment_Flow_Step__c dfs = CopadoTestDataFactory.createDeploymentFlowStep(flow.Id,sourceEnv.Id, targetEnv.Id);
            insert dfs;

            gitSnapshot = CopadoTestDataFactory.createGitSnapshot(sourceOrgCredential, repo.Id, 'source');
            insert gitSnapshot;

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

            snapshotCommit = CopadoTestDataFactory.createSnapshotCommit(sourceOrgCredential,gitSnapshot);
            snapshotCommit.copado__Commit_Id__c = '1234567890';
            snapshotCommit.copado__Status__c = 'Complete';
            insert snapshotCommit;

            userStoryCommit = CopadoTestDataFactory.createUserStoryCommit(userStory,snapshotCommit);
            insert userStoryCommit;

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

    public static testMethod void testGetLatestCommitOnStory(){
        CopadoWebhookCalloutMock calloutMock = new CopadoWebhookCalloutMock();
        calloutMock.mockStaticCodeAnalysisCall();
        setUp();

        Test.setMock(HttpCalloutMock.class, calloutMock);


        Attachment scAtt = CopadoTestDataFactory.createSnapshotCommitAttachmentWithClasses(snapshotCommit.Id);
        insert scAtt;

        System.runAs(runningUser){

            CopadoSnapshotCommitService cscs = new CopadoSnapshotCommitService();
            Test.startTest();

            String storyCommitId = cscs.getLatestCommitOnStory( String.valueOf(userStory.Id) );

            Test.stopTest();

            copado__User_Story_Commit__c usc = [
                    SELECT Id, copado__User_Story__c, copado__Snapshot_Commit__c
                    FROM copado__User_Story_Commit__c

            ];

            System.assertEquals(usc.Id,userStoryCommit.Id);
        }
    }
}