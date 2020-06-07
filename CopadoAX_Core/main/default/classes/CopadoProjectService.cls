public class CopadoProjectService {
	
    //get a project Id based on the name
    public static copado__Project__c getProjectByName(String prjName){
        copado__Project__c prj = [
                SELECT
                        Id,
                        Name
                FROM copado__Project__c
                WHERE Name = :prjName
                LIMIT 1
        ];
        return prj;
    }
}