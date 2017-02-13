/**
 * Created by mohandaas.rangaswamy on 2/13/2017.
 */
@isTest
global class PartnerCaseProxyServiceMockTest implements WebServiceMock{

    global void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {

        if(request instanceof PartnerCaseProxyService.CreatePartnerCase_element ){
            response.put('response_x', new PartnerCaseProxyService.CreatePartnerCaseResponse_element());
        }else if(request instanceof PartnerCaseProxyService.UpdatePartnerCase_element ){
            response.put('response_x', new PartnerCaseProxyService.UpdatePartnerCaseResponse_element());
        }

    }

}