public class KnownIsssuesScoreTemp implements iCalcKnownIssueScores {
    //using decimal return type for now 
    public Decimal DaysIssuePresent(DateTime oldestDate, integer multiplier){
        
        //>10=10, 7-9=7, 4-6=4, 1-3=0.25, 1=0
        DateTime startDate = DateTime.now();
        integer intDays =  startDate.Date().daysBetween(oldestDate.Date());
        
       
            if (intDays ==  1 ) 
                return 0 ;
            else if (intDays <  4 )
                return .25 * multiplier;
            else if (intDays <  7 ) 
                return 4 * multiplier;
            else if (intDays <  10 )
                return 7 * multiplier;
            else
                return 10 * multiplier;
        

    }
    public Decimal NumberIncidentsTiedToIssue(integer issueCount,  integer multiplier) {
        
			//>10=10, 7-9=7, 4-6=4, 1-3=1, 0=0
        	if (issueCount ==  0 ) 
                return 0 ;
            else if (issueCount <  4 )
                return 1 * multiplier;
            else if (issueCount <  7 ) 
                return 4 * multiplier;
            else if (issueCount <  10 )
                return 7 * multiplier;
            else
                return 10 * multiplier;
        
    }
    //not done
    public Decimal DollarAmountTiedToIssue(decimal accountSum,  integer multiplier) {
        //>=$5M=10, $3M-$5M=7, $2M-$3M=4, $1M-$2M=1, <=$0=0.00
        
       // if (accountSum ==  0.0 ) 
       //     return 0 ;
       // else if (accountSum <  4 )
       //     return 1 * multiplier;
       // else if (accountSum <  7 ) 
       //     return 4 * multiplier;
       // else if (accountSum <  10 )
       //     return 7 * multiplier;
       // else
       //     return 10 * multiplier;
  

     return 0;    
    }    
}