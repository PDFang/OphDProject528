public with sharing virtual class FeatureCreateFromProjectBase {
    
  private PullTFSItemsControllerBase componentBase;
	
  public virtual PullTFSItemsControllerBase getComponentController() {
    return componentBase;
  }

  public virtual void setComponentController(PullTFSItemsControllerBase compController) {
    componentBase = compController;
  }
	
  public FeatureCreateFromProjectBase getThis() {
    return this;
  }
    
}