public class MyIdeaListExtension {


    private final ApexPages.IdeaStandardSetController ideaSetController; 

    public MyIdeaListExtension (ApexPages.StandardSetController controller) {
        ideaSetController = (ApexPages.IdeaStandardSetController)controller;
    }

    public List<Idea> getModifiedIdeas() {
        Idea[] ideas = ideaSetController.getIdeaList();
        // modify ideas here
        return ideas;
    }
}