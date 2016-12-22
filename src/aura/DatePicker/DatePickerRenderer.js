/**
 * Created by arnab.karsarkar on 12/21/2016.
 */
({
    afterRender: function() {
        return this.superAfterRender();
    },

    rerender: function(component, helper) {
        helper.renderGrid(component);
        this.superRerender();
    }
}