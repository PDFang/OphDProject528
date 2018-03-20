/**
 * Created by mohandaas.rangaswamy on 3/12/2018.
 */

public class ThirdPartyTicketTriggerHandler extends TriggerHandler{

    protected override void afterInsert(){

        updateIncidentCase((List<Third_Party_Tickets__c>) trigger.new);
    }

    private void updateIncidentCase(List<Third_Party_Tickets__c> newList){

        Case[] incidents = new Case[]{};

        system.debug('updateIncidentCase(): newList - '+newList);

        for(Third_Party_Tickets__c ticket :newList){
            if(String.isNotBlank(ticket.Ticket_Number__c) && ticket.Case__c != null){
                Case incident = new Case(
                        Id = ticket.Case__c,
                        Apex_Bypass_Validations__c = true,
                        X3rdPartyVendorTicket__c = ticket.Ticket_Number__c
                );
                incidents.add(incident);
            }
        }

        system.debug('updateIncidentCase(): incidents - '+incidents);

        if(incidents.isEmpty()){
            return;
        }

        TriggerHandler.bypass('CaseTriggerHandler');
        try{
            update incidents;
        } catch (Exception ex){
            system.debug('updateIncidentCase(): Exception - '+ex);
            String subject = incidents[0].Id + ', Failed to update Ticket Number ' + incidents[0].X3rdPartyVendorTicket__c;
            inContactBaseClass.SendErrorEmail( ex, subject);
        }
        TriggerHandler.clearBypass('CaseTriggerHandler');

    }
}