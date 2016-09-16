public class DashboardReportsController 
{

        private DashboardReportControl__c drc;
        public String reportName;

        public DashboardReportsController()
        {
                reportName = URL.getCurrentRequestUrl().getPath().replace('/apex/','');
                drc = [Select ReportURL__c, Width__c, AltText__c FROM DashboardReportControl__c WHERE Name = :reportName];
        }
        
        public String ReportURL
        {
                get
                {
                        
                        return drc.ReportURL__c;               
                        
                }
        }
    
        public Double ReportWidth
        {
                get
                {
                        
                        return drc.Width__c;               
                        
                }
        }
    
        public String ReportAltText
        {
                get
                {
                        
                        return drc.AltText__c;               
                        
                }
        }

}