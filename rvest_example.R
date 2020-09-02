# Whenever you see libraries listed at the top of code, you should always make sure that you have them installed. To install a library--or a 'package' as they are often called--use the install.packages() function in R.
library(rvest)
library(tidyverse)

# This is the primary URL from which you will extract other URLs containing content of interest
main.url <- read_html("https://greensboro.com/news/local_news/")

# Using the selector gadget, identify the URLs of interest on the page, and then copy the xpath for pasting into th html_nodes function. By piping the output into html_attr() using "href," we collect just the URLs from the links identified using the selector gadget.
scrape.list <- html_nodes(main.url, xpath='//*[contains(concat( " ", @class, " " ), concat( " ", "tnt-asset-type-article", " " )) and contains(concat( " ", @class, " " ), concat( " ", "image-left", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "tnt-asset-link", " " ))]') %>%
  # Another variation without the pipe: scrape.list <- html_attr(scrape.list, "href")
  # By using the %>% we avoid the needless copy/paste to modify the variable containing our data
  html_attr("href")

# A simple for loop using paste0() combines the data scraped from the link href URLs with the missing 'https:greensboro.com' to create a complete URL for scraping
for (i in seq_along(scrape.list)) {
  scrape.list[i] <- paste0('https://greensboro.com', scrape.list[i])
}

# Creates an empty vector that will be filled data by the 'for loop' below
page.text <- vector()
page.date <- vector()

# The for loop visits each URL in scrape.list and then collects the text content from each page, creating a new list
for (i in seq_along(scrape.list)) {
  new.url <- read_html(scrape.list[i])

  #Collects text content from pages
  text.add <- html_nodes(new.url, xpath='//*[(@id = "asset-content")]//p') %>%
    html_text()

  #Collapses all the separate <p> text content into one string of text
  text.add <- paste(text.add, collapse=" ")

  #Collects the date from pages
  date.add <- html_nodes(new.url, "time") %>%
    html_attr("datetime")

  #Removes the extra date to make finished list the same length as other lists in loop
  date.add <- date.add[-c(2)]

  page.text <- c(page.text, text.add)
  page.date <- c(page.date, date.add)
}

# Using tibble, the list of URLs is combined with the text scraped from each URL to create a dataframe for our combined dataset
scrape.data <- tibble('url'=scrape.list, 'date'=page.date, 'text'=page.text)

# Save dataframe as a CSV file
write.csv(scrape.data, 'gboro_news.csv')
