package Assignment2;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import static Assignment2.WeightPlateSize.*;

public class Exercise {
    private ApparatusType at;
    private Map<WeightPlateSize,Integer> weight;
    private int duration;
    private static final int TIME_INTERVAL = 2;
    private static final int WEIGHT_PLATE_BOUND = 11;

    public Exercise(ApparatusType at, Map<WeightPlateSize, Integer> weight, int duration){
            this.at = at;
            this.weight = weight;
            this.duration = duration;
    }

    public ApparatusType getAt(){
        return this.at;
    }

    public Map<WeightPlateSize,Integer> getWeight(){
        return weight;
    }

    public int getDuration(){

        return this.duration;
    }

    public static Exercise generateRandom(){

        ApparatusType at = ApparatusType.randomApparatus();

        Map<WeightPlateSize, Integer> weight = new HashMap<WeightPlateSize, Integer>();
        Random rd = new Random();
        weight.put(SMALL_3KG,rd.nextInt(WEIGHT_PLATE_BOUND));
        weight.put(MEDIUM_5KG,rd.nextInt(WEIGHT_PLATE_BOUND));
        weight.put(LARGE_10KG,rd.nextInt(WEIGHT_PLATE_BOUND));

        if (weight.get(SMALL_3KG) + weight.get(MEDIUM_5KG) + weight.get(LARGE_10KG) == 0) {
            weight.put(WeightPlateSize.randomWeightPlate(),1);
        }

        int duration = rd.nextInt(TIME_INTERVAL) + 1;
        return new Exercise(at,weight,duration);
    }
}
