-module(shipping).
-compile(export_all).
-import(lists,[sum/1]).
-include_lib("./shipping.hrl").

shipco()->
  case init() of
    {ok,R}->R
  end.

get_ship(Shipping_State,Ship_ID) ->
  Ships = Shipping_State#shipping_state.ships,
  lists:keyfind(Ship_ID, #ship.id, Ships).
%%  print_state(Shipping_State),
%%  lists:filter(
%%    fun(#ship{id=ShipNo}) when ShipNo =:= Ship_ID -> true;
%%      (_)-> false
%%    end,Ships).


get_container(Shipping_State, Container_ID) ->
  Containers = Shipping_State#shipping_state.containers,
  lists:keyfind(Container_ID, #container.id, Containers).

get_port(Shipping_State, Port_ID) ->
  Ports = Shipping_State#shipping_state.ports,
  lists:keyfind(Port_ID, #port.id, Ports).


get_occupied_docks(Shipping_State, Port_ID) ->
  Docks = Shipping_State#shipping_state.ship_locations,
  DockList = lists:filter(
    fun(X) when element(1,X)  =:= Port_ID -> true;
      (_)-> false
    end,Docks),
  lists:map(fun(X) -> element(2,X) end, DockList).
%%  [F|| F <- Docks, Port_ID==element(1,F)].

get_ship_location(Shipping_State, Ship_ID) ->
  Docks = Shipping_State#shipping_state.ship_locations,
  case lists:keyfind(Ship_ID, 3, Docks) of
    false -> false;
    Tuple -> {element(1,Tuple),element(2,Tuple)}
  end.


get_container_weight(Shipping_State, Container_IDs) ->
  try
  ToBeSum = lists:map(fun(X) ->
  case get_container(Shipping_State,X) of
      false-> error(notfoud);
      Tuple-> Tuple#container.weight
  end end, Container_IDs),
  sum(ToBeSum)
  catch
  error:notfoud  -> error
  end.

get_ship_weight(Shipping_State, Ship_ID) ->
  ShipInventory = Shipping_State#shipping_state.ship_inventory,
  case maps:find(Ship_ID,ShipInventory) of
    {ok,R} -> get_container_weight(Shipping_State,R);
    error -> error
  end.

get_ship_cur_cap(Shipping_State, Ship_ID) ->
  ShipInventory = Shipping_State#shipping_state.ship_inventory,
  case maps:find(Ship_ID,ShipInventory) of
    {ok,R} ->  length(R);
    error -> error
  end.

get_ship_cur_load(ShipInventory, Ship_ID)->
  case maps:find(Ship_ID,ShipInventory) of
    {ok,R} ->  R;
    error -> error
  end.

get_port_cur_cap(Shipping_State, Port_ID) ->
  PortInventory = Shipping_State#shipping_state.port_inventory,
  case maps:find(Port_ID,PortInventory) of
    {ok,R} ->  length(R);
    error -> error
  end.

load_ship(Shipping_State, Ship_ID, Container_IDs) ->
  try
    ShipCap = case get_ship(Shipping_State,Ship_ID) of
                false-> error(othermessage);
                Tuple -> Tuple end,
    ShipCurCap = get_ship_cur_cap(Shipping_State,Ship_ID),
  if
    ShipCurCap+length(Container_IDs) > ShipCap#ship.container_cap -> error(overloadmessage);
    true->true
  end,

  ShipInventory = Shipping_State#shipping_state.ship_inventory,
  PortInventory = Shipping_State#shipping_state.port_inventory,
    {Port_ID, _}    = get_ship_location(Shipping_State,Ship_ID),
  PortInventory_A= maps:map(fun (X, Y) ->
  case is_sublist(Y,Container_IDs) of
      true -> if
                X =:= Port_ID -> lists:filter(fun (Elem) -> not lists:member(Elem, Container_IDs) end, Y );
                true -> Y
                end;
      _ -> Y
  end
    end, PortInventory),
  if
    PortInventory_A == PortInventory -> error(message);
    true -> true
  end,
  ShipInventory_A = maps:map(fun (X, Y) ->
    if
      X =:= Ship_ID -> lists:append(Y,Container_IDs);
      true -> Y
    end
      end,ShipInventory),
  {ok, #shipping_state{ships = Shipping_State#shipping_state.ships, containers = Shipping_State#shipping_state.containers,
    ports = Shipping_State#shipping_state.ports, ship_locations = Shipping_State#shipping_state.ship_locations,
    ship_inventory = ShipInventory_A, port_inventory = PortInventory_A}}

  catch
    error:overloadmessage ->io:format("The target ship is overload...~n"),error;
    error:message-> io:format("The given containers are not all on the same port...~n"),error;
    error:othermessage -> error
  end.

unload_ship_all(Shipping_State, Ship_ID) ->
  try
  case get_ship(Shipping_State,Ship_ID) of
    false-> error(othermessage);
    _ -> true
  end,
  {Port_ID, _} = case get_ship_location(Shipping_State,Ship_ID) of
                         {A,R} -> {A,R};
                       false->error(othermessage)
                        end,
  PortCurCap =  get_port_cur_cap(Shipping_State,Port_ID),
  ShipCurCap = get_ship_cur_cap(Shipping_State,Ship_ID),
  PortCap = get_port(Shipping_State,Port_ID),
%% judge port over weight
    if
      PortCurCap+ShipCurCap > PortCap#port.container_cap -> error(overloadmessage);
      true->true
    end,
    ShipInventory = Shipping_State#shipping_state.ship_inventory,
    PortInventory = Shipping_State#shipping_state.port_inventory,
    Ship_Containers = get_ship_cur_load(ShipInventory,Ship_ID),
    PortInventory_A= maps:map(fun (X, Y) ->
    if
      X =:= Port_ID -> lists:append(Y,Ship_Containers);
      true -> Y
    end end, PortInventory),
  ShipInventory_A = maps:map(fun (X, Y) ->
    if
      X =:= Ship_ID -> [];
      true -> Y
    end end,ShipInventory),
  {ok, #shipping_state{ships = Shipping_State#shipping_state.ships, containers = Shipping_State#shipping_state.containers,
    ports = Shipping_State#shipping_state.ports, ship_locations = Shipping_State#shipping_state.ship_locations,
    ship_inventory = ShipInventory_A, port_inventory = PortInventory_A}}
  catch
    error:overloadmessage ->io:format("The target port is overload...~n"),error;
    error:othermessage -> error
  end.


unload_ship(Shipping_State, Ship_ID, Container_IDs) ->
  try
  case get_ship(Shipping_State,Ship_ID) of
    false-> error(othermessage);
    _ -> true
  end,
  {Port_ID, _} = case get_ship_location(Shipping_State,Ship_ID) of
                         {A,R} -> {A,R};
                         false->error(othermessage)
                       end,
  PortCurCap = get_port_cur_cap(Shipping_State,Port_ID),
  PortCap = get_port(Shipping_State,Port_ID),
    if
      PortCurCap+length(Container_IDs) > PortCap#port.container_cap -> error(overloadmessage);
      true->true
    end,
    ShipInventory = Shipping_State#shipping_state.ship_inventory,
    PortInventory = Shipping_State#shipping_state.port_inventory,
    ShipInventory_A =   maps:map(fun (X, Y) ->
    if
      X =:= Ship_ID ->
        case is_sublist(Y,Container_IDs) of
          true -> lists:filter(fun (Elem) -> not lists:member(Elem, Container_IDs) end, Y );
          false -> error(errormessage)
        end;
      true-> Y
  end end,ShipInventory),

  PortInventory_A= maps:map(fun (X, Y) ->
    if
      X =:= Port_ID -> lists:append(Y,Container_IDs);
      true -> Y
    end end, PortInventory),
  {ok, #shipping_state{ships = Shipping_State#shipping_state.ships, containers = Shipping_State#shipping_state.containers,
    ports = Shipping_State#shipping_state.ports, ship_locations = Shipping_State#shipping_state.ship_locations,
    ship_inventory = ShipInventory_A, port_inventory = PortInventory_A}}
  catch
    error:errormessage -> io:format("The given containers are not all on the same ship...~n"),error;
    error:overloadmessage ->io:format("The target port is overload...~n"),error;
    error:othermessage -> error
  end.

set_sail(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
  Docks = Shipping_State#shipping_state.ship_locations,
  try
    case get_ship(Shipping_State,Ship_ID) of
        false-> error(usedmessage);
        _ -> true
    end,
    case get_port(Shipping_State,Port_ID) of
        false-> error(usedmessage);
        Tuple -> case lists:member(Dock,Tuple#port.docks) of
               true -> true;
               false-> error(usedmessage)
             end
    end,
    NewDocks = lists:map(fun (X) ->
  if
  Ship_ID =:= element(3,X) -> {Port_ID,Dock,Ship_ID};
    true -> if
              element(1,X) =:= Port_ID andalso element(2,X) =:= Dock -> error(usedmessage);
              true -> X
            end
  end end, Docks),
  {ok, #shipping_state{ships = Shipping_State#shipping_state.ships, containers = Shipping_State#shipping_state.containers,
    ports = Shipping_State#shipping_state.ports, ship_locations = NewDocks,
    ship_inventory = Shipping_State#shipping_state.ship_inventory, port_inventory = Shipping_State#shipping_state.port_inventory}}
  catch
  error:usedmessage ->error
  end.




%% Determines whether all of the elements of Sub_List are also elements of Target_List
%% @returns true is all elements of Sub_List are members of Target_List; false otherwise
is_sublist(Target_List, Sub_List) ->
lists:all(fun (Elem) -> lists:member(Elem, Target_List) end, Sub_List).

%% Prints out the current shipping state in a more friendly format
get_port_helper(Ports, Port_ID)->
  lists:keyfind(Port_ID, #port.id, Ports).


print_state(Shipping_State) ->
    io:format("--Ships--~n"),
    _ = print_ships(Shipping_State#shipping_state.ships, Shipping_State#shipping_state.ship_locations, Shipping_State#shipping_state.ship_inventory, Shipping_State#shipping_state.ports),
    io:format("--Ports--~n"),
    _ = print_ports(Shipping_State#shipping_state.ports, Shipping_State#shipping_state.port_inventory).

print_ships(Ships, Locations, Inventory, Ports) ->
    case Ships of
        [] ->
            ok;
        [Ship | Other_Ships] ->
            {Port_ID, Dock_ID, _} = lists:keyfind(Ship#ship.id, 3, Locations),
            Port = get_port_helper(Ports, Port_ID),
            {ok, Ship_Inventory} = maps:find(Ship#ship.id, Inventory),
            io:format("Name: ~s(#~w)    Location: Port ~s, Dock ~s    Inventory: ~w~n", [Ship#ship.name, Ship#ship.id, Port#port.name, Dock_ID, Ship_Inventory]),
            print_ships(Other_Ships, Locations, Inventory, Ports)
    end.

print_containers(Containers) ->
    io:format("~w~n", [Containers]).

print_ports(Ports, Inventory) ->
    case Ports of
        [] ->
            ok;
        [Port | Other_Ports] ->
            {ok, Port_Inventory} = maps:find(Port#port.id, Inventory),
            io:format("Name: ~s(#~w)    Docks: ~w    Inventory: ~w~n", [Port#port.name, Port#port.id, Port#port.docks, Port_Inventory]),
            print_ports(Other_Ports, Inventory)
    end.
%% This functions sets up an initial state for this shipping simulation. You can add, remove, or modidfy any of this content. This is provided to you to save some time.
%% @returns {ok, shipping_state} where shipping_state is a shipping_state record with all the initial content.
init() ->
    Ships = [#ship{id=1,name="Santa Maria",container_cap=10},
              #ship{id=2,name="Nina",container_cap=20},
              #ship{id=3,name="Pinta",container_cap=20},
              #ship{id=4,name="SS Minnow",container_cap=20},
              #ship{id=5,name="Sir Leaks-A-Lot",container_cap=20}
             ],
    Containers = [
                  #container{id=1,weight=200},
                  #container{id=2,weight=215},
                  #container{id=3,weight=131},
                  #container{id=4,weight=62},
                  #container{id=5,weight=112},
                  #container{id=6,weight=217},
                  #container{id=7,weight=61},
                  #container{id=8,weight=99},
                  #container{id=9,weight=82},
                  #container{id=10,weight=185},
                  #container{id=11,weight=282},
                  #container{id=12,weight=312},
                  #container{id=13,weight=283},
                  #container{id=14,weight=331},
                  #container{id=15,weight=136},
                  #container{id=16,weight=200},
                  #container{id=17,weight=215},
                  #container{id=18,weight=131},
                  #container{id=19,weight=62},
                  #container{id=20,weight=112},
                  #container{id=21,weight=217},
                  #container{id=22,weight=61},
                  #container{id=23,weight=99},
                  #container{id=24,weight=82},
                  #container{id=25,weight=185},
                  #container{id=26,weight=282},
                  #container{id=27,weight=312},
                  #container{id=28,weight=283},
                  #container{id=29,weight=331},
                  #container{id=30,weight=136}
                 ],
    Ports = [
             #port{
                id=1,
                name="New York",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=2,
                name="San Francisco",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=3,
                name="Miami",
                docks=['A','B','C','D'],
                container_cap=200
               }
            ],
    %% {port, dock, ship}
    Locations = [
                 {1,'B',1},
                 {1, 'A', 3},
                 {3, 'C', 2},
                 {2, 'D', 4},
                 {2, 'B', 5}
                ],
    Ship_Inventory = #{
      1=>[14,15,9,2,6],
      2=>[1,3,4,13],
      3=>[],
      4=>[2,8,11,7],
      5=>[5,10,12]},
    Port_Inventory = #{
      1=>[16,17,18,19,20],
      2=>[21,22,23,24,25],
      3=>[26,27,28,29,30]
     },
    {ok, #shipping_state{ships = Ships, containers = Containers, ports = Ports, ship_locations = Locations, ship_inventory = Ship_Inventory, port_inventory = Port_Inventory}}.
