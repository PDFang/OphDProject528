public with sharing virtual class PullTFSItemsControllerBase {

  public FeatureCreateFromProjectBase pageController 
  { 
        get; 
        set
        {
            if (value != null)
            {
                pageController = value;
                pageController.setComponentController(this);
            }
        }
  }
    
}