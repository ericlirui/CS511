%%%-------------------------------------------------------------------
%%% @author eric
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 11月 2019 10:17 上午
%%%-------------------------------------------------------------------
-module(barrier).
-author("eric").

%% API
-export([]).
%%first is the total number of process that have to reach to barrier, second is the number of processes yet to reach the barrier
%%thrid is the list of pids of process that have already reached the barrier.

barrier(0,N,L)->
  [From!{self(),ok} || From <- L],
  barrier(N,N,[]);
barrier(M,N,L) when M >0 ->
  receive
    {From,reached}->
      barrier(M-1,N,[From|L])
  end.


