<aura:application access="GLOBAL" >
  <ltng:require styles="/resource/slds213/assets/styles/salesforce-lightning-design-system-ltng.css"/>
     <ltng:require styles="{!$Resource.slds213 +
			'/assets/styles/salesforce-lightning-design-system-ltng.css'}"/>


	<!--<aura:dependency resource="c:CanvasAppTest"/>-->
<!--<c:TrustGridStatusComponent /> -->
   <!--<c:FullCalendar /> -->

  <!--&lt;!&ndash;  <div class="slds sldsCustom">
        <div class="slds-form">

            <c:DatePicker label="Test Date" placeholder="Enter a Date" formatSpecifier="MM/dd/yyyy" />

        </div>
    </div> -->
    <!--<c:FullCalendar />-->

    <c:CreateTFSWorkItemComp/>
</aura:application>