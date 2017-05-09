public class XMCalloutException extends Exception {
        public Integer HttpStatusCode {get;set;}
        public String Reason {get;set;}
        public String Message {get;set;}
}