<!--
 - Created by arnab.karsarkar on 12/16/2016.
 -->

<aura:application description="ProjectLookupApp">
    <aura:attribute name="id" type="String" default="" access="GLOBAL"/>
    <aura:attribute name="objNew" type="Contact" default="{'sobjectType':'Contact',
                                                       'Id':null}" />

    <div class="well">
        <div class="page-header">
            <h1>Arnab's mAgIc<small> Lookup</small></h1>
        </div>

        <p>Search for Projects</p>

        <div class="panel panel-primary" style="width:60%">
            <div class="panel-heading">Existent sobject</div>
            <div class="panel-body">
                <div class="form-horizontal" >
                    <div class="form-group">
                        <label class="col-sm-2 control-label">Project</label>
                        <div class="col-sm-8">
                            <c:ProjectLookupComp type="Project__c"
                                           value="{!v.id}"
                                           className="form-control "/>
                        </div>
                    </div>
                    <div class="form-group has-feedback">
                        <label class="col-sm-2 control-label">Loaded Project Id</label>
                        <div class="col-sm-8 ">
                            <ui:inputText value="{!v.id}"
                                          class="form-control"
                                          placeholder="Change id value"/>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        </div>

</aura:application>
