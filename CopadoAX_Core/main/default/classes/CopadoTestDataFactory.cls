/**
 * Created by kheidt.
 */

@IsTest
public class CopadoTestDataFactory {

    public static Boolean hasCopadoIntegration = checkForIntegrationField();
    public static UserService us = new UserService();

    public static copado__Environment__c createEnvironment(){
        copado__Environment__c env = new copado__Environment__c();
        env.Name = 'UnitTest';
        env.copado__Org_ID__c = UserInfo.getOrganizationId();
        env.copado__Type__c = 'Sandbox';
        env.copado__Minimum_Apex_Test_Coverage__c = 75.00;

        return env;
    }

    public static copado__Org__c createOrgCredential(copado__Environment__c env){
        copado__Org__c org = new copado__Org__c();
        org.Name = env.Name;
        org.copado__Environment__c = env.Id;
        org.copado__SFDC_Org_ID__c = env.copado__Org_ID__c + '_' + UserInfo.getUserId();
        org.copado__Org_Type__c = env.copado__Type__c;
        org.copado__Default_Credential__c = true;
        org.copado__Validated_Date__c = DateTime.now();
        return org;
    }

    public static copado__Git_Repository__c createGitRepo(){
        copado__Git_Repository__c repo = new copado__Git_Repository__c();
        repo.Name = 'UnitTestRepo';
        repo.copado__Git_Provider__c = 'Github';
        repo.copado__URI__c = 'git@github.com:testUser/testRepo.git';
        repo.copado__Branch_Base_URL__c = 'test/tree/';
        repo.copado__Commit_Base_URL__c = 'test/commit/';
        repo.copado__Pull_Request_Base_URL__c = 'test/pullRequest/';
        repo.copado__Tag_Base_URL__c = 'test/tag/';
        return repo;
    }

    public static copado__Static_Code_Analysis_Settings__c createStaticCodeAnalysisSettings(){
        copado__Static_Code_Analysis_Settings__c scas = new copado__Static_Code_Analysis_Settings__c();
        scas.Name = 'TestSCAS';
        return scas;
    }

    public static copado__Static_Code_Analysis_Rule__c createStaticCodeAnalysisRule(copado__Static_Code_Analysis_Settings__c scas){
        copado__Static_Code_Analysis_Rule__c scar = new copado__Static_Code_Analysis_Rule__c();
        scar.copado__Static_Code_Analysis_Settings__c = scas.Id;
        scar.copado__Rule_Name__c = 'AvoidSoqlInLoops';
        scar.copado__Message__c = 'Never put SOQL in loops. maybe sometimes. if you are sure.';
        scar.copado__Priority__c = '1';
        return scar;
    }

    public static copado__Deployment_Flow__c createDeploymentFlow(
            copado__Static_Code_Analysis_Settings__c scas,
            copado__Git_Repository__c repo
    ){
        copado__Deployment_Flow__c flow = new copado__Deployment_Flow__c();
        flow.Name = 'UnitTestFlow';
        flow.copado__Main_Branch__c = 'utMaster';
        flow.copado__Git_Repository__c = repo.Id;
        flow.copado__Static_Code_Analysis_Settings__c = scas.Id;
        flow.copado__Active__c = true;
        return flow;
    }

    public static copado__Project__c createProject(copado__Deployment_Flow__c flow){
        copado__Project__c project = new copado__Project__c();
        project.Name ='Unit Test Implementation';
        project.copado__Start_Date__c = Date.today().addDays(-1);
        project.copado__End_Date__c = Date.today().addYears(1);
        project.copado__Index_Metadata__c = true;
        project.copado__Status__c = 'In Progress';
        project.copado__Deployment_Flow__c = flow.Id;


        return project;
    }

    public static copado__Project__c addIntegrationSetting(copado__Project__c project, String settingId){
        if(hasCopadoIntegration) {
            project.put('Copado_Integration_Setting__c', settingId);
            project.put('Project_External_Id__c', 'UniTestEXTID');
        }
        return project;
    }

    public static SObject createIntegrationSetting(){
        SObject sobj;
        if(Schema.getGlobalDescribe().get('Copado_Integration_Setting__c') != null){
            sobj = Schema.getGlobalDescribe().get('Copado_Integration_Setting__c').newSObject();
        } else{
            sobj = Schema.getGlobalDescribe().get('CopadoAX__Copado_Integration_Setting__c').newSObject();
        }

        sobj.put('Name', 'Test Jira');
        sobj.put('External_System__c', 'JIRA');
        sobj.put('Named_Credential__c', 'JIRA_TESTF');

        return sobj;
    }

