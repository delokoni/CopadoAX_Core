/**
 * Created by kheidt on 2019-04-08.
 */

public class CopadoSnapshotCommitService {

    public String getLatestCommitOnStory(String usId){

        List<copado__User_Story_Commit__c> userStoryCommits = new List<copado__User_Story_Commit__c>();
        userStoryCommits = [
                SELECT
                        Id,
                        copado__Snapshot_Commit__c
                FROM
                        copado__User_Story_Commit__c
                WHERE
                        copado__User_Story__c = :usId
                ORDER BY
                        CreatedDate DESC
                LIMIT 1
        ];

        if(userStoryCommits.size() > 0) {
            return userStoryCommits[0].copado__Snapshot_Commit__c;
        } else{
            return null;
        }
    }
}