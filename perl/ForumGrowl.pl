#!/usr/bin/perl

use Mac::Growl;

$Notes = ["Forum-threads"];
$AppName = "ForumGrowl";

Mac::Growl::RegisterNotifications($AppName,$Notes,$Notes);

@old = ();
$isOld = 0;
$separator = 0;

if (-e "data.txt")
{
    open (INFILE,"data.txt");
    print "Loading datafile...\n";
    while( <INFILE> ) 
    {
        if($_=~/(.*),([0-9]+)/)
        {
            push(@old,["$1","$2"]);
        }
    }
    close (INFILE);
}

while(1)
{   
    print "Updating forum data...\n";
    @forum = split(/\n/,`curl -s "http://www.funmac.com/forumdisplay.php?s=&forumid=38&styleid=10"`);
    $size = @forum;
    
    for($i=0;$i<$size;$i++)
    {
        if($forum[$i]=~/<a href="showthread\.php\?s=[A-Za-z0-9]+&amp;t=[0-9]+">(.*)<\/a>/)
        {
            $topic = $1;
            $topic =~ s/&quot;/\"/g;
        }
        
        if($forum[$i]=~/<span style=\"cursor:pointer\" onclick=\"window\.open\('member\.php\?s=.*&amp;u=.*'\)\">(.*)<\/span>/)
        {
            $topicstarter = $1;
        }
        
        if($forum[$i]=~/<a href=\"member\.php\?find=lastposter&amp;t=[0-9]+\">(.*)<\/a>  /)
        {
            $lastposter = $1;
        }
        
        if($forum[$i]=~/<a href=\"#\" onclick=\"who\([0-9]+\); return false;\">(.*)<\/a>/)
        {
            $replies = $1;
            
            $rows = scalar(@old);
                        
            for($j=0;$j<$rows;$j++)
            {
                if($old[$j][0] eq $topic)
                {
                    $isOld = 1; #thread is old
                    
                    if($old[$j][1] == $replies)
                    {
                        $newReply = -1; #no new replies    
                    }
                    
                    else
                    {
                        $newReply = $j; #new reply, save array index
                    }
                }
            }
            
            if($isOld == 0)
            {
                if($separator == 0)
                {
                    print "------------------------------\n";
                    $separator = 1;
                }
                print "\(NEW THREAD\)\ntopic: $topic\ntopicstarter: $topicstarter\nlastposter: $lastposter\nreplies: $replies\n";
                print "------------------------------\n";
                Mac::Growl::PostNotification($AppName,"Forum-threads","$topic","topic starter: $topicstarter\nlast poster: $lastposter");
                push(@old,["$topic","$replies"]);
                sleep(2);
            }
            
            if(($isOld == 1) && ($newReply != -1))
            {
                if($separator == 0)
                {
                    print "------------------------------\n";
                    $separator = 1;
                }
                print "\(NEW REPLY\)\ntopic: $topic\ntopicstarter: $topicstarter\nlastposter: $lastposter\nreplies: $replies\n";
                print "------------------------------\n";
                Mac::Growl::PostNotification($AppName,"Forum-threads","$topic","topic starter: $topicstarter\nlast poster: $lastposter");
                $old[$newReply][1] = $replies;
                sleep(2);            
            }
            
            $isOld = 0;
            $newReply = -1;
            
        }
        
    
    }
    
    $separator = 0;
    $rows = scalar(@old);
    print "Saving datafile...\n";
    open(OUTFILE, ">data.txt");
    for($k=0;$k<$rows;$k++)
    {
        print OUTFILE "$old[$k][0],$old[$k][1]\n";
    }
    close(OUTFILE);

    print "Waiting 2 minutes for next update...\n";

    sleep(120);
}
