public class ContentVersionAlt {
    public List<ContentVersion> getContentVersions() {
        return [select id, Title, Description, FileType,
        Owner.Name, VersionNumber from ContentVersion
        Where IsLatest = true];
    }

}