library(shiny)
# Other useful packages
library(datasets)
library(rpart)
library(party)
library(fpc)

# Define colors
palette(c("#E73032", "#377EB8", "#4DAF4A", "#984EA3",
          "#FF7F00", "#FFDD33", "#A65628", "#F781BF", "#999999"))

# Define server logic 
shinyServer(function(input, output) {
  
  datasetInput <- reactive({
    switch(input$dataset,
           "all iris data" = iris,
           "setosa" = subset(iris, iris$Species == "setosa"),
           "versicolor" = subset(iris, iris$Species == "versicolor"),
           "virginica" = subset(iris, iris$Species == "virginica"))
  })
  
  colX <- reactive({
    switch(input$Xvar,
           "Sepal.Length" = iris$Sepal.Length,
           "Sepal.Width" = iris$Sepal.Width,
           "Petal.Length" = iris$Petal.Length,
           "Petal.Width" = iris$Petal.Width)
  })
  
  colY <- reactive({
    switch(input$Yvar,
           "Sepal.Length" = iris$Sepal.Length,
           "Sepal.Width" = iris$Sepal.Width,
           "Petal.Length" = iris$Petal.Length,
           "Petal.Width" = iris$Petal.Width)
  })
  
  clusters <- reactive({
    kmeans(iris[,1:4], input$clusters)
  })
  
  myColors <- reactive({
    switch(input$dataset,
           "all iris data" = c(palette()[1],palette()[2],palette()[3]),
           "setosa" = palette()[1],
           "versicolor" = palette()[2],
           "virginica" = palette()[3])
  })
  
  # Generate a summary of the dataset (or subset by Iris.Species)
  output$summary <- renderPrint({
    dataset <- datasetInput()
    summary(dataset)
  })
  
  # Show the first n observations
  output$view <- renderTable({
    head(datasetInput(), n = input$obs)
  })
  output$NbRows <- renderText({ 
    paste("You have selected to show ", input$obs," lines.")
  })
  
  
  # Show a simple x,y plot
  output$simplePlot <- renderPlot({
    
    df_iris <- datasetInput()
    plot(df_iris[,c(input$Xvar,input$Yvar)], xlab = input$Xvar, ylab = input$Yvar,
         main=toupper(ifelse(input$dataset == "all iris data", "iris", input$dataset)), pch=16, cex = 2,
         col = ifelse(df_iris$Species == "setosa", palette()[1], 
                      ifelse(df_iris$Species == "versicolor", palette()[2], palette()[3])) )
    
    legend("bottomright", legend = unique(df_iris[,5]), 
           col = myColors(), title = expression(bold("Iris.Species")),
           pch = 16, bty = "n", pt.cex = 2, 
           cex = 0.8, text.col = "black", horiz = FALSE, inset = c(0.05, 0.05))
  })
  
  # Show boxplot
  output$boxPlot <- renderPlot({
    df_iris <- datasetInput()
    
    if (input$dataset == "all iris data") {
      boxplot(df_iris[,c(input$Yvar)] ~ df_iris[,5], xlab = "Species", ylab = input$Yvar, main = "IRIS", 
              border = "black", col = myColors())
    }
    else {
      boxplot(df_iris[,c(input$Yvar)], xlab = "Species", ylab = input$Yvar, main = toupper(input$dataset),
              border = "black", col = myColors())
    }
  })
  
  # K-Means Plot
  output$NbClust <- renderText({ 
    paste("K-means clustering performed with ", input$clusters," clusters.")
  })
  output$kmeansPlot <- renderPlot({
    plot(iris[,c(input$Xvar,input$Yvar)],
         col = clusters()$cluster,
         pch = 20, cex = 2)
    points(clusters()$centers, pch = 4, cex = 4, lwd = 4)
  })
  
  # Density-based cluster
  output$dbscan_Param <- renderText({ 
    paste("DBSCAN clustering performed with eps = ", input$eps," and minPts = ", input$minPoints,".")
  })
  output$dbscanPlot <- renderPlot({
    cluster <- dbscan(iris[,-5], eps = input$eps, MinPts = input$minPoints)
    plot(cluster, iris[,c(input$Xvar, input$Yvar)])
  })
  
  # Decision Tree
  output$treePlot <- renderPlot({
    ctree <- ctree(Species ~ ., data = iris)
    plot(ctree, type="simple")
  })
  
  # Create a .csv file with dataframe inside
  output$downloadData <- downloadHandler(
    filename = function() {
      paste('data-Iris-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      write.csv(iris, con)
    }
  )
  
})