    public static copado__User_Story__c createUserStory (
            copado__Project__c project,
            copado__Environment__c env,
            copado__Org__c org
    ){
        copado__User_Story__c us = new copado__User_Story__c();
        us.copado__User_Story_Title__c = 'Unit Test US';
        us.copado__Promotion_Test_Level__c = 'NoTestRun';
        us.copado__Status__c = 'In Progress';
        us.copado__Org_Credential__c = org.Id;
        us.copado__Environment__c = env.Id; //line could be removed as it's filled by Copado after insert trigger anyway based on org cred
        us.copado__Project__c = project.Id;
        return us;
    }

    public static Attachment createUserStoryGitAttachment(String parentId){
        Attachment att = new Attachment();
        att.Name = 'Git MetaData';
        String bodyString =
                '[{"t":"ApexTrigger","n":"TestTrigger","cmm":"updated"},' +
                        '{"t":"ApexClass","n":"TestField","cmm":"updated"},' +
                        '{"t":"CustomField","n":"TestObject__c.TestField__c","cmm":"updated"},' +
                        '{"t":"CustomObject","n":"TestObject__c","cmm":"updated"}]';
        Blob bodyBlob = Blob.valueOf(bodyString);
        att.Body = bodyBlob;
        att.ParentId = parentId;
        return att;
    }

    public static Attachment createSnapshotCommitAttachmentWithClasses(String parentId){
        Attachment att = new Attachment();
        att.Name = 'MetaData';
        String bodyString = '[{"n":"MyObject__c","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-12-18","cb":"Konstantin Dev1 Heidt","r":false,"t":"SharingRules"},' +
            '{"n":"CustomLineItem__c","s":true,"d":"2018-12-10","b":"Konstantin Dev1 Heidt","cd":"2018-12-10","cb":"Konstantin Dev1 Heidt","r":false,"t":"SharingRules"},' +
            '{"n":"Test_Perm_Set","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-11-15","cb":"Konstantin Dev1 Heidt","r":false,"t":"PermissionSet"},' +
            '{"n":"Work%2Ecom Only User","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2017-11-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"Profile"},' +
                '{"n":"OpportunityTR","s":true,"d":"2017-12-05","b":"Konstantin Dev1 Heidt","cd":"2017-12-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"ApexTrigger"},' +
                '{"n":"AccountTR","s":true,"d":"2017-12-05","b":"Konstantin Dev1 Heidt","cd":"2017-12-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"ApexTrigger"},' +
                '{"n":"Utility","s":true,"d":"2017-12-22","b":"Konstantin Dev1 Heidt","cd":"2017-12-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"ApexClass"},' +
                '{"n":"TestDataFactory","s":true,"d":"2017-12-12","b":"Konstantin Dev1 Heidt","cd":"2017-12-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"ApexClass"},' +
                '{"n":"MyObject__c-MyObject Layout","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-12-18","cb":"Konstantin Dev1 Heidt","r":false,"t":"Layout"},' +
                '{"n":"Event-Event Layout","s":true,"d":"2017-12-22","b":"Konstantin Dev1 Heidt","cd":"2017-11-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"Layout"},' +
                '{"n":"Activity.This_is_a_Custom_Field__c","s":true,"d":"2017-12-22","b":"Konstantin Dev1 Heidt","cd":"2017-12-22","cb":"Konstantin Dev1 Heidt","r":false,"t":"CustomField"},' +
                '{"n":"CustomLineItem__c","s":true,"d":"2018-12-10","b":"Konstantin Dev1 Heidt","cd":"2018-12-10","cb":"Konstantin Dev1 Heidt","r":false,"t":"CustomObject"},' +
                '{"n":"EMEA_Director_Sales","s":true,"d":"2018-12-03","b":"Konstantin Dev1 Heidt","cb":"Konstantin Dev1 Heidt","r":false,"t":"Role"}]';
        Blob bodyBlob = Blob.valueOf(bodyString);
        att.Body = bodyBlob;
        att.ParentId = parentId;
        return att;
    }

