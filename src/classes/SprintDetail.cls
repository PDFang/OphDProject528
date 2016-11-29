/**
 * Created by william.nelson on 11/21/2016.
 */

public with sharing class SprintDetail {

    private Date startDate;
    private Date endDate;
    private string label;


    public Date SprintStart{
        get{return startDate;}
        set{endDate = value;}
    }

    public Date  SprintEnd{
        get{return endDate;}
        set{endDate = value;}
    }

    public Date  SprintLabel{
        get{return endDate;}
        set{endDate = value;}
    }

}