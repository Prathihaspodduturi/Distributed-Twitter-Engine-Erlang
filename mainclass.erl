-module(mainclass).

-export([startTheRegistration/0,startTwitter/0,signInBuffer/0,sendTweet/0,getUsersList/0,subscribe/0,signInOut/0,
myMentions/0,queryHashTag/0,getSubscribedTweets/0,reTweet/0]).

startTheRegistration()->
    io:format("~s~n",["Welcome to the twitter clone"]),
    {ok,[SignIn]}=io:fread("Do you want to SignIn or register For Signin enter S for register R","~ts"),
    if
        (SignIn=="S")->
            register:signInUser();
        true->
            register:registerUser()
    end.
signInBuffer()->
    receive
        % for SignIn
        {UserName,PasswordAndProcess,Pid}->
            userregister ! {UserName,PasswordAndProcess,self(),Pid};
        % for Registeration    
        {UserName,PassWord,Email,Pid,register}->
            userregister ! {UserName,PassWord,Email,self(),Pid};
        % For receiving user's tweets and quering them        
        {UserName,Tweet,Pid,tweet}->
            if
                UserName==querying ->
                    hashTagMap!{Tweet,self(),Pid}; 
                UserName==queryingSubscribedTweets->
                    % Tweet is UserName
                    subscribeToUser!{Tweet,self(),Pid,tweet}; 
                true ->
                 receiveTweet !{UserName,Tweet,self(),Pid} 
            end;
        {UserName,Pid}->
            if 
                Pid==signOut->
                    [UserName1,RemoteNodePid]=UserName,
                    userProcessIdMap!{UserName1,RemoteNodePid,self(),randomShitAgain};
                true->
                 receiveTweet !{UserName,self(),Pid}
            end;     
        {Pid}->
            userregister ! {self(),Pid,"goodMorningMate"};    
        {UserName,CurrrentUserName,Pid,PidOfReceive}->
            subscribeToUser ! {UserName,CurrrentUserName,PidOfReceive,self(),Pid}
    end,
    receive
        {Message,Pid1}->
            Pid1 ! {Message},
            signInBuffer()        
    end.    
startTwitter()->
    List1 = [{"a","sample"}],
    List2=[{"venkat",["hi"]}],
    List3=[{"#Cr7","The Greatest footballer of all time is #Cr7"}],
    List4=[{"a",[]}],
    List5=[{"Il","Random"}],
    Map1 = maps:from_list(List1),
    Map2 = maps:from_list(List2),
    Map3= maps:from_list(List3),
    Map4=maps:from_list(List4),
    Map6=maps:from_list(List4),
    Map5=maps:from_list(List5),
    Map6=maps:from_list(List4),
    register(userregister,spawn(list_to_atom("centralserver@VenkatsaiROGG15"),register,recieveMessage,[Map1])),
    register(receiveTweet,spawn(list_to_atom("centralserver@VenkatsaiROGG15"),sendreceive,getTweetFromUser,[Map2])),
    register(hashTagMap,spawn(list_to_atom("centralserver@VenkatsaiROGG15"),sendreceive,hashTagTweetMap,[Map3])),
    register(subscribeToUser,spawn(list_to_atom("centralserver@VenkatsaiROGG15"),register,userSubscriberMap,[Map4,Map6])),
    register(userProcessIdMap,spawn(list_to_atom("centralserver@VenkatsaiROGG15"),register,userProcessIdMap,[Map5])).
sendTweet()->
    Tweet1=io:get_line("Enter Your Tweet "),
    Tweet=lists:nth(1,string:tokens(Tweet1,"\n")),
    try sendreceive:sendTweetToServer(Tweet)
    catch 
    error:_ -> 
      io:format("User Not Signed in~n") 
    end.   
getUsersList()->
    % try register:getUsersList()
    % catch
    %     error:_ ->
    %         io:format("User Not Signed in~n")  
    % end.
    spawn(register,getUsersList,[]).  
subscribe()->
    UserName1=io:get_line("Enter User You want to subscribe to"),
    UserName=lists:nth(1,string:tokens(UserName1,"\n")),
    register:subscribeToUser(UserName).
signInOut()->
    register:signOutUser().
myMentions()->
    sendreceive:myMentions().
queryHashTag()->
    HashTag=io:get_line("Enter HashTag you want to query"),
    HashTag1=lists:nth(1,string:tokens(HashTag,"\n")),
    sendreceive:queryHashTag(HashTag1).
getSubscribedTweets()->
    sendreceive:getSubscribedTweets().   
reTweet()->
    TweetId1=io:get_line("Enter Id of Tweet You want to ReTweet"),
    TweetId=lists:nth(1,string:tokens(TweetId1,"\n")),
    sendreceive:reTweet(TweetId).





