/**
 * Created by william.nelson on 10/16/2017.
 */

public class AllCommentTriggerHelper {

    private static boolean alreadyCreatedComments = false;


    public static boolean hasAlreadyCreatedComments() {
        return alreadyCreatedComments;
    }

    // By setting the variable to true, it maintains this
    // new value throughout the duration of the request
    // (or testMethod)

    public static void setAlreadyCreatedComments() {
        alreadyCreatedComments = true;
    }

}