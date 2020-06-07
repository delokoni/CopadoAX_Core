/**
 * Created by kheidt on 2019-04-11.
 */

@isTest
public class UserServiceTest {

    private static User adminUser;
    private static User runningUser;

    private static void setup(){
        adminUser = CopadoTestDataFactory.createAdminUser();
        insert adminUser;

        System.runAs(adminUser){
            runningUser = CopadoTestDataFactory.createStandardUser();
            insert runningUser;
        }
    }

    public static testMethod void getProfile(){
        setup();

        UserService us = new UserService();
        Test.startTest();
        Profile adm = us.getProfile('System Administrator');
        Profile std = us.getProfile('Standard User');

        Test.stopTest();

        System.assertNotEquals(null, adm.Id);
        System.assertNotEquals(null, std.Id);
        System.assertNotEquals(adm.Id, std.Id);
    }

    public static testmethod void testGetCurrentUser(){
		setup();

        UserService us = new UserService();

        Test.startTest();
        System.debug(adminUSer);
        User usrAdmin = us.getUser(adminUser.Id);
        User usrStandard = us.getUser(runningUser.Id);

        Test.stopTest();

        System.assertEquals(adminUser.Id, usrAdmin.Id);
        System.assertEquals(runningUser.Id, usrStandard.Id);
        List<Account> accounts = new List<Account>();
    }
}