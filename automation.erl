-module(automation).

-export([startAutomation/0,registerAutomation/4,signInUsers/3,createSubscribers/4,subscribeAutomation/3,createTweets/3
,sendTweetAutomation/4,getAllTweets/3,getMyMentions/3]).

startAutomation()->
    {ok,UserCount}=io:read("Enter Number of users~n"),
    {ok,NumberOfDisconnectedUsers}=io:read("Number of disconnected users"),
    ServerConnectionId=spawn(list_to_atom("centralserver@VenkatsaiROGG15"),mainclass,signInBuffer,[]),
    persistent_term:put("UserCount",UserCount),
    statistics(wall_clock),
    registerAutomation(UserCount,NumberOfDisconnectedUsers,1,ServerConnectionId).

registerAutomation(UserCount,NumberOfDisconnectedUsers,Index,ServerConnectionId)->
    if
        Index>UserCount ->
            automation:signInUsers(UserCount,1,ServerConnectionId);
        true ->
            UserName="User"++  integer_to_list(Index),
            ServerConnectionId ! {UserName,UserName,"someThingElse",self(),register},
            receive
                {_}->
                    ok
                    % io:format("~s~n",[Registered])    
            end,
            registerAutomation(UserCount,NumberOfDisconnectedUsers,Index+1,ServerConnectionId)
    end.
 signInUsers(UserCount,Index,ServerConnectionId)->
    if
        Index>UserCount ->
            subscribeAutomation(1800,1,ServerConnectionId),
            sendTweetAutomation(1800,UserCount-1,1,ServerConnectionId);
            ok;
        true ->
            List4=[{"a",[]}],
            Map6=maps:from_list(List4),
            TweetMapId=spawn(sendreceive,idTweetMap,[Map6,1]),
            ReceivePid=spawn(sendreceive,receiveTweetFromUserAutomation,[TweetMapId]),
            UserName="User"++  integer_to_list(Index),
            ServerConnectionId!{UserName,[UserName,ReceivePid],self()},
            receive
                {_}->
                    ok   
            end,
            signInUsers(UserCount,Index+1,ServerConnectionId)
    end.
 subscribeAutomation(CurrentCount,Index,ServerConnectionId)->
    if
        CurrentCount<2 ->
            ok;
        true ->
            spawn(automation,createSubscribers,[Index,CurrentCount,1,ServerConnectionId]),
            % automation:createSubscribers(Index,CurrentCount,1,ServerConnectionId),
            subscribeAutomation(CurrentCount div (Index+1),Index+1,ServerConnectionId)
    end.

sendTweetAutomation(OriginalCount,CurrentCount,Index,ServerConnectionId)->
    if
        CurrentCount<2 ->
            automation:getAllTweets(1,OriginalCount,ServerConnectionId),
            automation:getMyMentions(1,OriginalCount,ServerConnectionId);
            ok;
        true ->
            spawn(automation,createTweets,[Index,CurrentCount,ServerConnectionId]),
            % automation:createTweets(Index,CurrentCount,ServerConnectionId),
            sendTweetAutomation(OriginalCount,CurrentCount div (Index+1),Index+1,ServerConnectionId)
    end.

createTweets(CurrentId,SubscriberCount,ServerConnectionId)->
    if
        SubscriberCount==0->
            ok;    
        true ->
            UserName="User"++  integer_to_list(CurrentId),
            Z=base64:encode(crypto:strong_rand_bytes(32)),
            if
                SubscriberCount rem 3==0->
                    HashTweet=binary_to_list(Z)++" @User"++integer_to_list(rand:uniform(SubscriberCount)),
                    ServerConnectionId!{UserName,HashTweet,self(),tweet},
                    receive
                        {_}->
                            ok  
                    end;        
                true->
                    ServerConnectionId!{UserName,binary_to_list(Z),self(),tweet},
                    receive
                        {_}->
                            ok  
                    end
            end,        
            createTweets(CurrentId,SubscriberCount-1,ServerConnectionId)
    end. 

createSubscribers(CurrentId,SubscriberCount,Index,ServerConnectionId)->
    if
        Index==CurrentId ->
            createSubscribers(CurrentId,SubscriberCount-1,Index+1,ServerConnectionId);
        SubscriberCount==0->
            ok;    
        true ->
            UserName="User"++  integer_to_list(CurrentId),
            CurrentUserName="User"++  integer_to_list(Index),
            ServerConnectionId!{UserName,CurrentUserName,self(),"RandomShit"},
            receive
                {_}->
                    ok  
            end,
            createSubscribers(CurrentId,SubscriberCount-1,Index+1,ServerConnectionId)
    end.
getAllTweets(Index,UserCount,ServerConnectionId)->
    if
        Index==UserCount->
            ok;
        true->
            UserName="User"++  integer_to_list(Index),
            ServerConnectionId!{querying,UserName,self(),tweet},
            receive
                {_}->
                    ok
            end,  
            getAllTweets(Index+1,UserCount,ServerConnectionId)
    end.
getMyMentions(Index,UserCount,ServerConnectionId)->
    if
        Index==UserCount->
            {_, Time2} = statistics(wall_clock),
            io:format("Time Taken is ~p~n",[Time2*40]);
        true->
            UserName="User"++  integer_to_list(Index),
            UserId="@"++UserName,
            ServerConnectionId!{querying,UserId,self(),tweet},
            receive
                {_}->
                    ok
            end,  
            getMyMentions(Index+1,UserCount,ServerConnectionId)
    end.





