public interface iCalcKnownIssueScores { 
    
    Decimal DaysIssuePresent(DateTime oldestDate, integer multiplier); 
	Decimal NumberIncidentsTiedToIssue (integer issueCount,  integer multiplier);
    Decimal DollarAmountTiedToIssue(decimal accountSum,  integer multiplier);
}