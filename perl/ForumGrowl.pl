#!/usr/bin/perl

use Mac::Growl;

$Notes = ["Forum-threads"];
$AppName = "ForumGrowl";

Mac::Growl::RegisterNotifications($AppName,$Notes,$Notes);

@old = ();
$isOld = 0;

while(1)
{
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
        
        if($forum[$i]=~/<a href=\"member\.php\?find=lastposter&amp;t=[0-9]+\">([a-zA-Z_0-9]+)<\/a>/)
        {
            $lastposter = $1;
        }
        
        if($forum[$i]=~/<a href=\"#\" onclick=\"who\([0-9]+\); return false;\">(.*)<\/a>/)
        {
            $replies = $1;
            
            $rows = scalar(@old);
            
            #print "rows: $rows\n";
            
            for($j=0;$j<$rows;$j++)
            {
                if($old[$j][0] eq $topic)
                {
                    if($old[$j][1] == $replies)
                    {
                        $isOld = 1;
                    }
                }
            }
            
            if($isOld == 0)
            {
                #print "topic: $topic\ntopicstarter: $topicstarter\nlastposter: $lastposter\nreplies: $replies\n\n";
                Mac::Growl::PostNotification($AppName,"Forum-threads","$topic","topic starter: $topicstarter\nlast poster: $lastposter");
                push(@old,["$topic","$replies"]);
                sleep(2);
            }
            
            else
            {
                $isOld = 0;
            }
            
        }
        
    
    }
    sleep(120);#check for new updates every 2 minutes
}
