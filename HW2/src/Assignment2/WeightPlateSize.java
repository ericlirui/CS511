package Assignment2;

import java.util.*;


public enum WeightPlateSize {
    SMALL_3KG, MEDIUM_5KG, LARGE_10KG;

    private static final List<WeightPlateSize> VALUES =
            Collections.unmodifiableList(Arrays.asList(values()));
    private static final int SIZE = VALUES.size();
    private static final Random RANDOM = new Random();

    public static WeightPlateSize randomWeightPlate()  {
        return VALUES.get(RANDOM.nextInt(SIZE));
    }
}


