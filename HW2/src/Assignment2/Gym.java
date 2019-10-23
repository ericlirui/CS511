package Assignment2;
import  java.util.*;
import  java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static Assignment2.WeightPlateSize.*;

public class Gym implements Runnable{
    private static final int GYM_SIZE = 30;
    private static final int GYM_REGISTERED_CLIENTS = 10000;
    private Map< WeightPlateSize ,Integer> noOfWeightPlates;
    private Set<Integer> clients; // for generating fresh client ids
    private ExecutorService executor;
    private int counterSmall;
    private int counterMedium;
    private int counterLarge;
    private int ClientCounter;
    private List<Integer> listSet;

    // various semaphores
    private static Semaphore[] sem = {new Semaphore(1),new Semaphore(1),new Semaphore(1),
            new Semaphore(1),new Semaphore(1),new Semaphore(1),new Semaphore(1),new Semaphore(1)};
    private static Semaphore small3 = new Semaphore(1);
    private static Semaphore medium5 = new Semaphore(1);
    private static Semaphore large10 = new Semaphore(1);
    private static Semaphore mutex = new Semaphore(1);


    public Gym(){
        this.noOfWeightPlates = new HashMap<WeightPlateSize, Integer>();
        this.noOfWeightPlates.put(SMALL_3KG,110);
        this.noOfWeightPlates.put(LARGE_10KG,75);
        this.noOfWeightPlates.put(MEDIUM_5KG,90);
        this.clients = IntStream.range(0,GYM_REGISTERED_CLIENTS).boxed().collect(Collectors.toSet());
        this.counterSmall = 0;
        this.counterMedium = 0;
        this.counterLarge = 0;
        this.ClientCounter = 0;
        this.listSet = new ArrayList<Integer>(clients);
        //run thread Client
        this.executor = Executors.newFixedThreadPool(GYM_SIZE);
        for (int i = 0; i < GYM_REGISTERED_CLIENTS - 1 ; i++) {
            this.executor.execute(this::run);
        }
        executor.shutdown();
    }
    public void run(){
        try {
            mutex.acquire();
            Client cl = Client.generateRandom(listSet.get(ClientCounter));
            ClientCounter ++;
            mutex.release();
            List<Exercise> route = cl.getRoutine();
            //System.out.printf("Size of routine is %d\n",route.size());
            for (Iterator<Exercise> it = route.iterator(); it.hasNext(); ) {
                Exercise value = it.next();
                sem[value.getAt().ordinal()].acquire();
                Map<WeightPlateSize,Integer> weight = value.getWeight();

                small3.acquire();
                mutex.acquire();
                counterSmall = counterSmall + weight.get(SMALL_3KG);
                mutex.release();
                while(counterSmall > noOfWeightPlates.get(SMALL_3KG) ){
                    System.out.printf("Client %d is waiting at Apparatus small.\n",cl.getId());
                }
                small3.release();

                medium5.acquire();
                mutex.acquire();
                counterMedium = counterMedium + weight.get(MEDIUM_5KG);
                mutex.release();

                while(counterMedium > noOfWeightPlates.get(MEDIUM_5KG) ){
                    System.out.printf("Client %d is waiting at Apparatus medium.\n",cl.getId());
                }
                medium5.release();

                large10.acquire();
                mutex.acquire();
                counterLarge = counterLarge + weight.get(LARGE_10KG);
                mutex.release();
                while(counterLarge > noOfWeightPlates.get(LARGE_10KG) ){
                    System.out.printf("Client %d is waiting at Apparatus large.\n",cl.getId());
                }
                large10.release();
                //exercise
                System.out.printf("Client %d is exercising, ApparatusType:%s, WeightPlate small:%d, medium:%d, large:%d\n",
                        cl.getId(),value.getAt().toString(),weight.get(SMALL_3KG),weight.get(MEDIUM_5KG),weight.get(LARGE_10KG));
                Thread.sleep(value.getDuration());

                //unload
                mutex.acquire();
                counterSmall = counterSmall - weight.get(SMALL_3KG);
                counterMedium = counterMedium - weight.get(MEDIUM_5KG);
                counterLarge = counterLarge - weight.get(LARGE_10KG);
                mutex.release();

                sem[value.getAt().ordinal()].release();
                //System.out.printf("Client %d is finished exercise, ApparatusType:%s, WeightPlate small:%d, medium:%d, large:%d\n",
                //        cl.getId(),value.getAt().toString(),weight.get(SMALL_3KG),weight.get(MEDIUM_5KG),weight.get(LARGE_10KG));
            }

        }catch (InterruptedException e){
            e.printStackTrace();
        }
    }
}
