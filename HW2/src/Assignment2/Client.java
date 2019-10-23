package Assignment2;
import java.util.*;

public class Client {
    private int id;
    private List<Exercise> routine;
    private static final int RANGE_START = 15;
    private static final int RANGE_END = 20;
    private static final int RANGE = 6;

    public Client(int id){
        this.id = id;
        this.routine = new ArrayList<Exercise>();
    }
    public void addExercise(Exercise e){
        this.routine.add(e);
    }
    public  List<Exercise> getRoutine(){
        return this.routine;
    }
    public int getId(){
        return this.id;
    }
    public static Client generateRandom(int id){
        Client cl = new Client(id);
        Exercise ex;
        Random rd  = new Random();
        //generate a random number betwen 15 to 20;
        int range = rd.nextInt(RANGE_END) % RANGE + RANGE_START;
        for (int i = 0; i < range; i++) {
            ex = Exercise.generateRandom();
            cl.addExercise(ex);
        }
        return cl;
    }
}