    public static Attachment createSnapshotCommitAttachmentWithoutClasses(String parentId){
        Attachment att = new Attachment();
        att.Name = 'MetaData';
        String bodyString = '[{"n":"MyObject__c","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-12-18","cb":"Konstantin Dev1 Heidt","r":false,"t":"SharingRules"},' +
            '{"n":"CustomLineItem__c","s":true,"d":"2018-12-10","b":"Konstantin Dev1 Heidt","cd":"2018-12-10","cb":"Konstantin Dev1 Heidt","r":false,"t":"SharingRules"},' +
            '{"n":"Test_Perm_Set","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-11-15","cb":"Konstantin Dev1 Heidt","r":false,"t":"PermissionSet"},' +
            '{"n":"Work%2Ecom Only User","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2017-11-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"Profile"},' +
            '{"n":"MyObject__c-MyObject Layout","s":true,"d":"2018-12-18","b":"Konstantin Dev1 Heidt","cd":"2018-12-18","cb":"Konstantin Dev1 Heidt","r":false,"t":"Layout"},' +
            '{"n":"Event-Event Layout","s":true,"d":"2017-12-22","b":"Konstantin Dev1 Heidt","cd":"2017-11-05","cb":"Konstantin Dev1 Heidt","r":false,"t":"Layout"},' +
            '{"n":"Activity.This_is_a_Custom_Field__c","s":true,"d":"2017-12-22","b":"Konstantin Dev1 Heidt","cd":"2017-12-22","cb":"Konstantin Dev1 Heidt","r":false,"t":"CustomField"},' +
            '{"n":"CustomLineItem__c","s":true,"d":"2018-12-10","b":"Konstantin Dev1 Heidt","cd":"2018-12-10","cb":"Konstantin Dev1 Heidt","r":false,"t":"CustomObject"},' +
            '{"n":"EMEA_Director_Sales","s":true,"d":"2018-12-03","b":"Konstantin Dev1 Heidt","cb":"Konstantin Dev1 Heidt","r":false,"t":"Role"}]';
        Blob bodyBlob = Blob.valueOf(bodyString);
        att.Body = bodyBlob;
        att.ParentId = parentId;
        return att;
    }

    public static CopadoKeys__c createApiKeyCustomSetting(){
        CopadoKeys__c cap = new CopadoKeys__c();
        cap.Name = 'CopadoApiKey';
        cap.Value__c = '1234567890';
        return cap;
    }

    public static CopadoKeys__c createProjectIdCustomSetting(Id projectId){
        CopadoKeys__c cpk = new CopadoKeys__c();
        cpk.Name = 'ProjectId';
        cpk.Value__c = projectId;
        return cpk;
    }

    public static copado__Deployment_Flow_Step__c createDeploymentFlowStep(Id flow, Id source, Id target){
        copado__Deployment_Flow_Step__c dfs = new copado__Deployment_Flow_Step__c();
        dfs.copado__Source_Environment__c = source;
        dfs.copado__Destination_Environment__c = target;
        dfs.copado__Branch__c = 'unitTest';
        dfs.copado__Deployment_Flow__c = flow;

        return dfs;
    }
    
    public static copado__Git_Backup__c createGitSnapshot(copado__Org__c oc, String repoId, String branch){
        copado__Git_Backup__c gs = new copado__Git_Backup__c();
        gs.Name = oc.Name;
        gs.copado__Git_Repository__c = repoId;
        gs.copado__Org__c = oc.Id;
        gs.copado__Branch__c = branch;
        gs.copado__Git_Snapshot_Permissions__c = 'Allow Commits Only';
    	return gs;
    }

    public static copado__Git_Org_Commit__c createSnapshotCommit(copado__Org__c orgCred, copado__Git_Backup__c snapshot){
        copado__Git_Org_Commit__c goc = new copado__Git_Org_Commit__c();
        goc.copado__Org__c = orgCred.Id;
        goc.copado__Git_Backup__c = snapshot.Id;
        //goc.copado__Git_Operation__c = 'Commit Files';
        goc.copado__Commit_Date__c = Date.today();
        goc.copado__Status__c = 'Complete';
        return goc;
    }

