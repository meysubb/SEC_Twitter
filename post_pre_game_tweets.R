library(ncaahoopR)
library(lubridate)
library(dplyr)
library(rtweet)
library(rvest)
library(bigballR)


create_token(
  app = Sys.getenv('t_app'),
  consumer_key = Sys.getenv('t_consumer_key'),
  consumer_secret = Sys.getenv('t_consumer_secret'),
  access_token = Sys.getenv('t_access_token'),
  access_secret = Sys.getenv('t_access_secret'))

## Load SEC teams + Hashtags 
## Check if file exists before running code to get teams. 
if(!file.exists("app/sec_teams_list.RDS")){
  source("app/get_sec_teams_list.R")
}
sec_teams <- readRDS("app/sec_teams_list.RDS")
## Date 
today <- Sys.Date()

daily_sched_sec <- get_master_schedule(year(today), month(today), day(today))

daily_sched_sec <-
  daily_sched_sec %>% filter(home %in% sec_teams$sec_teams |
                           away %in% sec_teams$sec_teams) %>% 
  mutate(away = gsub("State","St.",away),
         home = gsub("State","St.",home))


## Get Data from Big Ball R
# sec_today_sched <-
#   get_date_games(date = as.character(format(today, "%m/%d/%Y")), conference = "SEC") %>% 
#   select(Date,Start_Time,Home,Away)
# colnames(sec_today_sched) <- tolower(colnames(sec_today_sched)) 

### Need to clean this up later, before the for loop.
if (nrow(daily_sched_sec) == 0) {
  final_line <- "There are no SEC basketball games today. Enjoy CBB!"
  post_tweet(status = final_line)
  quit()
}

# ### Merge the dataframes together
# if(nrow(daily_sched_sec)==nrow(sec_today_sched)) {
#   daily_sched_sec <-
#     sec_today_sched %>% inner_join(daily_sched_sec, by = c("away", "home"))
# }


## what do i do here when loading to heroku? 
write.csv(daily_sched_sec,"app/daily_sched.csv",row.names = FALSE)

get_game_info <- function(game_id){
  base_url <- "http://www.espn.com/mens-college-basketball/game?gameId="
  full_url <- paste0(base_url,game_id)
  first_nodes <- ".status-detail , .game-network , .icon-location-solid-before , .caption-wrapper"
  second_nodes <- ".line , .status-detail"
  info <- read_html(full_url) %>% html_nodes(first_nodes) %>% html_text()
  info2 <- read_html(full_url) %>% html_nodes(second_nodes)  %>% html_text()
  all_info <- c(info,info2)
  ### go to n-1 (to preserve the line of the game)
  clean_info <- gsub("[^[:alnum:]]", " ", all_info[1:length(all_info)-1])
  clean_info[length(all_info)] <- all_info[length(all_info)]
  trim_info <- trimws(clean_info)
  return(trim_info)
}

for(i in 1:nrow(daily_sched_sec)){
  val <- daily_sched_sec$game_id[i]
  home_team <- daily_sched_sec$home[i]
  home_hashtag <- sec_teams[sec_teams$sec_teams == home_team,'hashtags']
  away_team <- daily_sched_sec$away[i]
  away_hashtag <- sec_teams[sec_teams$sec_teams == away_team,'hashtags']
  
  
  s <- get_game_info(val)
  s <- s[s != ""]
  
  arena <- s[1]
  cov <- s[2]
  line <- s[4]
  
  line1 <- paste0("Today's Game ", i ,": ",away_team, " @ ",home_team," (",arena,"),",cov)
  if('start_time' %in% colnames(daily_sched_sec)){
    start_time <- daily_sched_sec$start_time[i]
    line1 <- paste0("Today's Game ", i ,": ",away_team, " @ ",home_team," (",arena,"), ",start_time," - ",cov)
  }
  
  
  line2 <- paste0("Line: ",line,".")
  line3 <- paste0(home_hashtag," ",away_hashtag)
  
  final_line <- paste(line1,line2,line3)
  post_tweet(status = final_line) 
}

