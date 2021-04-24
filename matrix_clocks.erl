% Module simulating processes exchanging messages with matrix clocks
% Created by Maxime Princelle, M1 SIL
%
% The included test separates 'even' sites to 'uneven' ones:
% - All the 'even' sites receive a message from every 'uneven' ones then send back a message to each of them.
% - All the 'uneven' sites send a message to each 'even' sites then receive a message from each of them.
%
% --------------------------------------------

-module(matrix_clocks).
-export([test/1, site/4, rowMax/2]).

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
    io:format("~nError: (rowMax) Invalid sizes (lists have to be the same length).~n Details: List1=(~w) List2=(~w)~n", [List1, List2]),
    error;
rowMax(List1, List2) when (length(List1) == 1) and (length(List1) == length(List2)) -> % One element by list
    Val1 = lists:nth(1, List1),
    Val2 = lists:nth(1, List2),
    if
        (Val1 >= Val2) -> [Val1];
        (Val1 < Val2) -> [Val2]
    end; % Returns the max value between the list of a size of 1
rowMax(List1, List2) when (length(List1) > 1) and (length(List1) == length(List2)) ->
    Val1 = lists:nth(1, List1),
    Val2 = lists:nth(1, List2),
    if
        (Val1 >= Val2) -> [Val1] ++ rowMax(lists:nthtail(1, List1), lists:nthtail(1, List2));
        (Val1 < Val2) -> [Val2] ++ rowMax(lists:nthtail(1, List1), lists:nthtail(1, List2))
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
        (Idx1 == 1) -> rowMax(lists:nth(1, Clock1), lists:nth(Idx2, Clock2)) ++ lists:nthtail(1, Clock1);
        (Idx1 < length(Clock1)) -> lists:sublist(Clock1, Idx1-1) ++ rowMax(lists:nth(Idx1, Clock1), lists:nth(Idx2, Clock2)) ++ lists:nthtail(Idx1, Clock1);
        (Idx1 == length(Clock1)) -> lists:sublist(Clock1, Idx1-1) ++ rowMax(lists:nth(Idx1, Clock1), lists:nth(Idx2, Clock2));
        (length(Clock1) /= length(Clock2)) -> io:format("~nError: (clockRowSync) Invalid sizes (Clocks have to be the same size).~n Details:~n  Clock1=(~w)~n  Clock2=(~w)~n", [Clock1, Clock2]), error
    end. % Return the updated Clock


% Returns a Clock with the max values
% (lists have to be the same size)
% - Clock1: first Clock
% - Clock2: second Clock
clockSync_do(Idx, Clock1, Clock2) ->
    if
        (Idx == 0) -> clockRowSync(0, 0, Clock1, Clock2);
        (Idx > 0) -> clockSync_do(Idx-1, clockRowSync(Idx, Idx, Clock1, Clock2), Clock2);
        (Idx < 0) -> io:format("~nError: (clockSync_do) Invalid Idx.~n Details:~n  Idx=(~p)~n~n  Clock1=(~w)~n  Clock2=(~w)~n", [Idx, Clock1, Clock2]), error
    end.
clockSync(Clock1, Clock2) ->
    if
        (length(Clock1) == length(Clock2)) -> clockSync_do(length(Clock1), Clock1, Clock2);
        (length(Clock1) /= length(Clock2)) -> io:format("~nError: (clockSync) Invalid sizes (Clocks have to be the same size).~n Details:~n  Clock1=(~w)~n  Clock2=(~w)~n", [Clock1, Clock2]), error
    end. % Return the updated Clock


% % Updates the Clock for an internal event
% % - Site: Idx of the process on which the event is made
% % - SiteClock: Clock of the process on which the event is made
% internalEvent(Site, SiteClock) ->
%     incrementClock(Site, SiteClock). % Increment the process clock


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
    clockSync(clockRowSync(Receiver, Sender, incrementClock(Receiver, ReceiverClock), Message), Message). % Increment and Update the receiver clock, then Sync it


% % Prints a List in the console
% % - List: list to display
% printList(List) ->
%     io:format("[ "),
%     lists:foreach(fun(Y) -> io:format(" ~p ", [Y]) end, List),
%     io:format(" ]").


% % Prints a Clock in the console
% % - Clock: Clock to display
% printClock(Clock) ->
%     lists:foreach(fun(Y) -> printList(Y) end, Clock),
%     io:format("~n").


