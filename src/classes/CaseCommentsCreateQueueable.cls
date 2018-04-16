/**
 * Created by jeremy.sparrell on 4/10/2018.
 */

public class CaseCommentsCreateQueueable implements Queueable{
    List<CaseComment> comments;

    public CaseCommentsCreateQueueable(List<CaseComment> caseComments){
        this.comments = caseComments;
    }

    public void execute(QueueableContext context){
        insert comments;
    }
}