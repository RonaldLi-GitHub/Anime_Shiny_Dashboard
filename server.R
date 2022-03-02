library(ggplot2)
library(dplyr)
library(stringdist)
library("scales")
library(devtools)
library(summaryBox)
library(shinydashboard)
library(stringr)
library(plotly)
library(shinyvalidate)
library(wordcloud)

df=read.csv("df_data.csv")

genres_list=vector()

for (i in 1:nrow(df)){
  for (item in str_split(df[i,"genres"], "/")[[1]]){
  if( ! item %in% genres_list )  {
    genres_list=c(genres_list, item)
    
  }
}
}



df_year=df%>%
  group_by(begin_year)%>%
  mutate(p_rank_score=percent(percent_rank(weighted_score)), rank_score=dense_rank(desc(weighted_score)),
         p_rank_vote=percent(percent_rank(nb_votes)), rank_vote=dense_rank(desc(nb_votes))
         )

df_overall=df%>%
  mutate(p_rank_score=percent(percent_rank(weighted_score)), rank_score=dense_rank(desc(weighted_score)),
         p_rank_vote=percent(percent_rank(nb_votes)), rank_vote=dense_rank(desc(nb_votes))
  )



df_genre=df%>%
  group_by(begin_year)%>%
  summarise(mean_rating = mean(weighted_score, na.rm = TRUE))


NUM_PAGES=2


name_match <- function(x){
  match_list=unique(df$name)
  matrix=stringdistmatrix(x, match_list, method="cosine")
  matrix=data.frame(t(matrix))
  matrix=cbind(match_list, matrix)
  colnames(matrix)=c("Titles", "Match_Score")
  return (matrix)
  
}

checkRange1 <- function(value, input){
  if(!is.na(value) & (value < 1979 || value > 2021)){
   "Please specify a year that is within the range: 1979 to 2021"
  }
}

checkRange2 <- function(value, input){
  if(!is.na(value) & (value < input$year_start || value > 2021)){
    paste0("Please specify a year that is within the range: ", input$year_start, " to ", 2021)
  }
}