% Function that sets the flow for a process
% - Idx: index given to the process
% - Clock: matrix clock of the process
% - Step: defines the step (1 or 2) of the simulation to determine if the process will send or receive messages
% - Iteration: defines the current iteration for the given Step, this allows us to count the messages sent and received. Also, it allows us to respect the simulated procedure and determine to which process send a message
site(Idx, Clock, Step, Iteration) ->
    % Clock at the begining.
    io:format("~nProcess= p~p : Clock= ~w~n",[Idx, Clock]),
    if
        % Uneven processes send a message to all even processes...
        (Step == 1) and (Idx rem 2 == 1) and (Iteration*2 =< length(Clock))  ->
            Message = messageToSend(Idx, Clock),
            io:format("~nProcess= p~p : Sending a message to process= p~p => ( ~w )~n", [Idx, Iteration*2, Message]),
            list_to_atom("p"++integer_to_list(Iteration*2)) ! {Message, Idx}, % Sending message to even process
            site(Idx, Message, 1, Iteration+1); % Recall the method to send any other messages (Step stays the same, but we increment Iteration)

        % Done with Step 1 for the uneven processes
        (Step == 1) and (Idx rem 2 == 1) and (Iteration*2 > length(Clock)) ->
            io:format("~nProcess= p~p : All messages sent, passing to receiving step...~n Current Clock = ~w~n", [Idx, Clock]),
            site(Idx, Clock, 2, 1); % We go to Step 2 and reset the Iteration value

        % Even processes receive a message from each uneven ones...
        (Step == 1) and (Idx rem 2 == 0)
            and (      ((Iteration =< length(Clock)/2) and (length(Clock) rem 2 == 0)) % Size 'even'
                    or ((Iteration =< (length(Clock)+1)/2) and (length(Clock) rem 2 == 1)) % Size 'uneven'
                ) ->
                receive % Receive message from process
                    {Message, Sender} -> 
                        io:format("~nProcess= p~p : Receiving a message from process= p~p => ( ~w )~n", [Idx, Sender, Message]),
                        % io:format("~nProcess= p~p : Clock after receiving message from (p~p) = ~n~w~n", [Idx, Sender, Clock2]),
                        site(Idx, messageToReceive(Idx, Clock, Sender, Message), 1, Iteration+1) % Recall the method to receive any other messages (Step stays the same, but we increment Iteration)
                end;

        % Done with Step 1 for even processes
        (Step == 1) and (Idx rem 2 == 0)
            and (      ((length(Clock) rem 2 == 0) and (Iteration > length(Clock)/2))
                    or ((length(Clock) rem 2 == 1) and (Iteration > (length(Clock)+1)/2))
                ) ->
                io:format("~nProcess= p~p : All messages were received, now sending back...~n",[Idx]),
                site(Idx, Clock, 2, 1); % We go to Step 2 and reset the Iteration value

        % After the Step 1, all 'uneven' processes receive a message from each 'even' ones.
        (Step == 2) and (Idx rem 2 == 1)
            and (      ((Iteration =< length(Clock)/2) and (length(Clock) rem 2 == 0)) % Size 'even'
                    or ((Iteration =< (length(Clock)+1)/2) and (length(Clock) rem 2 == 1)) % Size 'uneven'
                ) ->
                receive
                    {Message, Sender} -> 
                        io:format("~nProcess= p~p : Receiving a message from process= p~p => ( ~w )~n", [Idx, Sender, Message]),
                        % io:format("~nProcess= p~p : Clock after receiving message from (p~p) = ~n~w~n", [Idx, Sender, Clock2]),
                        site(Idx, messageToReceive(Idx, Clock, Sender, Message), 2, Iteration+1) % Recall the method to receive any other messages (Step stays the same, but we increment Iteration)
                end;

        % After the Step 1, every 'even' processes send a message to each 'uneven' ones.
        (Step == 2) and (Idx rem 2 == 0) and (Iteration*2-1 =< length(Clock)) ->
            Message = messageToSend(Idx, Clock),
            io:format("~nProcess= p~p : Sending a message to p~p => ( ~w )~n", [Idx, Iteration*2-1, Message]),
            list_to_atom("p"++integer_to_list(Iteration*2-1)) ! {Message, Idx}, % We send messages to 'uneven' processes
            site(Idx, Message, 2, Iteration+1); % Recall the method to send any other messages (Step stays the same, but we increment Iteration)

        % Site is done with it's tasks, stopping itself.
        true -> io:format("~nDone with process p~p~n", [Idx]), true
    end.


% Test function for the simulator, N is the number of processes to run.
test(N) ->
    % This included test separates 'even' sites to 'uneven' ones:
    % - All the 'even' sites receive a message from every 'uneven' ones then send back a message to each of them.
    % - All the 'uneven' sites send a message to each 'even' sites then receive a message from each of them.
    io:format("~nIn this test, there will be ~p procceses.~nWe separate 'even' ones from 'uneven' ones.~nTheir flow is predefined like this:~n- All the 'even' sites receive a message from every 'uneven' ones then send back a message to each of them.~n- All the 'uneven' sites send a message to each 'even' sites then receive a message from each of them.~n",[N]),
    initSite(N).
