library(dplyr)
library(rvest)
kp_url <- "https://kenpom.com/"

test <- read_html(kp_url) %>% html_nodes('thead:nth-child(1) a , thead:nth-child(1) .conf , td') %>% html_text()

cols <- test[1:14]
cols <- cols[-which(grepl('\\bL\\b',cols))]
cols[grepl('W',cols)] <-paste0(cols[grepl('W',cols)],"-L")


adj_cols <- rep(cols[6:length(cols)],each=2)
even_seq <- seq(1,length(adj_cols))%%2 == 0
adj_cols[even_seq] <- paste0(adj_cols[even_seq],'_rankings')

final_cols <- c(cols[1:5],adj_cols)

final_cols[14:19] <- paste0("SOS_",final_cols[14:19])
final_cols[c(length(final_cols)-1,length(final_cols))] <- paste0("NCSOS_",final_cols[c(length(final_cols)-1,length(final_cols))]) 

test2 <- test[-(1:14)]

kp_df <- data.frame(matrix(test2,byrow = T,ncol=21))
colnames(kp_df) <- final_cols

sec_kp_df <- kp_df %>% filter(Conf=="SEC")

sec_kp_df[,c(1,4:ncol(sec_kp_df))] <- apply(sec_kp_df[,c(1,4:ncol(sec_kp_df))],2,function(x) as.numeric(as.character(x)))
       