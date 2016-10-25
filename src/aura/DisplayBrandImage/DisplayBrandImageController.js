/**
 * Created by arnab.karsarkar on 10/17/2016.
 */
({
    doInit : function(component){
         var action = component.get("c.findBrandingImage");
         var url ='';
         action.setCallback(this, function(response) {
                            var state = response.getState();
                            if (state === 'SUCCESS'){

                                 console.log('response ==>' + response.getReturnValue());
                                 url = '$Resource.' + response.getReturnValue();
                                 // console.log('url ==>' + url);
                                  var profUrl = $A.get(url);
                                 // console.log('profUrl ==>' + profUrl);
                                   component.set("v.fileName", profUrl);

                                }
                             });

            $A.enqueueAction(action);


    }
})