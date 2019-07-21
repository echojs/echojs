require_relative 'app'

# init required by the methods we will call
$r = setup_redis
Comments = RedisComments.new($r,"comment",proc{|c,level|
    c.sort {|a,b|
        ascore = compute_comment_score a
        bscore = compute_comment_score b
        if ascore == bscore
            # If score is the same favor newer comments
            b['ctime'].to_i <=> a['ctime'].to_i
        else
            # If score is different order by score.
            # FIXME: do something smarter favouring newest comments
            # but only in the short time.
            bscore <=> ascore
        end
    }
})

###############################################################################
# Anti Spam tools
###############################################################################

# Search for a user, delete its comments and news 
def delete_user(username)
    user = get_user_by_username(username)
    
    # an admin cannot delete himself
    return 0 if user_is_admin?(user)

    if user
        puts "user found #{user}"
        # getting news and comments
        user_comments = get_user_comments(user["id"],0,100000)
        user_news = get_posted_news(user["id"],0,100000)

        # deleting comments
        nb_comments = user_comments[1]
        puts "User has #{nb_comments} comments"
        if nb_comments > 0
            # puts "Comments #{user_comments}"
            puts "Deleting comments"
            # Call insert_comment(news_id,user_id,comment_id,parent_id,body) and parent_id doesn't matter in that case
            user_comments[0].each{|c|
                puts "calling insert_comment(#{c[:news_id]},#{c[:user_id]},#{c[:id]},nil,'')"
                insert_comment(c[:news_id],c[:user_id],c[:id],nil,'')
            }
        end

        # deleting news
        active_news = user_news[0].select{ |item| item["del"] != "1" }
        nb_news = active_news.count
        puts "User has #{nb_news} news"
        if nb_news > 0
            # puts "News #{active_news}"
            puts "Deleting news"
            # call del_news(news_id,user_id)
            active_news.each{|n|
                puts "calling del_news(#{n["id"]}, #{n["user_id"]}, true)"
                del_news(n["id"], n["user_id"], true)
            }
        end

        # banning user
        ban_user(username)
    else
        puts "User not found #{username}"
    end
end

def ban_user(username)
    user = get_user_by_username(username)

    # an admin cannot delete himself
    return 0 if user_is_admin?(user)

    if user
        rand_number = get_rand

        # DEL auth:auth
        $r.del("auth:#{user["auth"]}")
        # HMSET user:NN salt ""
        # HMSET user:NN password ""
        # HMSET user:NN auth ""
        # HMSET user:NN apisecret ""
        $r.hmset("user:#{user["id"]}","salt","","password",rand_number,"auth","","apisecret","")

        puts "Banned #{user["username"]} successfully"
    else
        puts "User not found #{username}"
    end
end