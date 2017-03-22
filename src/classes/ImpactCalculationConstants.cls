public class ImpactCalculationConstants {

    public enum ImpactScoreType {
        AccountNetScore,
        IncidentNetScore,
        GainsightNetScore
    }

   public static final Set<String> recordTypes = new Set<String>{
            'Customers',
            'Resell Customers',
            'Resell Partner'
    };
}