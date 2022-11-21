library(shiny)
library(shinydashboard)
library(leaflet)
library(tidyverse)

ui <- dashboardPage( 
 skin = "green",
 dashboardHeader(title = "Arrow of God"),
 ## Sidebar content
 dashboardSidebar(
  sidebarSearchForm(textId = "searchText", buttonId = "searchButton",label = "Search..."),
   sidebarMenu(
    
    #menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Charts", tabName = "charts", icon = icon("signal")),
    menuItem("Map",tabName = "ke_map", icon = icon("globe"))#,
    #menuItem("Widgets", tabName = "widgets", icon = icon("th")),
    #menuItem("Settings", tabName = "settings", icon = icon("cog"))
   )
 ),
 dashboardBody(
 tabItems(
  # First tab content
  #tabItem(tabName = "dashboard",fluidRow(
   #box(title = "Crime Rates"),
   #box(title = "Profits"),
   #box(title = "Losses"),
   #box(title = "Change"),
   #box(),
   #box(solidHeader = TRUE, collapsible = TRUE, plotOutput("plot1", height = 250), status = "primary", footer = "@tgtarus"),
   #box(title = "Controls", sliderInput("slider", "Number of observations:", 1, 100, 50), 
   #    solidHeader = TRUE, collapsible = TRUE, status = "warning"))),
  # Second tab content
  tabItem(tabName = "charts",h2("Charts"),
          box("Type of Platform", plotOutput("platform")),
          box("Type of Transaction", plotOutput("trans"))
          ),
  
  # Third tab content
  tabItem(tabName = "ke_map",leafletOutput("keMap", width = "1920px", height = "940px"))#,
  
  # Fourth tab content
  #tabItem(tabName = "widgets",h2("Widgets tab content")),
  
  # Fifth tab content
  #tabItem("settings", h2("Find Settings"))
 )
)
)

server <- function(input, output) {
 my_map <- df_train %>% leaflet() %>% addTiles() %>% 
  addCircleMarkers(map, lat = train$pickup_lat, lng = train$pickup_long, weight = 1, radius = 1.5)
 output$keMap <- renderLeaflet({my_map})
 
 #Histogram
 histdata <- rnorm(500)
 output$plot1 <- renderPlot({
  data <- histdata[seq_len(input$slider)]
  hist(data) })
 output$platform <- renderPlot({
  ggplot(train, aes(x = as_factor(platform_type), fill = as_factor(platform_type)))+
   geom_bar()+
   labs(x = "Type of Platform", fill = "Type of Platform")
 })
 output$trans <- renderPlot({
  ggplot(train,aes(x = personal_or_business, fill = personal_or_business))+
   geom_bar()+
   labs(x = "Order Type", fill = "Type of Order")
 })
}

shinyApp(ui, server)