server <- function(input, output, session) {
  
  val <- reactiveValues(search_val="", page=1, search_list="", df_temp =NULL,
                        current_id=NULL)
  
  observeEvent(input$go, {val$search_val <-{input$textin} })
  
  observeEvent(input$clear, {val$search_val <-{""} })
  
  
  observe({
    toggleState(id = "prevBtn", condition = val$page > 1)
    toggleState(id = "nextBtn", condition = val$page < NUM_PAGES)
    hide(selector = ".page")
    show(paste0("step", val$page))
  })
  
  navPage <- function(direction) {
    val$page <- val$page + direction
  }
  
  observeEvent(input$prevBtn, navPage(-1))
  observeEvent(input$nextBtn, navPage(1))
  
  observeEvent(input$go, {val$df_temp=df %>%
    merge(name_match(val$search_val), by.x="name", by.y="Titles", all.x=TRUE)%>%
    arrange(Match_Score)%>%
    select(id, type, name, vintage, episode_count, genres)%>%
    slice_head(n=5)
    })
  
  observeEvent(input$go, {val$search_list=paste(val$df_temp$id,val$df_temp$name) })
  
  observeEvent(input$clear, {val$search_list=""
  val$current_id=NULL
  
  })
  
  observeEvent(input$year_start, {
    updateNumericInput(session, "year_end", value=input$year_start, min=input$year_start)})
  
  iv <- InputValidator$new()
  iv$add_rule("year", sv_required())
  iv$add_rule("year", checkRange1, input)
  iv$add_rule("year_start", sv_required())
  iv$add_rule("year_end",sv_required())
  iv$add_rule("year_start", checkRange1, input)
  iv$add_rule("year_end",checkRange2, input)
  iv$enable()
  
  output$plot <- renderPlotly({
   p <- df %>%
    filter(!is.na(weighted_score) & type==input$select & begin_year==input$year) %>%
    top_n(input$n,weighted_score ) %>%
    rename(score=weighted_score) %>%
    mutate(name=reorder(name, score))%>%
    ggplot(aes(x=name, y=score))
   
   p <- p+ geom_bar(stat="identity", fill="#add8e6")+
   coord_flip()+
     ggtitle(paste("Top", input$n, "Titles in Review Score"))+
     theme(plot.title = element_text(size=12, face="bold"),
       axis.title.x=element_blank(), axis.title.y=element_blank())
  
   
   ggplotly(p)
  })
  
  output$plot0.5 <- renderPlotly({
    p <- df %>%
      filter(!is.na(nb_votes) & type==input$select & begin_year==input$year) %>%
      top_n(input$n,nb_votes ) %>%
      rename(votes=nb_votes) %>%
      mutate(name=reorder(name, votes))%>%
      ggplot(aes(x=name, y=votes))
    
    p <- p+ geom_bar(stat="identity", fill = "#9dd8c5")+
      coord_flip()+
      ggtitle(paste("Top", input$n, "Titles in Vote Count"))+
      theme(plot.title = element_text(size=12, face="bold"),
            axis.title.x=element_blank(), axis.title.y=element_blank())
    
    
    ggplotly(p)
  })
  
  output$wordplot <- renderPlot({
    temp_df= df %>%
      filter(!is.na(weighted_score) & type==input$select & begin_year==input$year) %>%
      top_n(input$n,weighted_score )
    
    genres=temp_df$genres %>%
      str_split("/") %>%
      unlist()
    
    genres=genres[!is.na(genres)]
    
    genres_freq=as.data.frame(table(genres))
    colnames(genres_freq)[1]="Genre"
    
    layout(matrix(c(1, 2), nrow=2), heights=c(1, 4))
    par(mar=rep(0, 4))
    plot.new()
    text(x = 0.5, y = 0.5, paste("Genres in Top", input$n, "Titles"), cex = 1.5, font = 2)
    
    wordcloud(genres_freq$Genre, genres_freq$Freq,min.freq = 1,
              max.words=30, random.order=FALSE, rot.per=0, 
              colors=brewer.pal(8, "Dark2"))
    
    
    
  })

  
  output$plot2 <- renderPlotly({
    
    p <- df%>%
      filter(grepl(input$genre, genres) & between (begin_year, input$year_start, input$year_end))%>%
      rename(votes=nb_votes, score=weighted_score, anime_type=type)%>%
      ggplot(aes(votes, score))
    
    p <- p+ geom_point(aes(color=anime_type))+
      labs(x="Votes", y="Rating", title="Votes vs. Rating")
    
    ggplotly(p)
    }
  )
  
  output$plot3 <- renderPlotly({
    p <-  df%>%
      filter(grepl(input$genre, genres) & between (begin_year, input$year_start, input$year_end))%>%
      mutate(vintage_year=factor(begin_year), anime_type=factor(type))%>%
      
      ggplot(aes(vintage_year,fill=anime_type))
    
    p <- p+ geom_histogram(stat = "count")+
      labs(x="Year", y="Count", title="Number of Titles")
    
    ggplotly(p)  
      
  }
  )
  
  output$plot4 <- renderPlotly({
    p <- df%>%
      filter(grepl(input$genre, genres) & between (begin_year, input$year_start, input$year_end))%>%
      group_by(begin_year, type)%>%
      summarise(average_rating = mean(weighted_score, na.rm = TRUE), anime_type=max(type))%>%
      mutate(vintage_year=factor(begin_year))%>%
      ggplot(aes(vintage_year, average_rating, fill=anime_type))
    
    p <- p+ geom_bar(stat = "identity",position = "stack")+
      scale_y_continuous(labels = scales::comma)+
      labs(x="Year", y="Rating", title="Average Review Rating")
    
    ggplotly(p)
    
  }
  )
  output$plot5 <- renderPlotly({
    p <- df%>%
      filter(grepl(input$genre, genres) & between (begin_year, input$year_start, input$year_end))%>%
      group_by(begin_year, type)%>%
      summarise(average_votes = sum(nb_votes, na.rm = TRUE), anime_type=max(type) )%>%
      mutate(vintage_year=factor(begin_year))%>%
      ggplot(aes(vintage_year, average_votes, fill=anime_type))
    
    p <- p+ geom_bar(stat = "identity",position = "stack")+
      scale_y_continuous(labels = scales::comma)+
      labs(x="Year", y="Votes", title="Totle Votes")
    
    ggplotly(p)
    
    
  }
  )
  
  output$textoutput <- renderTable({
    
    if (val$page ==1){
      if(val$search_val!=""){
        val$df_temp 
      }
    }
    
    else {
    }
  }
    )
  
  output$plot_hoverinfo <- renderPrint({
    cat("Hover (throttled):\n")
    str(input$plot_hover)
  })
  
  observe({
    updateSelectInput(session, "selectdata", label="Select which one",
                      choices=val$search_list)
    
  }  
  )
  
  
  output$var2 <- renderText({if(val$search_list!=""){val$df_temp[1,"name"]}})
  output$var3 <- renderText({if(val$search_list!=""){val$df_temp[1,"type"]}})
  output$var4 <- renderText({if(val$search_list!=""){val$df_temp[1,"vintage"]}})
  output$var5 <- renderText({if(val$search_list!=""){val$df_temp[1,"genres"]}})
  output$var6 <- renderText({if(val$search_list!=""){val$df_temp[1,"episode_count"]}})
  
  output$var8 <- renderText({if(val$search_list!=""){val$df_temp[2,"name"]}})
  output$var9 <- renderText({if(val$search_list!=""){val$df_temp[2,"type"]}})
  output$var10 <- renderText({if(val$search_list!=""){val$df_temp[2,"vintage"]}})
  output$var11 <- renderText({if(val$search_list!=""){val$df_temp[2,"genres"]}})
  output$var12 <- renderText({if(val$search_list!=""){val$df_temp[2,"episode_count"]}})
  
  output$var13 <- renderText({if(val$search_list!=""){val$df_temp[3,"name"]}})
  output$var14 <- renderText({if(val$search_list!=""){val$df_temp[3,"type"]}})
  output$var15 <- renderText({if(val$search_list!=""){val$df_temp[3,"vintage"]}})
  output$var16 <- renderText({if(val$search_list!=""){val$df_temp[3,"genres"]}})
  output$var17 <- renderText({if(val$search_list!=""){val$df_temp[3,"episode_count"]}})
  
  output$var18 <- renderText({if(val$search_list!=""){val$df_temp[4,"name"]}})
  output$var19 <- renderText({if(val$search_list!=""){val$df_temp[4,"type"]}})
  output$var20 <- renderText({if(val$search_list!=""){val$df_temp[4,"vintage"]}})
  output$var21 <- renderText({if(val$search_list!=""){val$df_temp[4,"genres"]}})
  output$var22 <- renderText({if(val$search_list!=""){val$df_temp[4,"episode_count"]}})
  
  output$var23 <- renderText({if(val$search_list!=""){val$df_temp[5,"name"]}})
  output$var24 <- renderText({if(val$search_list!=""){val$df_temp[5,"type"]}})
  output$var25 <- renderText({if(val$search_list!=""){val$df_temp[5,"vintage"]}})
  output$var26 <- renderText({if(val$search_list!=""){val$df_temp[5,"genres"]}})
  output$var27 <- renderText({if(val$search_list!=""){val$df_temp[5,"episode_count"]}})
  
  observeEvent (input$clear,
    {if(val$search_list==""){
    shinyjs::hide(id = "go1")
    shinyjs::hide(id = "go2")
    shinyjs::hide(id = "go3")
    shinyjs::hide(id = "go4")
    shinyjs::hide(id = "go5")
      
  }
  else {
    shinyjs::show(id = "go1")
    shinyjs::show(id = "go2")
    shinyjs::show(id = "go3")
    shinyjs::show(id = "go4")
    shinyjs::show(id = "go5")
  }
    })
  
  observeEvent (input$go,
                {if(val$search_list!=""){
                  shinyjs::show(id = "go1")
                  shinyjs::show(id = "go2")
                  shinyjs::show(id = "go3")
                  shinyjs::show(id = "go4")
                  shinyjs::show(id = "go5")
                }
                  else {
                    shinyjs::hide(id = "go1")
                    shinyjs::hide(id = "go2")
                    shinyjs::hide(id = "go3")
                    shinyjs::hide(id = "go4")
                    shinyjs::hide(id = "go5")
                  }
                })

  
  
  output$summarybox <- renderUI({
    
    if(!is.null(val$current_id)){
      fluidPage(
        
        
        fluidRow(style='height:3vh', column(8, tags$b(paste("Anime Title:", filter(df_overall, id==val$current_id)$name, ",
    Vintage Year: ",filter(df_overall, id==val$current_id)$begin_year, ", Review Score:", filter(df_overall, id==val$current_id)$weighted_score,
    ", Vote Count: ",filter(df_overall, id==val$current_id)$nb_votes )))),  
        
    fluidRow(column(4, tags$b("Review Score Overall")),  column(4, tags$b("Vote Count Overall"))),   
    fluidRow(box(width = '100%',
                 summaryBox2("Percentile Rank", filter(df_overall, id==val$current_id)$p_rank_score, width = 2, icon ="fas fa-percent", style = "success text-white"),
                 summaryBox2("Rank", filter(df_overall, id==val$current_id)$rank_score, width = 2, icon = " 	fa fa-calculator", style = "info"),
 
                 summaryBox2("Percentile Rank", filter(df_overall, id==val$current_id)$p_rank_vote,width = 2, icon =  	"fas fa-percent", style = "success text-white"),
                 summaryBox2("Rank",  filter(df_overall, id==val$current_id)$rank_vote, width = 2, icon = " 	fa fa-calculator", style = "info")
      
      )
    ),
    
    
    fluidRow(column(4, tags$b(paste("Review Score ", filter(df_overall, id==val$current_id)$begin_year))), column(4, tags$b(paste("Vote Count ", filter(df_overall, id==val$current_id)$begin_year)))),
    
    
    fluidRow(box(width = '100%',
                
                 summaryBox2("Percentile Rank", filter(df_year, id==val$current_id)$p_rank_score, width = 2, icon =  	"fas fa-percent", style = "success text-white"),
                 summaryBox2("Rank ", filter(df_year, id==val$current_id)$rank_score, width = 2, icon = " 	fa fa-calculator", style = "info"),
                
                 summaryBox2("Percentile Rank", filter(df_year, id==val$current_id)$p_rank_vote, width = 2, icon =  	"fas fa-percent", style = "success text-white"),
                 summaryBox2("Rank", filter(df_year, id==val$current_id)$rank_vote, width = 2, icon = " 	fa fa-calculator", style = "info")
    )
    ),
    
    
    fluidRow( column(4, renderPlot({
      
      layout(matrix(1:2, nc=2), widths=c(5,4,5))
      par(las=1, mar=c(2,4,5,0))
      
     boxplot(df$weighted_score, ylim=c(0,10), ylab="Review Score", col="lightgreen")
     text(x=1, y=filter(df_overall, id==val$current_id)$weighted_score, filter(df_overall, id==val$current_id)$name)
      title(main="Overall", line=1)
      par(mar=c(2,1,5,0))
     boxplot(filter(df, begin_year==filter(df_overall, id==val$current_id)$begin_year)$weighted_score, yaxt="n", ylim=c(0,10), col="lightblue1")
     title(main=filter(df_overall, id==val$current_id)$begin_year, line=1)
     text(x=1,y=filter(df_overall, id==val$current_id)$weighted_score, filter(df_overall, id==val$current_id)$name)
    
    })
    ),
    column(4, renderPlot({
      layout(matrix(1:2, nc=2), widths=c(5,4,5))
      par(las=1, mar=c(2,4,5,0))
      
      boxplot(df$nb_votes, ylim=c(1,13466), ylab="Vote Count", col="lightgreen")
      text(x=1, y=filter(df_overall, id==val$current_id)$nb_votes, filter(df_overall, id==val$current_id)$name)
      title(main="Overall", line=1)
      par(mar=c(2,1,5,0))
      boxplot(filter(df, begin_year==filter(df_overall, id==val$current_id)$begin_year)$nb_votes, yaxt="n", ylim=c(1,13466), col="lightblue1")
      title(main=filter(df_overall, id==val$current_id)$begin_year, line=1)
      text(x=1,y=filter(df_overall, id==val$current_id)$nb_votes, filter(df_overall, id==val$current_id)$name)
      
    })
    )
    ),
    
    fluidRow(column(8, actionButton("backtomain", "Go Back"), align = "center"), style='padding-top:10px;')
    
    ) #fluid page end
    }
    
    
  })
  
  
  output$OverallBox = renderValueBox({
    
    if(!is.null(val$current_id)){
      valueBox(filter(df_overall, id==val$current_id)$p_rank_score, "rank", icon = NULL, color = "aqua")}
  })
  
  observeEvent(input$go1,{
    updateTabsetPanel(session, "tabs", selected="result")
    val$current_id=val$df_temp[1,"id"]
    
    })
  observeEvent(input$go2,{
    updateTabsetPanel(session, "tabs", selected="result")
    val$current_id=val$df_temp[2,"id"]
    })
  observeEvent(input$go3,{
    updateTabsetPanel(session, "tabs", selected="result")
    val$current_id=val$df_temp[3,"id"]
  })
  observeEvent(input$go4,{
    updateTabsetPanel(session, "tabs", selected="result")
    val$current_id=val$df_temp[4,"id"]
  })
  observeEvent(input$go5,{
    updateTabsetPanel(session, "tabs", selected="result")
    val$current_id=val$df_temp[5,"id"]
  })
  
  observeEvent(input$backtomain, {
               updateTabsetPanel(session, "tabs", selected="search")})
  
}


