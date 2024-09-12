library(shiny)
library(shinyjs)
library(shinythemes)
library(dplyr)
#Master function named convert

convert <- function(filename, version,block,study_id) {
library(stringr)
library(tidyverse)
library(pdftools)
library(docxtractr)
check <<- 0
cleanup_text <- function(text){

  #replacement of non-ascii characters using gsub() function 
  text <- gsub("\\s+", " ", text)
  text <- gsub("×", "x", text)
  text <- gsub("≠", "not equal to", text)
  text <- gsub("≥",">=",text)
  text <- gsub("≤","<=",text)
  text <- gsub("&","and",text)
  text <- gsub("]","",text)
  text  <- gsub("<Insert text>", "", text)
  text <- gsub("[^\x01-\x7F]", "_", text)  #replaces any other non-ascii character with "_"
  text <- gsub("[\\*\\#\\$\\%\\^\\+\\-\\~\\]","",text)  #removes the special characters included within square brackets (can be added manually)

  # Removing special characters using function of stringr library
  text <- str_remove_all(text, "[^[:alnum:][[:space:]][:punct:]<>=]")
  return(text)
}

#subfunction to process and create a dataframe

process_text <- function(text, version) {
text <- paste(text,collapse = "\n")
  blockn = block+0.1
      head <- paste0(blockn," INCLUSION CRITERIA")
     index <- str_locate(text, head)[1, 1]
     length <- nchar(text)
  result <- str_sub(text,index,length)
     tail <- paste0(blockn+0.2," ")
     index <- str_locate(result,tail)[1, 1]
     result_new <- substr(result, 1, index-1)
    text <- result_new
      spltxt <- paste0(blockn+0.1," EXCLUSION CRITERIA")
  
  
  text <- cleanup_text(text)
  
  # Split the input text into inclusion and exclusion parts
  parts <- str_split(text, spltxt)[[1]]
  parts[1] <- cleanup_text(parts[1])

  index <- str_locate(parts[1],": 1.")[1, 1]
  length <- nchar(parts[1])
     inc <- str_sub(parts[1],index,length)
  inclusion <- str_split(inc, "\\d\\.\\s")[[1]]
  # Process inclusion criteria
  inclusion <- inclusion[-1]
  #creating a sequence for inclusion id
  IETESTCD <- paste0("I", seq_along(inclusion))
  #creating inclusion dataframe
  inclusion_df <- data.frame(STUDYID=study_id,
    Domain = "TI",
    IETESTCD = IETESTCD,
    IETEST = str_replace_all(inclusion, "\\n|/", " "),
    IECAT = "Inclusion",
    IESCAT="",
    TIRL="",
    TIVERS = version)


   parts[2] <- cleanup_text(parts[2])
  # Process exclusion criteria
   index <- str_locate(parts[2],": 1.")[1, 1]
  length <- nchar(parts[2])
     exc <- str_sub(parts[2],index,length)
 
  exclusion <- str_split(exc, "\\d\\.\\s")[[1]]
  exclusion[1] <- str_replace(exclusion[1], "^1\\.", "") #replacing unwanted first element
  exclusion <- exclusion[-1]
  #creating a sequence for ecxlusion id
  IETESTCD <- paste0("E", seq_along(exclusion))
  #creating exclusion dataframe
  exclusion_df <- data.frame(STUDYID=study_id,
    Domain = "TI",
    IETESTCD = IETESTCD,
    IETEST = str_replace_all(exclusion, "\\n|/", " "),
    IECAT = "Exclusion",
    IESCAT="",
    TIRL="",
    TIVERS = version)

  # Combining inclusion and exclusion dataframes
  bind_rows(inclusion_df, exclusion_df)
}

# subfunction to combine old version dataframe and new version dataframe
combine_dataframes <- function(df_old, new_text, version) {
  # Processing new text to create a dataframe
  new_data <- process_text(new_text, version)

  # Combining old and new dataframes
  bind_rows(df_old, new_data)
}

compare_data <- function(merged_df) {

   # Assuming TIVERS is the column indicating the version
  merged_df <- merged_df %>%
  arrange(IETESTCD, TIVERS) %>%  # Ensure correct order for lag function
  group_by(IETESTCD) %>%
  mutate(
  row_id = row_number(),
  IETEST_prev = lag(IETEST),
  change = ifelse(is.na(IETEST_prev), FALSE, IETEST != IETEST_prev),
  change_group = cumsum(change)
  ) %>%
  group_by(IETESTCD, change_group) %>%
  mutate(
  new_suffix = ifelse(change_group > 0, LETTERS[row_number()], "")
  ) %>%
  ungroup() %>%
  group_by(IETESTCD, change_group) %>%
  mutate(
  new_suffix = ifelse(change_group > 0, LETTERS[change_group], "")
  ) %>%
  ungroup() %>%

  return(merged_df)

  return(merged_df)
}

filter_dataframe <- function(df) {
  df %>%
    arrange(TIVERS, IETESTCD) %>%
    group_by(IETESTCD) %>%
    mutate(
      prev_version = lag(TIVERS),
      prev_ietestcd = lag(IETESTCD),
      is_last_version = TIVERS == max(TIVERS)
    ) %>%
    ungroup() %>%
    filter(
      grepl("[A-Z]$", IETESTCD) |
      TIVERS == 1 |
      is.na(prev_version) |
      (prev_version != TIVERS) |
      !IETESTCD %in% df$IETESTCD[df$TIVERS == prev_version & df$IETESTCD != prev_ietestcd & df$is_last_version]
    ) %>%
    select(-prev_version, -prev_ietestcd, -is_last_version)
}

cleanup_df <- function(combined_df){

combined_df <- combined_df %>%
  mutate(IETESTCD = ifelse(new_suffix != "", paste0(IETESTCD, new_suffix), IETESTCD))
  combined_df <- combined_df[, -c(9:13)]
  combined_df <- combined_df %>%
  arrange(TIVERS, desc(IECAT == "Inclusion"))
  
combined_df <- filter_dataframe(combined_df)
  return(combined_df) 
}


#checking version number to see if need to combine older version dataframe and calling functions appropriately
if (exists("combined_df")) {
   
  if (version %in% combined_df$TIVERS) {
    show_prompt("This version already exist")
	check <- 1}
  else if (!(version-1) %in% combined_df$TIVERS) {
    show_prompt("Previous version missing")
	 check <- 1}
  else{
    file_extension <- tools::file_ext(filename)
    if(file_extension == "pdf"){
      new_text_data <- pdf_text(filename)
    }
    else if(file_extension == "docx"){
      new_text_data <- read_docx(filename)
    }
    combined_df <<- combine_dataframes(combined_df, new_text_data, version)
    combined_df <- compare_data(combined_df)
    combined_df <- cleanup_df(combined_df)
    check <- 0
  }

}
else if (version == 1 ) {
  file_extension <- tools::file_ext(filename)
  if(file_extension == "pdf"){
  text_data_v1 <- pdf_text(filename)
  }
  else if(file_extension == "docx"){
  python_script <- "import sys; from docx2pdf import convert; convert(sys.argv[1], sys.argv[2])"
  system(paste("py -c", shQuote(python_script), shQuote(filename), shQuote("output.pdf")))
  text_data_v1 <- pdf_text("output.pdf")
  }
  combined_df <<- process_text(text_data_v1, version)
}


if (exists("combined_df")) {
if (check==0){
   
combined_df <- combined_df %>%
  mutate(IETEST = ifelse(IETEST != "", paste0(IETESTCD, ": ", IETEST), IETEST))
# Exporting to CSV format file named combined_data.csv
write.csv(combined_df, "combined_data.csv", row.names = FALSE)
show_prompt("Conversion Done !")
}
}
}

