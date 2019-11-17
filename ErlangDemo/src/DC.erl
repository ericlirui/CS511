%%%-------------------------------------------------------------------
%%% @author eric
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 11月 2019 10:45 上午
%%%-------------------------------------------------------------------
-module('DC').
-author("eric").
-compile(export_all).


dryCleaner(Clean,Dirty) ->
  receive
    {dropOffOverall}->
      dryCleaner(Clean,Dirty+1) ;
    {From,Ref,dryCleanItem}  when Clean >0 ->
      From!{self(),Ref,ok},
      dryCleaner(Clean+1,Dirty-1);
    {From,Ref,pickUpOverall} when Clean >0 ->
      From!{self(),Ref,ok},
      dryCleaner(Clean-1,Dirty)
  end.

employee(DC) ->
  DC!{dropOffOverall},
  DC!{self(),make_ref(),pickUpOverall},
  receive
    {From,Ref,ok} ->
      ok
  end.

dryCleanMachine(DC)->
  DC!{self(),make_ref(),dryCleanItem},
  receive
    {From,Ref,ok} ->
      timer:sleep(1000),
      dryCleanMachine(DC)
  end.

start(W,M)->
  DC=spawn (?MODULE,dryCleaner,[0,0]),
  [spawn(?MODULE, employee(), [DC]) || _ <- lists:seq(1,W) ],
  [spawn(?MODULE, dryCleanMachine, [DC]) ||  _ <- lists:seq(1,M) ].

