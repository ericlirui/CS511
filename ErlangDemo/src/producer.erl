%%%-------------------------------------------------------------------
%%% @author eric
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. 11月 2019 10:30 上午
%%%-------------------------------------------------------------------
-module(producer).
-author("eric").

%% API
-export([]).

buffer(CurrentSize,Producers,Consumers,Capacity)->
receive
  {From,startProduce} when CurrentSize +Producers < Capacity->
    {self(),ok},
    buffer(CurrentSize,Producers+1,Consumers, Capacity+1);
  {From,endProduce}->
    buffer(CurrentSize+1,Producers,Consumers, Capacity);
  {From,startConsume} when Consumers - CurrentSize > 0 ->
    {self(),ok},
    buffer(CurrentSize,Producers,Consumers+1, Capacity);
  {From,endConsume}->
    buffer(CurrentSize-1,Producers,Consumers, Capacity)
end.


producer(S) ->
  S!{self(),startProduce},
  io:format("consumer ~p: startProduce ~n",[self()]),
  receive
    {S,ok}->
      io:format("consumer ~p: endConsume ~n",[self()]),
      produce,
      S!{self(),endProduce}
  end.

consumer(S)->
  S!{self(),startConsume},
  io:format("consumer ~p: startConsume ~n",[self()]),
  receive
    {S,ok}->
      io:format("consumer ~p: endConsume ~n",[self()]),
      consume,
      S!{self(),endConsume}
  end.

start(NP,NC,Size)->
  B=spawn(?MODULE,buffer,[0,0,0,Size]),
  [ producer(B) || _<- lists:seq(1,NP)],
  [ consumer(B) || _<- lists:seq(1,NC)].