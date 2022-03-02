library(shinyjs)
library(stringr)
library(plotly)
library(shinyWidgets)

NUM_PAGES <- 2

ui_theme <- bslib::bs_theme(version = 4)

df=read.csv("df_data.csv")

genres_list=vector()

for (i in 1:nrow(df)){
  for (item in str_split(df[i,"genres"], "/")[[1]]){
    if( ! item %in% genres_list )  {
      genres_list=c(genres_list, item)
      
    }
  }
}



ui <- fluidPage(
  tags$head(tags$style( "
.navbar-default {
  background-color: inherit;
  border: none;
}
")),
  setBackgroundColor(
    color = c("#EBEED7", "#C8E4E5"),
    gradient = "linear",
    direction = c("bottom","left")
  ),
  navlistPanel(
    id = "tabset",
    "Anime Titles-Overall",
    tabPanel("Highest Rated/Most Voted Titles",
    fluidPage(
    column(2,wellPanel(
    numericInput("year", label="Select Year", value=2000, min=1979, max=2021),  
    selectInput("select", label="Select Type", choices=c("TV", "movie")),
    sliderInput("n", "Top N", min=1, max=10, value=5)
    )),
    
    column(5, 
           fluidRow( plotlyOutput("plot")),
           
           fluidRow( plotlyOutput("plot0.5"))
           
           ),
    
    column(5, plotOutput("wordplot"), align="center")
    )  

   
      
 ),   
 tabPanel("General Information",
          fluidPage(
            column(2, wellPanel(
              numericInput("year_start", label="Select Starting Year", value=1996, min=1979, max=2021),
              numericInput("year_end", label="Select Ending Year", value="", min=1979, max=2021),
              selectInput(
                "genre", "Select a genre", sort(genres_list))
            )),  
            column(8,
                   fluidRow(column(6, plotlyOutput("plot2"), style="padding:15px;"),column(6, plotlyOutput("plot3"),style="padding:15px;")),
                   fluidRow(column(6, plotlyOutput("plot4")),column(6, plotlyOutput("plot5")))
            )  
            
            
            
          )          
 ),
     
    "Anime Titles-Individual",
    tabPanel("Search the Anime Database", HTML("<b>Search Anime Titles</b>"),
    fluidPage(
    tabsetPanel(id="tabs",
    tabPanel(title="Search", value="search",
             
    fluidRow(column(8, HTML("<b>Instructions</b>"),style='padding-top:10px;')),   
    fluidRow(column(8, "(1) Please type the name of the anime title you would like to search in the text box below and click 'Search'.")),  
    fluidRow(column(8, "(2) The Top 5 results will be returned. Please select the one you are 
                    interested to see by clicking the button 'Click for Result'. ")), 
    fluidRow(column(8, "(3) The Result page will display information specific to your selection. You can return to the search
                    page to click on a different title to see its result.")),
    fluidRow(column(8, "(4) You can click 'Clear' to erase the search results at any time.")), 
    fluidRow(column(3, textInput("textin", ""))),  
    fluidRow(column(1, actionButton("go", "Search"), align = "left", style='height:5vh'),
             column(1, actionButton("clear", "Clear"), align = "left", style='height:5vh')),
    
    fluidRow(
      column(2, HTML("<b>Name</b>"), style='height:3vh', align = "left"),
      column(1, HTML("<b>Type</b>"), style='height:3vh'),
      column(2, HTML("<b>Vintage</b>"), style='height:3vh'),
      column(2, HTML("<b>Genres</b>"), style='height:3vh'),
      column(1, HTML("<b>Episode</b>"), style='height:3vh')
      ),
    fluidRow(useShinyjs(),
     
      column(2, textOutput("var2"), style="padding:20px;", align = "left"),
      column(1, textOutput("var3"), style="padding:20px;", align = "left"),
      column(2, textOutput("var4"), style="padding:20px;", align = "left"),
      column(2, textOutput("var5"), style="padding:20px;", align = "left"),
      column(1, textOutput("var6"), style="padding:20px;", align = "left"),
      column(1, hidden(actionButton("go1", "Click for Result")), style="padding:12.5px;", align = "left"),
    ),
    fluidRow(
      
      column(2, textOutput("var8"), style="padding:20px;", align = "left"),
      column(1, textOutput("var9"), style="padding:20px;", align = "left"),
      column(2, textOutput("var10"), style="padding:20px;", align = "left"),
      column(2, textOutput("var11"), style="padding:20px;", align = "left"),
      column(1, textOutput("var12"), style="padding:20px;", align = "left"),
      column(1, hidden(actionButton("go2", "Click for Result")), style="padding:12.5px;", align = "left"),
    ),
    
    fluidRow(
      
      column(2, textOutput("var13"), style="padding:20px;", align = "left"),
      column(1, textOutput("var14"), style="padding:20px;", align = "left"),
      column(2, textOutput("var15"), style="padding:20px;", align = "left"),
      column(2, textOutput("var16"), style="padding:20px;", align = "left"),
      column(1, textOutput("var17"), style="padding:20px;", align = "left"),
      column(1, hidden(actionButton("go3", "Click for Result")), style="padding:12.5px;", align = "left"),
    ),
    fluidRow(
      
      column(2, textOutput("var18"), style="padding:20px;", align = "left"),
      column(1, textOutput("var19"), style="padding:20px;", align = "left"),
      column(2, textOutput("var20"), style="padding:20px;", align = "left"),
      column(2, textOutput("var21"), style="padding:20px;", align = "left"),
      column(1, textOutput("var22"), style="padding:20px;", align = "left"),
      column(1, hidden(actionButton("go4", "Click for Result")), style="padding:12.5px;", align = "left"),
    ),
    fluidRow(
      
      column(2, textOutput("var23"), style="padding:20px;", align = "left"),
      column(1, textOutput("var24"), style="padding:20px;", align = "left"),
      column(2, textOutput("var25"), style="padding:20px;", align = "left"),
      column(2, textOutput("var26"), style="padding:20px;", align = "left"),
      column(1, textOutput("var27"), style="padding:20px;", align = "left"),
      column(1, hidden(actionButton("go5", "Click for Result")), style="padding:12.5px;", align = "left"),
    )
    ),
    
    tabPanel(
      title = "Result",
      value= "result",
      br(),
      uiOutput("summarybox")
    )
  
             ))), #end of panel 2
widths = c(2, 10)
  )
)
