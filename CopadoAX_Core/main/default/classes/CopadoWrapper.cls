/**
 * Created by kheidt on 14/03/2018.
 */

public class CopadoWrapper {

    public class MetadataItem {
        public String t;
        public String n;
        public String cmm;
    }

    public List<MetadataItem> att;


    public static CopadoWrapper parse(String json) {
        return (CopadoWrapper) System.JSON.deserialize(json, CopadoWrapper.class);
    }
}