table_extract <- function(filename, block){

  curr_dir <- getwd()
curr_dir <- gsub("/", "\\\\", curr_dir)
     python_script <- paste0(curr_dir,"\\final.py")
  system(paste("py", "final.py", filename, block))
  file = "converted_tab.csv"
  if(file.exists(file)){
    show_prompt("Done!")

 } else{
    show_prompt("File not converted!")
}

}


main <- function(choice,file,ver,block,study_id) {


    if (choice == 1) {
     convert(file,ver,block,study_id)
    } 
    else if (choice == 3) {
      rm(combined_df, envir = globalenv())
      if(block!=11)
      show_prompt("Data cleared...\n")
    } 
    else if (choice == 4) {
      if (exists("combined_df")) {
      rm(combined_df, envir = globalenv())}
    
    }
    else if (choice == 2) {
 
      table_extract(file,block)}
}

show_prompt <- function(message) {
  showModal(modalDialog(
    title = "Message",
    message,
    easyClose = TRUE,
    footer = tagList(
      modalButton("Close")
    )
  ))
}

ui <- fluidPage(
     theme = shinytheme("cosmo"),
    tags$head(
    tags$style(HTML("
      body {
        background-color:  #003366;  /* ink blue background color */
      }
    "))
  ),
  useShinyjs(),  # Initialize shinyjs
 # Heading with Image
  fluidRow(
    column(12,
      tags$div(
        style = "text-align: left; margin: 20px 0;padding:10px;",
        tags$img(src = "https://www.designyourway.net/blog/wp-content/uploads/2024/04/novo-nordisk-logo.jpg", class = "header-img", class="header-img", alt = "App Logo", width = "150")  # Adjust `width` as needed
      )
    )
  ),

 
fluidRow(
    column(12,
 tags$div(
     
      tags$div(
             style = "text-align: center; margin-bottom: 10px;",  # Adjust the margin as needed
             tags$h1("Novo Nordisk", style = "color: #FFFFFF;font-weight: bold;font-family: 'Times New Roman', sans-serif; font-size: 50px; margin-bottom: 30px;"),  # Adjust text color as needed
   
 # Subtitle
             tags$h3( "Protocol Extractor", style = "color: #FFFFFF; font-family: 'Roboto', sans-serif; font-size: 30px; margin-top: 0; margin-bottom: 20px;" )
           ),
           ),
           # Horizontal line above the options
           tags$hr(style = "border: 1px solid #FFFFFF; margin:60px 0 0 0;"),
    )
  ),
  fluidRow(
    column(3,
           actionButton("extract_inclusion_exclusion", "Extract Inclusion/Exclusion Data",style = "margin-top: 40px; margin-bottom: 20px; margin-left:80px"),
  div(),
           actionButton("extract_objectives_endpoints", "Extract Objectives and Endpoints",style = "margin-bottom: 20px;margin-left:80px"),
  div(),
           actionButton("clear_data", "Clear Data",style = "margin-bottom: 20px;margin-left:150px"),
  div(),
           actionButton("exit", "Exit",style = "margin-bottom: 20px;margin-left:170px")
    ),
 column(1,
           # Vertical line with inline CSS
          tags$div(style = "border-left: 2px solid #FFFFFF; height: 70vh; min-height: 300px; margin-left: 15px;")  # Changed height properties for visibility
    ),
    column(8,
tags$div(style = "position: relative; width: 100%;"),
           hidden(
             div(id = "inclusion_exclusion_panel",
 style = "position: absolute; left: 300px;",
div(style="margin-top: 20px;",
                 fileInput("file_input", label = tags$span(style = "color: #FFFFFF;","Select File")),
                 numericInput("version_input", label = tags$span(style = "color: #FFFFFF;", "Version Number"), value = 1, min = 1),
                 numericInput("block_input",  label = tags$span(style = "color: #FFFFFF;",  "Section Number"), value = 1, min = 1),
  textInput("study_id", label = tags$span(style = "color: #FFFFFF;",  "Study ID"), value = "A1"),
                 actionButton("submit_inclusion_exclusion", "Submit")
             )
     )
           ),
           hidden(
             div(id = "objectives_endpoints_panel",
 style = "position: absolute; left: 300px;",
div(style="margin-top: 20px;",
              fileInput("file_input2", label = tags$span(style = "color: #FFFFFF;","Select File")),
     numericInput("block_input2",  label = tags$span(style = "color: #FFFFFF;",  "Section Number"), value = 1, min = 1),
                 actionButton("submit_objectives_endpoints", "Submit")
             )        
 )
)
    )
  )
)


server <- function(input, output, session) {

   observeEvent(session, {
            main(3,"name", 1, 11,"blah")         
  })
   
  observeEvent(input$extract_inclusion_exclusion, {
    hide("objectives_endpoints_panel")
    toggle("inclusion_exclusion_panel")
    
  })
 
  observeEvent(input$extract_objectives_endpoints, {
    hide("inclusion_exclusion_panel")
    toggle("objectives_endpoints_panel")
   
  })
 
  observeEvent(input$clear_data, {
    hide("inclusion_exclusion_panel")
    hide("objectives_endpoints_panel")
    tryCatch({ 
            main(3,"name", 1, 8,"blah")
            shinyjs::enable("study_id")
           },
           error = function(e) {
                                 show_prompt(paste("An error occurred:", e$message))
                                                                          
                           },                        
                                  warning = function(w) {
                                  show_prompt(paste("A warning occurred:", w$message))
                                  }
                           )
                           
  })
 
  observeEvent(input$exit, {
    show_prompt("You can close the Tab now")
    stopApp()
  })
 
  observeEvent(input$submit_inclusion_exclusion, {
    tryCatch({  #if (exists("combined_df")) {
                    
                # }
            main(1, input$file_input$datapath, input$version_input, input$block_input, input$study_id)
            shinyjs::disable("study_id")
           },
           error = function(e) {
                                 show_prompt(paste("An error occurred:", e$message))
                                                                          
                           },                        
                                  warning = function(w) {
                                  show_prompt(paste("A warning occurred:", w$message))
                                  }
                           )  
                            

  })
 
  observeEvent(input$submit_objectives_endpoints, {
    tryCatch({ 
            main(2, input$file_input2$datapath, 1, input$block_input2,"blah")
                    #print(input$file_input2$datapath)
           },
           error = function(e) {
                                 show_prompt(paste("An error occurred:", e$message, input$study_id))
                                                                          
                           },                        
                                  warning = function(w) {
                                  show_prompt(paste("A warning occurred:", w$message))
                                  }
                           )
                           

  })

 }


shinyApp(ui, server)