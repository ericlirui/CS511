-module(ex_massagepassing).
-compile(export_all).


echo() ->
    receive
	{echo,From, Ref, Msg} ->
	    From ! {self(),Ref,Msg},
	    echo();
	{stop} ->
	    ok
end.

fact(0) ->
    1;
fact(N) when N>0 ->
    N*fact(N-1).

fact_loop(S) ->
    receive 
	{request,From,Ref,N} ->
	    From!{self(),Ref,fact(N)},
	    fact_loop(S+1);
	{query,From,Ref} ->
	    From!{self(),Ref,S},
	    fact_loop(S);
	{stop} ->
	    ok
    end.

gen_server(State, F) ->
    receive 
	{request,From,Ref,Input} ->
	    case (catch(F(State,Input))) of
				{'EXIT',Reason} -> From!{self(),Ref,error,Reason},
		    gen_server(State,F);
				{NewState,Result} -> From!{self(),Ref,ok,Result},
		    gen_server(NewState,F);
				ThrowException -> From!{self(),Ref,error,ThrowException},
		    gen_server(State,F)
	    end;	
	{update,From,Ref,G} ->
	    From!{self(),Ref,ok},
	    gen_server(State,G);
	{query,From,Ref} ->
	    From!{self(),Ref,State},
	    gen_server(State,F);
	{stop} ->
	    ok
    end.


sem(0) -> 		  
    receive
	{release,_From} ->
	    sem(1)
    end;	 
sem(P) when P>0 ->
    receive 
	{acquire,From} ->
	    From!{self(),ok},
	    sem(P-1);
	{release,_From} ->
	    sem(P+1)
    end.


client1(S) ->
    io:format("A~n"),
    S!{release,self()}.

client2(S) ->
    S!{acquire,self()},
    receive 
	{S,ok} ->
	    io:format("B~n")
    end.
    
    
start() ->
     S = spawn(?MODULE,sem,[0]),
    spawn(?MODULE,client2,[S]),
    spawn(?MODULE,client1,[S]).



%%semaphore using massage passing

sem(0)->
	receive
		{release,From,Ref}->
			sem(1)
	end;
sem(N) when N > 0 ->
	receive
		{release} ->
			sem(N+1);
		{acquire,From,ref} ->
			From!{ack}

	end.
acquire(S)->
	R=make_ref(),
	S!{acquire,self(),R},
	receive
		{ack,S,R}->
			ok
	end.




%% Trunstile example using message passing

counter_loop(C)->
	receive
		{bump}->
			counter_loop(C+1);
		{read,From,Ref}->
			From!{self(),Ref,C},
			counter_loop(C);
		{stop}->
			ok
	end.

turnstile(0, _C)	->
	ok;

turnstile(N, C)	when N>0 ->
	C!{bump},
	turnstile(N-1, C).

starT(N) ->
	C = spawn(?MODULE, counter_loop, [0]),
	spawn(?MODULE, turnstile, [N, C]),
	spawn(?MODULE, turnstile, [N, C]),
	C.

%%% How to test you code in the Erlang shell
%> c(ex).
%> C = ex;shartT(50).
%> C!{read, self(), make_ref()}.
%> flush().




start()->
	spawn(?MODULE, fun  server /0).
server()->
	receive
		{From,Ref,start}->
			S = spawn(?MODULE,sevlet,[From,rand:uniform(20)]), %% from is the client
			From!{self(),Ref,S,ok},
			server()
	end.

client(S)->
	R= make_ref(),
	S!{self(),R,start},
	receive
		{S,R,Servlet,ok} ->
			ok
	end,
	N = rand:uniform(20),
	client_loop(Servlet,N,0).

client_loop(Servlet,N,C)->
	R= make_ref(),
	Servlet!{self(),R,guess,N},
	receive
		{Servlet,R,gotIt}->
			io:format("Clinet ~p guessedin ~W attempts~n",[self(),C]);
		{Servlet,R,tryAgain}->
			clinet_loop(Servlet,rand:uniform(20),C+1)
	end.

servlet(Client,Number)->
	receive
		{Client,R,guess,N} ->
			if
				N == Number -> Client!{self(),R,gotIt} ;
				true -> Client!{self(),R,tryAgain},
					servlet(Client,Number)
			end
	end.




dryCleaner(Clean,Dirty) ->
	receive
		{dropOffOverall}->
			dryCleaner(Clean,Dirty+1) ;
		{From,Ref,dryCleanItem}  when Clean >0 ->
			From!{self(),Ref,pickUpOne},
			dryCleaner(Clean+1,Dirty-1);
		{From,Ref,pickUpOverall} when Clean >0 ->
			From!{self(),Ref,ok},
			dryCleaner(Clean-1,Dirty)
	end.

employee(DC) ->
	DC!{dropOffOverall},
	receive
		{From,Ref,pickUpOne} ->
			ok
	end.

dryCleanMachine(DC)->
	DC!{self(),make_ref(),dryCleanItem},
	receive
	{From,Ref,ok} ->
		timer:sleep(1000),
		From!{self(),pickUpOverall},
		dryCleanMachine(DC)
	end.

start(W,M)->
	DC=spawn (?MODULE,dryCleaner,[0,0]),
	[spawn(?MODULE, employee(), [DC]) || _ <- lists:seq(1,W) ],
	[spawn(?MODULE, dryCleanMachine, [DC]) ||  _ <- lists:seq(1,M) ].