    public static copado__User_Story_Commit__c createUserStoryCommit(copado__User_Story__c story, copado__Git_Org_Commit__c snapshotCommit){
        copado__User_Story_Commit__c usc = new copado__User_Story_Commit__c();
        usc.copado__User_Story__c = story.Id;
        usc.copado__Snapshot_Commit__c = snapshotCommit.Id;
        usc.Name = String.valueOf(Date.today());
        usc.copado__External_Id__c = story.Id + '_' + snapshotCommit.Id;
        return usc;
    }

    public static copado__Deployment__c createDeployment(
            Id sourceOrgId
    ){
        copado__Deployment__c dpl = new copado__Deployment__c();
        dpl.copado__From_Org__c = sourceOrgId;
        dpl.Name = 'Unit Test Deployment';
        return dpl;
    }

    public static copado__Destination_Org__c createDesticationOrgs(Id deploymentId, Id toOrgCredId){
        copado__Destination_Org__c dorg = new copado__Destination_Org__c();

        dorg.copado__Deployment__c = deploymentId;
        dorg.copado__To_Org__c = toOrgCredId;

        return dorg;
    }

    public static copado__Promotion__c createForwardPromotion(Id projectId, Id sourceEnvId, Id targetEnvId){
        copado__Promotion__c prom = new copado__Promotion__c();

        prom.copado__Project__c = projectId;
        prom.copado__Source_Environment__c = sourceEnvId;
        prom.copado__Destination_Environment__c = targetEnvId;

        return prom;
    }

    public static List<copado__Promoted_User_Story__c> createPromotedUserStories(Id promotionId, List<Id> storyIds){
        List<copado__Promoted_User_Story__c> pus = new List<copado__Promoted_User_Story__c>();

        for(Id uid : storyIds){
            copado__Promoted_User_Story__c pu = new copado__Promoted_User_Story__c();
            pu.copado__User_Story__c = uid;
            pu.copado__Promotion__c = promotionId;
            pus.add(pu);
        }

        return pus;
    }
    
    public static User createAdminUser(){
        Profile adminProfile = us.getProfile('System Administrator');
        User newUser = new User();
        newUser.ProfileId = adminProfile.Id;
        newUser.FirstName = 'Alois';
        newUser.LastName = 'Admin';
        newUser.email = 'admin@aa.test';
        newUser.Username = 'admin@aa.test';
        newUser.Alias = 'tadmin';
        newUser.CommunityNickname = 'tadmin';
        newUser.LocaleSidKey = 'es_ES';
        newUser.emailencodingkey='UTF-8';
        newUser.languagelocalekey='en_US';
        newUser.TimeZoneSidKey='Europe/Rome';
        return newUser;
    }
    
    public static User createStandardUser(){
        Profile standardProfile = us.getProfile('Standard User');
        User newUser = new User();
        newUser.ProfileId = standardProfile.Id;
        newUser.FirstName = 'Steven';
        newUser.LastName = 'Standard';
        newUser.email = 'standard@aa.test';
        newUser.Username = 'standard@aa.test';
        newUser.Alias = 'tandard';
        newUser.CommunityNickname = 'tstand';
        newUser.LocaleSidKey = 'es_ES';
        newUser.emailencodingkey='UTF-8';
        newUser.languagelocalekey='en_US';
        newUser.TimeZoneSidKey='Europe/Rome';
        
        return newUser;
    }
    
    public static PermissionSet getCopadoUserPermissionSet(){
        return [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
    }

    public static Account createAccount(String name){
        Account acct = new Account();
        acct.Name = name;

        return acct;
    }

    public static Opportunity createOppty(Account acct, String name){
        Opportunity oppty = new Opportunity();
        oppty.Name = name;
        oppty.AccountId = acct.Id;
        oppty.StageName = 'Qualification';
        oppty.CloseDate = Date.today() + 30;

        return oppty;
    }

    public static Boolean checkForIntegrationField(){
        Schema.DescribeSObjectResult dsr = copado__Project__c.getSObjectType().getDescribe();
        Map<String,Schema.SObjectField> dfr = Schema.sObjectType.copado__Project__c.fields.getMap();

        if(
                dfr.containsKey('Copado_Integration_Setting__c') ||
                dfr.containsKey('copado_integration_setting__c') ||
                dfr.containsKey('CopadoAX__Copado_Integration_Setting__c') ||
                dfr.containsKey('copadoax__copado_integration_setting__c')
        ){
            return true;
        } else{
            return false;
        }
    }

}