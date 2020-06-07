/**
 * Created by kheidt on 2019-04-11.
 */

public class UserService {

    public User getUser(Id userId){
        User thisUser = new User();
        if(Utility.registry.get(userId)!= null){
            thisUser = (User) Utility.registry.get(userId);
        } else {
            thisUser = queryUser(userId);
            Utility.registry.put(userId, thisUser);
        }
        return thisUser;
    }

    public Profile getProfile(String profileName){
        if(Utility.registry.get(profileName)!= null){
            return (Profile) Utility.registry.get(profileName);
        } else{
            Profile thisProfile = queryProfile(profileName);
            Utility.registry.put(profileName, thisProfile);
            return thisProfile;
        }

    }

    /** queries and more stuff **/

    private Profile queryProfile(String profileName){
        return [
                SELECT
                        Id,
                        Name
                FROM
                        Profile
                WHERE
                        Name = :profileName
                LIMIT
                        1
        ];
    }

    private User queryUser(Id userId){
        return [
                SELECT
                        Id,
                        Name
                FROM
                        User
                WHERE
                        Id = :userId
        ];
    }
}