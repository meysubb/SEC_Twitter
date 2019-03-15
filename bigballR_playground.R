library(bigballR)
library(ncaahoopR)

sec_today <- get_date_games(date=as.character(format(Sys.Date()-7, "%m/%d/%Y")),conference = 'SEC')

library(future)
library(furrr)
library(dplyr)

sec_pbp <- sec_today %>% mutate(
  pbp = future_map(GameID,get_play_by_play,.progress = TRUE))

sec_lineups <- sec_pbp %>% mutate(
  lineups = purrr::map(pbp,get_lineups,keep.dirty=T,garbage.filter=F),
  player_stats = purrr::map(pbp,get_player_stats,keep.dirty=T,garbage.filter=F),
  mins_dist_plot = purrr::map(player_stats,gg_minute_dist_plot))


gg_minute_dist_plot <- function(p_df){
  ### probably a better way to do this. 
  p_df[,7:ncol(p_df)] <- sapply(p_df[,7:ncol(p_df)],as.numeric)
  p_df <- p_df %>% 
    ungroup() %>%   
    arrange(Team,MINS) %>%   
    mutate(.r = row_number())
  
  home_team <- unique(p_df$Home)
  away_team <- unique(p_df$Away)
  home_color <-  ncaa_colors[ncaa_colors$ncaa_name == home_team,'primary_color']
  away_color <-  ncaa_colors[ncaa_colors$ncaa_name == away_team,'primary_color']
  
  ggplot(p_df,aes(x=.r,y=MINS,fill=Team)) + 
    geom_col() + 
    coord_flip() + 
    facet_wrap(~Team,ncol=1,scales='free') +  
    scale_x_continuous(
      breaks = p_df$.r,
      labels = p_df$Player
    ) + 
    labs(title = 'Minutes Distribution',
         subtitle = paste0(away_team,' @ ',home_team),
         caption = '@msubbaiah1\nData courtsey of bigballR(@jakef1873)',
         x = '',
         y = 'Minutes') + 
    theme_bw(base_size=16)  +
    scale_fill_manual(values = c(away_color,home_color)) 
}



### Take top player from each team
top_players_on_off <- function(pbp,lineup){
  player_stats <- get_player_stats(pbp,keep.dirty = T) 
  
  player_name <- player_stats %>% group_by(Team) %>% 
    filter(GS==max(GS)) %>% ungroup() %>% select(Player,Team)
  
  on_off = data.frame()
  
  for(i in 1:nrow(player_name)){
    on_off_stats = on_off_generator(player_name$Player[i],lineup) %>% select(Status,Mins,OEFF,DEFF,NETEFF)
    on_off_stats$Team = player_name$Team[i]
    on_off_stats$spot = toupper(trimws(gsub(player_name$Player[i]," ",on_off_stats$Status)))
    on_off_stats$Status = gsub("\\s*\\w*$", "", on_off_stats$Status)
    on_off = rbind(on_off,on_off_stats)
  }
  off_stats <- on_off %>% filter(spot=='OFF') %>% select(-spot)
  colnames(off_stats) <- paste0(colnames(off_stats),"_off")
  on_stats <- on_off %>% filter(spot == 'ON') %>% select(-spot)
  colnames(on_stats) <- paste0(colnames(on_stats),"_on")
  
  on_off = on_stats %>% inner_join(off_stats,by=c("Status_on"="Status_off")) %>% select(-Team_on) 
  return(on_off)
}


dat = top_players_on_off(sec_lineups$pbp[[4]],sec_lineups$lineups[[4]])
dat = dat[ , order(names(dat),decreasing = T)] %>% select(Status_on,Team_off,everything())

ggplot(dat,aes(x=variable,y=value,fill=spot)) + 
  geom_bar(stat='identity') + 
  coord_flip() + 
  facet_wrap(Team~.,scales='free') + theme_bw() + 
  scale_y_continuous(breaks=seq(-140,140,10),labels=abs(seq(-140,140,10)))
 
ggplot(dat,aes(x=variable,y=value,fill=spot)) + geom_bar(stat='identity',position='dodge') + 
  facet_wrap(Team~variable,scales='free',ncol=4) + theme_bw()


### Top Players total different lineups
for(i in 1:nrow(player_name)){
  player_lineup_stats = get_player_lineups(sec_lineups$lineups[[4]],Included = player_name$Player[i])
  
  pct_total_lineups = nrow(player_lineup_stats)/nrow(sec_lineups$lineups[[4]]%>% filter(Team==player_name$Team[i]))
  on_off_stats = on_off_generator(player_name$Player[i],sec_lineups$lineups[[4]]) %>% select(Status,Mins,OEFF,DEFF,NETEFF,PACE)
}

dat <- reshape2::melt(on_off_stats,id="Status")

