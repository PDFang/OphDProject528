/**
 * Created by william.nelson on 11/28/2016.
 */

public with sharing class ProjectPeriodDate {

    private Date startDate;
    private Date endDate;

    public Date ProjectStart{
        get{return startDate;}
        set{endDate = value;}
    }

    public Date  ProjectEnd{
        get{return endDate;}
        set{endDate = value;}
    }

}