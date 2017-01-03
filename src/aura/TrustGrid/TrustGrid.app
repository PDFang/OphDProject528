<!--
 - Created by mohandaas.rangaswamy on 11/16/2016.
 -->
<aura:application description="TrustGrid" extends="force:slds" access="GLOBAL">
    <c:TrustGridContainer>
        <aura:set attribute="trustGridComponent">
            <c:TrustGridStatusComponent/>

        </aura:set>
        <aura:set attribute="mosScoreComponent">
            <p>MOS Score</p>
        </aura:set>
    </c:TrustGridContainer>

</aura:application>