-module(sendreceive).

-export([sendTweetToServer/1,getTweetFromUser/1,hashTagTweetMap/1,parseTheTweet/5,receiveTweetFromUser/0,
sendTweetToAllSubscribers/4,myMentions/0,queryHashTag/1,printTweets/2,getSubscribedTweets/0,handle/5,idTweetMap/2,reTweet/1,
sendTweetToServerAutomation/2,reTweetAutomation/2,receiveTweetFromUserAutomation/1,getSubscribedTweetsAutomation/2]).

sendTweetToServer(Tweet)->
    try persistent_term:get("SignedIn")
    catch 
    error:X ->
        io:format("~p~n",[X])
    end,  
    SignedIn=persistent_term:get("SignedIn"),
    if
        SignedIn==true-> 
            RemoteServerId=persistent_term:get("ServerId"),
            RemoteServerId!{persistent_term:get("UserName"),Tweet,self(),tweet},
            receive
                {Registered}->
                    io:format("~s~n",[Registered])  
            end;
        true->
            io:format("You should sign in to send tweets Call mainclass:startTheRegistration() to complete signin~n")
    end. 


getTweetFromUser(UserTweetMap)->
    receive
        {UserName,Tweet,Pid,RemoteNodePid}->
            NewUserTweetMap=sendreceive:handle(UserName,Tweet,Pid,RemoteNodePid,UserTweetMap),
            % io:format("~p~n",[NewUserTweetMap]),
            getTweetFromUser(NewUserTweetMap);
         {UserName}->
            NewUserTweetMap=maps:put(UserName,[],UserTweetMap),
            getTweetFromUser(NewUserTweetMap);
         {UserName1,Pid}->
            {UserName}=UserName1,
            ListTweets=maps:find(UserName,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {[]};
                true ->
                    {ok,Tweets}=ListTweets,
                    Pid ! {Tweets}
            end,
            getTweetFromUser(UserTweetMap); 
         {UserName,Pid,RemoteNodePid}->
            ListTweets=maps:find(UserName,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {[],RemoteNodePid};
                true ->
                    {ok,Tweets}=ListTweets,
                    Pid ! {Tweets,RemoteNodePid}
            end,
            getTweetFromUser(UserTweetMap)

    end. 

handle(UserName,Tweet,Pid,RemoteNodePid,UserTweetMap)->
    ListTweets=maps:find(UserName,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {"User Not present in Server Database",RemoteNodePid},
                    UserTweetMap; 
                true ->
                    {ok,Tweets}=ListTweets,
                    Tweets1=lists:append(Tweets,[Tweet]),
                    NewUserTweetMap=maps:put(UserName,Tweets1,UserTweetMap), 
                    Pid ! {"Tweet Posted",RemoteNodePid},  
                    TweetSplitList=string:split(Tweet," ",all),
                    parseTheTweet(TweetSplitList,1,Tweet,UserName,"#"),
                    parseTheTweet(TweetSplitList,1,Tweet,UserName,"@"),
                    subscribeToUser ! {UserName,self()},
                    receive
                        {Subscribers}->
                        %   io:format("Subscribers are ~p~n",[Subscribers]),
                          spawn(sendreceive,sendTweetToAllSubscribers,[Subscribers,1,Tweet,UserName])
                    end,                  
                    NewUserTweetMap  
            end.


hashTagTweetMap(HashTagTweetMap)->
   receive
    {HashTag,Tweet,UserName,addnewhashTag}->
        % io:format("~s~n",[Tweet]),
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                NewHashTagTweetMap=maps:put(HashTag,[{Tweet,UserName}],HashTagTweetMap),
                hashTagTweetMap(NewHashTagTweetMap); 
            true ->
                {ok,Tweets}=ListTweets,
                Tweets1=lists:append(Tweets,[{Tweet,UserName}]),
                NewHashTagTweetMap=maps:put(HashTag,Tweets1,HashTagTweetMap),
                % io:format("~p",NewUserTweetMap),                
                hashTagTweetMap(NewHashTagTweetMap)  
        end;
     {HashTag,Pid,RemoteNodePid}->
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                Pid ! {[],RemoteNodePid};
            true ->
                {ok,Tweets}=ListTweets,
                Pid ! {Tweets,RemoteNodePid}
        end,
        hashTagTweetMap(HashTagTweetMap)
    end. 
parseTheTweet(SplitTweet,Index,Tweet,UserName,Tag)->
    if
        Index==length(SplitTweet)+1 ->
         ok;
        true ->
            CurrentString=string:find(lists:nth(Index,SplitTweet),Tag,trailing),
            if
                CurrentString==nomatch ->
                  ok;  
                true ->
                    if
                        Tag=="@" ->
                            UserName1=string:sub_string(CurrentString,2,length(CurrentString)),
                            userProcessIdMap!{UserName1,Tweet,UserName,someShit,tweet};
                        true ->
                            ok
                    end,
                    hashTagMap ! {CurrentString,Tweet,UserName,addnewhashTag}  
            end,
            parseTheTweet(SplitTweet,Index+1,Tweet,UserName,Tag)
    end.

sendTweetToAllSubscribers(Subscribers,Index,Tweet,UserName)->
 if
    Index>length(Subscribers)->
            ok;
    true->
        {Username1,_}=lists:nth(Index,Subscribers),
        % io:format("~p~n",[Pid]),
        userProcessIdMap!{Username1,Tweet,UserName,someShit,tweet},
        sendTweetToAllSubscribers(Subscribers,Index+1,Tweet,UserName)
 end.       

receiveTweetFromUser()->
    receive
     {Message,UserName}->
        tweetMap!{UserName,Message},
        receiveTweetFromUser()
    end.
myMentions()->
    RemoteServerId=persistent_term:get("ServerId"),
    UserId="@"++persistent_term:get("UserName"),
    RemoteServerId!{querying,UserId,self(),tweet},
    receive
        {Tweets}->
            printTweets(Tweets,1) 
    end.
queryHashTag(Tag)->
    RemoteServerId=persistent_term:get("ServerId"),
    RemoteServerId!{querying,Tag,self(),tweet},
    receive
        {Tweets}->
            printTweets(Tweets,1)  
    end.
printTweets(Tweets,Index)->
    if
        Index>length(Tweets) ->
            ok;
        true ->
            {Tweet,UserName}=lists:nth(Index,Tweets),
            tweetMap!{UserName,Tweet},
            printTweets(Tweets,Index+1)
    end.       
getSubscribedTweets()->
    RemoteServerId=persistent_term:get("ServerId"),
    RemoteServerId!{queryingSubscribedTweets,persistent_term:get("UserName"),self(),tweet},
    receive
        {Tweets}->
            format(Tweets,1)
    end.
format(Tweets,UserIndex)->
        if
            UserIndex>length(Tweets) ->
                ok;
            true ->
                CurrentUserTweets=lists:nth(UserIndex,Tweets),
                {{UserName},CurrentTweets}=CurrentUserTweets,
                % io:format("~p~n",[CurrentUserTweets]),
                printTweets1(CurrentTweets,1,UserName),
                format(Tweets,UserIndex+1)
        end.
        

printTweets1(Tweets,Index,UserName)->
    if
        Index>length(Tweets) ->
            ok;
        true ->
            Tweet=lists:nth(Index,Tweets),
            tweetMap!{UserName,Tweet},
            printTweets1(Tweets,Index+1,UserName)
    end.  
idTweetMap(TweetIdMap,Index)->
    receive
     {UserName,Tweet}->
            TweetId="Tweet"++  integer_to_list(Index),
            % io:format("TweetId=~p~n",[TweetId]),
            NewUserMap=maps:put(TweetId,[UserName,Tweet],TweetIdMap),
            % io:format("~p : ~p  ~s ~n",[UserName,Tweet,TweetId]),
            idTweetMap(NewUserMap,Index+1);
      {TweetId,Pid,someShit}->
        Tweet=maps:find(TweetId,TweetIdMap),
            if
                Tweet==error->
                    io:format("error ocuured~n");
                true ->
                    {ok,OrgTweet}=Tweet,
                    Pid ! {OrgTweet}
            end      
    end. 
reTweet(TweetId)->
    tweetMap! {TweetId,self(),someShit},
    receive
        {Tweet}->
            [UserName,CurrentTweet]=Tweet,
            FormReTweet="Retweeted "++UserName++" : "++CurrentTweet,
            sendreceive:sendTweetToServer(FormReTweet)
    end. 

reTweetAutomation(TweetId,UserName)->
    tweetMap! {TweetId,self(),someShit},
    receive
        {Tweet}->
            [UserName,CurrentTweet]=Tweet,
            FormReTweet="Retweeted "++UserName++" : "++CurrentTweet,
            sendreceive:sendTweetToServerAutomation(FormReTweet,UserName)
    end. 


sendTweetToServerAutomation(Tweet,UserName)->
    RemoteServerId=persistent_term:get("ServerId"),
    RemoteServerId!{UserName,Tweet,self(),tweet},
    receive
        {_}->
                    ok  
    end.  
getSubscribedTweetsAutomation(UserName,RemoteServerId)->
    RemoteServerId!{queryingSubscribedTweets,UserName,self(),tweet},
    receive
        {_}->
            io:format("Got Tweets of ~p~n",[UserName])
    end.  
receiveTweetFromUserAutomation(TweetMapProcessId)->
    receive
        {Message,UserName}->
            TweetMapProcessId!{UserName,Message},
            receiveTweetFromUserAutomation(TweetMapProcessId)
       end.      
 




       



    



 