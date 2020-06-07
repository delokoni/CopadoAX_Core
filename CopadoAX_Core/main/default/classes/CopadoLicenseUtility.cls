public class CopadoLicenseUtility {
    
    // yes, coding towards testClass coverage is not a best practice, 
    // but as dependency injection is not used, we need to be able to manipulate those values in test classes in order to test exceptions
    @TestVisible copado.GlobalAPI.CopadoLicenses clic;
    @TestVisible List<copado.GlobalAPI.UserLicense> lwu;   
    @TestVisible List<copado.GlobalAPI.UserLicense> usersWithEnterprise = new List<copado.GlobalAPI.UserLicense>();
    @TestVisible copado.GlobalAPI copadoGlobalAPI;
    
    
    public CopadoLicenseUtility(){
        //instanciate license service and get the required information
        copadoGlobalAPI = new copado.GlobalAPI(); 
        clic = copadoGlobalAPI.getLicenseInformation();
        System.debug(clic); 
        
        lwu = copadoGlobalAPI.listCopadoLicenses();
        System.debug(lwu);
    }
    
    
    public copado.GlobalAPI.UserLicense assignLicenseForTestRun(Id testUserId){
        //check if there are non used licenses available
        if(this.getNumberOfAvailableEnterprise() > 0){
            //if unused licenses are available, just assign one to the run test user
            addLicenseToUser(testUserId, 'enterprise');
            return null;
        } else{
            //get users with enterprise licenses
            List<copado.GlobalAPI.UserLicense> enterpriseLicenses = this.getUsersWithEnterprise();
            
            copado.GlobalAPI.UserLicense enterpriseUser = enterpriseLicenses[0];
            
            //remove license from an existing user
            this.removeLicenseFromUser(enterpriseUser.userId);
            
            //assign it to test user
            this.addLicenseToUser(testUserId, 'enterprise');
            
            //provide Id for clean up later
            return enterpriseUser;
        }
    }
    
    public void deleteLicenseForTestRun(Id testUserId, copado.GlobalAPI.UserLicense restoreUserLicense){
 		
        if(restoreUserLicense == null){
            System.debug('will be deleted: ' + testUserId);
            this.removeLicenseFromUser(testUserId);
        } else{
            System.debug('will be deleted: ' + testUserId);
            System.debug('will be restored: ' + restoreUserLicense);
            
            this.removeLicenseFromUser(testUserId);
            copadoGlobalAPI.upsertCopadoLicense(restoreUserLicense.userId,restoreUserLicense);
        }
    }
    
    public Integer getNumberOfAvailableEnterprise(){
        
        //check how many enterprise licenses are available.
        Integer availableEnterprise = clic.availableCopadoLicenses;
        System.debug(availableEnterprise);
        return availableEnterprise;
    }
    
    public List<copado.GlobalAPI.UserLicense> getUsersWithEnterprise(){
        
        //check, which users have enterprise liense assigned
        
        //List<Id> usersWithEnterprise = new List<Id>();
        for(copado.GlobalAPI.UserLicense ul : lwu){
            if(ul.isCopadoEnabled){
                usersWithEnterprise.add(ul);
            }
        }
        System.debug(usersWithEnterprise);
        
        return usersWithEnterprise;
    }
    
    public Boolean removeLicenseFromUser(Id userId){
        System.debug('will be removed: ' + userId);
        return copadoGlobalAPI.deleteCopadoLicense(userId);
    }
    
    public copado.GlobalAPI.UserLicense addLicenseToUser(Id userId, String licenseType){
        //create a new license shell;
        copado.GlobalAPI.UserLicense UL = new copado.GlobalAPI.UserLicense(UserId,False,False,False,False,False);
        
        //provide licenses
        UL.isCADEnabled=false;
        UL.isCCHEnabled=false;
        UL.isCCMEnabled=false;
        UL.isCopadoEnabled = licenseType == 'enterprise' ? true:false;
        UL.isCSTEnabled =false;
        
        System.debug('will be added: ' + UL);        
        copadoGlobalAPI.upsertCopadoLicense(userID,UL);
        return UL;
    }
}