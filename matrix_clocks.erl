% Module simulating processes exchanging messages with matrix clocks
% Created by Maxime Princelle, M1 SIL
% --------------------------------------------

--module(matrix_clocks)


% Function generating and saving a pI process
% Idx : number to attribute to the process (>= 1)
% N : total number of processes
initSite(Idx, N) when (Idx < N + 1)->
    % Creating a clock (list of lists (N*N))
    Clock = lists:duplicate(N, lists:duplicate(N, 0)), 
    % Register process (pI with I = Idx)
    register(list_to_atom("p"++integer_to_list(Idx)), spawn(?MODULE, site, [Idx, Clock, 1, 1])),
    initSite(Idx+1,N);
initSite(Idx, N) when (Idx >= N + 1) ->
    ok.
initSite(N) when (N < 2) ->
    error.
initSite(N) ->
    initSite(1,N).


% Increments the value of the given List at a specified Index
% - Idx: is the index of the clock to increment
% - List: is the List on which the operation is performed
% Returns the edited List object
% > Operation: C_i[i] <- C_i[i] + 1
incrementValueInList(Idx, List) ->
    if
        (Idx == 1) -> [lists:nth(1, List) +1] ++ lists:nthtail(1,List);
        (Idx < length(List)) -> lists:sublist(List, Idx-1) ++ [lists:nth(Idx, List) +1] ++ lists:nthtail(Idx,List);
        (Idx == length(List)) -> lists:sublist(List, Idx-1) ++ [lists:nth(Idx,List) +1];
        (Idx > length(List)) -> error
    end. % The result of if is used as return value for the function.


% Increments the value of the given Clock at a specified Index
% - Idx: is the index of the clock to increment
% - Clock: is the Clock on which the operation is performed
% Returns the edited Clock object
% > Operation: C_i[i,i] <- C_i[i,i] + 1
incrementClock(Idx, Clock) ->
    if
        (Idx == 1) -> [incrementValueInList(1, lists:nth(1, Clock))] ++ lists:nthtail(1, Clock);
        (Idx < length(Clock)) -> lists:sublist(Clock, Idx-1) ++ [incrementValueInList(Idx, lists:nth(Idx, Clock))] ++ lists:nthtail(Idx, Clock);
        (Idx == length(Clock)) -> lists:sublist(Clock, Idx-1) ++ [incrementValueInList(Idx, lists:nth(Idx, Clock))];
        (Idx > length(Clock)) -> error
    end. % The result of 'if' is used as return value for the function.


% Compares the values of two lists and returns a List with the greatests values
% (lists have to be the same size)
% - List1: first list
% - List2: second list
rowMax(List1, List2) when (length(List1) < 1) or (length(List1) /= length(List2)) -> % Invalid sizes (lists have to be the same length)
    error;
rowMax(List1, List2) when (length(List1) == 1) and (length(List1) == length(List2)) -> % One element by list
    Val1 = lists:nth(1,List1),
    Val2 = lists:nth(1,List2),
    if
        Val1 >= Val2 -> [Val1];
        Val1 < Val2 -> [Val2]
    end; % Returns the max value between the list of a size of 1
rowMax(List1, List2) when (length(List1) > 1) and (length(List1) == length(List2)) ->
    Val1 = lists:nth(1,List1),
    Val2 = lists:nth(1,List2),
    if
        Val1 >= Val2 -> [Val1] ++ rowMax(lists:nthtail(1,List1), lists:nthtail(1,List2));
        Val1 < Val2 -> [Val2] ++ rowMax(lists:nthtail(1,List1), lists:nthtail(1,List2))
    end. % Returns the max value on the first elements of the list then recalls the function to append the return for the next element(s) of the Lists


% Returns a Clock with the max values between two given rows
% (lists have to be the same size)
% - Idx1: first row index for Clock1 (i)
% - Idx2: second row index for Clock2 (j)
% - Clock1: first Clock (i)
% - Clock2: second Clock (j)
% > Operation: C_i[i,*] <- max(C_i[i,*], C_j[j,*])
clockRowSync(Idx1, Idx2, Clock1, Clock2) ->
    if
        (Idx1 == 1) -> [rowMax(lists:nth(1, Clock1), lists:nth(Idx2, Clock2))] ++ lists:nthtail(1, Clock1);
        (Idx1 < length(Clock1)) -> lists:sublist(Clock1, Idx1-1) ++ [rowMax(lists:nth(Idx1, Clock1), lists:nth(Idx2, Clock2))] ++ lists:nthtail(Idx1, Clock1);
        (Idx1 == length(Clock1)) -> lists:sublist(Clock1, Idx1-1) ++ [rowMax(lists:nth(Idx1, Clock1), lists:nth(Idx2, Clock2))];
        (length(Clock1) > 1) -> error;
        (length(Clock1) /= length(Clock2)) -> error;
    end. % Return the updated Clock


% Returns a Clock with the max values
% (lists have to be the same size)
% - Clock1: first Clock
% - Clock2: second Clock
clockSync_do(0, Clock1, Clock2) -> 
    clockRowSync(0, 0, Clock1, Clock2)
clockSync_do(Idx, Clock1, Clock2) ->
    clockSync_do(Idx-1, clockRowSync(Idx, Idx, Clock1, Clock2), Clock2)
clockSync(Clock1, Clock2) ->
    if
        (length(Clock1) == length(Clock2)) -> clockSync_do(length(Clock1)-1, Clock1, Clock2);
        (length(Clock1) /= length(Clock2)) -> error;
        (length(Clock1) > 1) -> error;
    end. % Return the updated Clock


% Prepares and returns the Clock of the message to send
% - From: Idx of the process from which the message is sent
% - FromClock: Clock of the process from which the message is sent
messageToSend(From, FromClock) ->
    incrementClock(From, FromClock). % Increment the process clock


% Updates the Clock on message reception
% - Receiver: Idx of the process from which the message is received
% - ReceiveClock: Clock of the process from which the message is received
% - Sender: Idx of the process from which the message is sent
% - Message: Clock of the process from which the message is sent
messageToReceive(Receiver, ReceiverClock, Sender, Message) ->
    ReClock = incrementClock(Receiver, ReceiverClock), % Increment the receiver clock
    ReClock = clockRowSync(Receiver, Sender, ReClock, Message); % Update the receiver clock
    clockSync(ReClock, Message). % Sync the receiver clock

