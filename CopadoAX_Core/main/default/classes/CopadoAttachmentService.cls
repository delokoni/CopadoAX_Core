/**
 * Created by kheidt.
 */

public  class CopadoAttachmentService {

    public static List<CopadoWrapper.MetadataItem> usa_items = new List<CopadoWrapper.MetadataItem>();
    public static List<CopadoSnapshotCommitWrapper.MetadataItem> sca_items = new List<CopadoSnapshotCommitWrapper.MetadataItem>();

    public List<String> getApexClassesFromUserStoryAttachments(String usId){

        List<Attachment> attachments = this.getAttachments(usId, 'Git MetaData');

        Set<String> gitClasses = new Set<String>();

        if(!attachments.isEmpty()) {

            String attBody = this.prepareAttachmentForParsing(attachments);
            CopadoWrapper cw = CopadoWrapper.parse(attBody);

            System.debug('git Metadata: ' + cw);
            for(CopadoWrapper.MetadataItem mi : cw.att){
                if(mi.t == 'ApexClass' || mi.t == 'ApexTrigger'){
                    gitClasses.add(mi.n);
                    usa_items.add(mi);
                }
            }
        } else{
            return null;
        }
        return new List<String>(gitClasses);
    }

    public List<String> getApexClassesFromSnapshotCommitAttachments(String scId){
        List<Attachment> attachments = this.getAttachments(scId, 'MetaData');
        Set<String> gitClasses = new Set<String>();

        if(!attachments.isEmpty()){
            String attBody = this.prepareAttachmentForParsing(attachments);
            CopadoSnapshotCommitWrapper cscw = CopadoSnapshotCommitWrapper.parse(attBody);

            System.debug('git Metadata from snapshot commit: ' + cscw);
            for(CopadoSnapshotCommitWrapper.MetadataItem mi : cscw.att){
                if(mi.t == 'ApexClass' || mi.t == 'ApexTrigger'){
                    gitClasses.add(mi.n);
                    sca_items.add(mi);
                }
            }
        }
        return new List<String>(gitClasses);
    }

    private List<Attachment> getAttachments(String parentID, String attName){
        List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE Name = :attName AND ParentId = :parentID];

        return attachments;
    }

    private String prepareAttachmentForParsing(List<Attachment> attachments){
        String attBody = '{ \"att\": ' + attachments[0].Body.toString() + '}';
        System.debug('attachment: ' + attBody);
        return attBody;
    }
}