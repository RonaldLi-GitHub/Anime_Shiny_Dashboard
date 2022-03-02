library(XML)
library("methods")
library(RCurl)
library(dplyr)
library(stringr)
 
# The URL below contains all titles in the Anime News Network database
report_URL <- "https://www.animenewsnetwork.com/encyclopedia/reports.xml?id=155&nlist=all"
api_URL <- "https://cdn.animenewsnetwork.com/encyclopedia/api.xml"
# The following converts the XML into a dataframe
report_df <- report_URL %>%
  getURL() %>%
  xmlParse() %>%
  xmlToDataFrame()

# For this project, the focus on the following types of title: movie, TV
# The goal is to obtain all ids to be used for later API call
lookup_table_full <- report_df %>%
  filter(type %in% c("movie", "TV")) %>%
  select(id, type, name, vintage)

# The goal is to capture the following information and place in the data frame
# adaptation status, genre, theme, vintage, votes, score.

get_related_var <- function(src, relate_type, elem_val){
  tryCatch(
   expr={
     src_list=src[names(src)==relate_type]
     src_list_final=src_list[sapply(src_list, function(x)getElement(x, "rel") == elem_val)]
     
     if(length(src_list_final)==1) {
     return (getElement(src_list_final[[1]], "id"))
       }
     else if(length(src_list_final)>1){
     return (str_c(sapply(src_list_final, function(x)getElement(x, "id")), collapse = "/"))   
     }
     else {
     return ("NA")
     }
   },
   error=function(e){
     return ("NA") 
   }
)
}

get_info_var <- function(src, type_val){
  tryCatch(
    expr={
      src_list=src[names(src)=="info"]
      src_list_final=src_list[sapply(src_list, function(x)getElement(x$.attrs, "type" ) == type_val)]
      if(length(src_list_final)==1){
        return (src_list_final[[1]]$text)
      }
      else if (length(src_list_final)>1){
        return (str_c(sapply(src_list_final, function(x)x$text), collapse = "/")) 
      }
      else {
        return ("NA")
      }
      },
    error=function(e){
      return ("NA") 
    }
  )
}

get_rating_var <- function(src, rating_val){
  tryCatch(
    expr={
      src_list=src[names(src)=="ratings"]
      if(length(src_list)>=1){
      return (getElement(src_list$ratings, rating_val))
      }
      else {
      return ("NA")
      }
      },
    error=function(e){
      return ("NA") 
    }
  )
}
  
# Get the vintage years (beginning year and ending year) for each anime title
get_begin_year <- function (date){
  return (str_extract(date, "[0-9]{4}"))
}

get_end_year <- function (date){
  return (sapply(date, function(x)str_extract_all(x, "[0-9]{4}")[[1]][2])) 
}

lookup_table<- lookup_table_full %>%
  mutate(begin_year=get_begin_year(vintage), end_year=get_end_year(vintage)) 

lookup_table=filter(lookup_table, id !=16857)

# Initiate the data frame to store the data
df=data.frame()
# Start the loop, table api call is able to retrieve 50 titles (50 is current maximum limit allowed)
for (i in seq(1, nrow(lookup_table), 50)) {
  api_link=str_c(api_URL, "?title=", paste0(lookup_table[i:min(i+49,nrow(lookup_table)) ,"id"], "/", collapse=""), collapse = "")
  api_source= api_link %>%
    getURL() %>%
    xmlParse() %>%
    xmlToList()
  for (j in 0:min(49,nrow(lookup_table)-i) ){
  df[i+j,"id"]=lookup_table[i+j,"id"]
  df[i+j,"type"]=lookup_table[i+j,"type"]
  df[i+j,"name"]=lookup_table[i+j,"name"]
  df[i+j,"vintage"]=lookup_table[i+j,"vintage"]
  df[i+j, "adapted_from"]=get_related_var(api_source[[j+1]], "related-prev", "adapted from")
  df[i+j, "adaptation"]=get_related_var(api_source[[j+1]], "related-next", "adaptation")
  df[i+j, "sequel"]=get_related_var(api_source[[j+1]], "related-next", "sequel")
  df[i+j, "related"]=get_related_var(api_source[[j+1]], "related-next", "related")
  df[i+j, "spinoff"]=get_related_var(api_source[[j+1]], "related-next", "spinoff")
  df[i+j, "episode_count"]=get_info_var(api_source[[j+1]], "Number of episodes")
  df[i+j, "genres"]=get_info_var(api_source[[j+1]], "Genres")
  df[i+j, "themes"]=get_info_var(api_source[[j+1]], "Themes")
  df[i+j, "nb_votes"]=get_rating_var(api_source[[j+1]], "nb_votes")
  df[i+j, "weighted_score"]=get_rating_var(api_source[[j+1]], "weighted_score")
  df[i+j, "bayesian_score"]=get_rating_var(api_source[[j+1]], "bayesian_score")
  }
  Sys.sleep(1)
  }

# Add the vintage years variables and replace missing values with "NA"
data<- df %>%
  mutate(begin_year=get_begin_year(vintage), end_year=get_end_year(vintage))
data[is.na(data)]="NA"

# Export the data to a csv file
write.csv(data, "df_data.csv", row.names = FALSE)


