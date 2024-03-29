library(ncaahoopR)
library(rtweet)
library(dplyr)
library(ggplot2)
library(lubridate)


create_token(
  app = Sys.getenv('t_app'),
  consumer_key = Sys.getenv('t_consumer_key'),
  consumer_secret = Sys.getenv('t_consumer_secret'),
  access_token = Sys.getenv('t_access_token'),
  access_secret = Sys.getenv('t_access_secret'))

## Load Data
sec_teams <- readRDS("app/sec_teams_list.RDS") %>% 
  mutate_all(as.character)

today <- Sys.Date()-1

daily_sched_sec <- get_master_schedule(year(today), month(today), day(today))

daily_sched_sec <-
  daily_sched_sec %>% filter(home %in% sec_teams$sec_teams |
                               away %in% sec_teams$sec_teams) %>% 
  mutate(away = gsub("State","St.",away),
         home = gsub("State","St.",home))


if(nrow(daily_sched_sec)==0){
  quit()
}

daily_sched_sec <- daily_sched_sec %>% 
  mutate(home = as.character(home),
         away = as.character(away))



for(i in 1:nrow(daily_sched_sec)){
  val <- daily_sched_sec$game_id[i]
  home_team <- daily_sched_sec$home[i]
  home_hashtag <- sec_teams[sec_teams$sec_teams == home_team,'hashtags']
  away_team <- daily_sched_sec$away[i]
  away_hashtag <- sec_teams[sec_teams$sec_teams == away_team,'hashtags']
  
  home_color <-  ncaa_colors[ncaa_colors$ncaa_name == home_team,'primary_color']
  away_color <-  ncaa_colors[ncaa_colors$ncaa_name == away_team,'primary_color']
  if (length(home_color)==0){
    team_name = sec_teams[sec_teams$hashtags == home_hashtag & !sec_teams$sec_teams == home_team,"sec_teams"]
    home_color <- ncaa_colors[ncaa_colors$espn_name == team_name,'primary_color']
  }
  if (length(away_color)==0){
    team_name = sec_teams[sec_teams$hashtags == away_hashtag & !sec_teams$sec_teams == away_team,"sec_teams"]
    away_color <- ncaa_colors[ncaa_colors$espn_name == team_name,'primary_color']
    if(home_color == away_color){
      away_color <- ncaa_colors[ncaa_colors$ncaa_name == team_name,'secondary_color']
    }
  }
  
  if(home_color == away_color){
    away_color <- ncaa_colors[ncaa_colors$ncaa_name == away_team,'secondary_color']
  }
  
  ## Get/Save WP Chart 
  ggsave(
    'app/wp_chart_plot.png',
    gg_wp_chart(val, home_color, away_color, show_labels = T),
    height = 8,
    width = 12
  )
  
  tweet_text <- paste0("WP Plots for ",away_team," @ ",home_team,". ",home_hashtag," ",away_hashtag)
  post_tweet(status = tweet_text,media = 'app/wp_chart_plot.png') 
}
