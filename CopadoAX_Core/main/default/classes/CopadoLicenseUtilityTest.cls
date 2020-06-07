@isTest
public class CopadoLicenseUtilityTest {
    
    private static CopadoLicenseUtility clu;
	private static User adminUser;
    private static User otherUser;
    private static Id copadoPermissionSet;
    
    private static void setUp(){
        //create admin user for creating running user
        adminUser = CopadoTestDataFactory.createAdminUser();
        insert adminUser;
        
        
        System.runAs(adminUser){            
            //get copado permission set
            copadoPermissionSet = CopadoTestDataFactory.getCopadoUserPermissionSet().Id;
            
            //assign permission set to user
            PermissionSetAssignment psa = new PermissionSetAssignment
                (
                    PermissionSetId = copadoPermissionSet, 
                    AssigneeId = adminUser.Id
                );
            insert psa;   
            
            otherUser = CopadoTestDataFactory.createStandardUser();
            insert otherUser;
            //assign permission set to user
            PermissionSetAssignment psao = new PermissionSetAssignment
                (
                    PermissionSetId = copadoPermissionSet, 
                    AssigneeId = otherUser.Id
                );
            insert psao; 
        }

    }
    
    
    public static testmethod void testAssignLicenseForTestRunAvailable(){
        
        setUp();
        
        clu = new CopadoLicenseUtility();
        clu.clic.availableCopadoLicenses = 1;
        System.runAs(adminUser){
            Test.startTest();
            
            copado.GlobalAPI.UserLicense ul = clu.assignLicenseForTestRun(adminUser.Id);    
                
            System.assertEquals(null, ul);
            
            clu.deleteLicenseForTestRun(adminUser.Id, ul);
            
            Test.stopTest();
        }
    }
    
    public static testmethod void testAssignLicenseForTestRunNotAvailable(){
        
        setUp();
        copado.GlobalAPI gapi = new copado.GlobalAPI();
        gapi.upsertCopadoLicense(otherUser.Id, new copado.GlobalAPI.UserLicense(otherUser.Id, false, false, false, true, false) );
        
        clu = new CopadoLicenseUtility();
        clu.clic.availableCopadoLicenses = 0;
        System.runAs(adminUser){
            Test.startTest();
            
            copado.GlobalAPI.UserLicense ul = clu.assignLicenseForTestRun(adminUser.Id);    
                
            System.assertNotEquals(null, ul);
            
            clu.deleteLicenseForTestRun(adminUser.Id, ul);

            Test.stopTest();
        }
    }
}