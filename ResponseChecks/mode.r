library(dplyr)
library(tidyr)
library(lubridate)
library(forcats)
library(ggplot2)
library(readxl)
library(stringr)
library(scales)
library(purrr)
library(rlang)

ds_responses <- readxl::read_excel(
  "../../Data/TrackingForm_Client.xlsx"
  #"./Data/DataAggregation1/TrackingForm_Client.xlsx"
) %>%
  select(
    CustomerID = 'CustomerID',
    Responded = 'Completion disposition (1.1)',
    CompletionDate = `Date of completion`,
    Condition,
    Mode = 'Mode of completion (Mail, web, phone)',
    Notes
  ) %>%
  mutate(
    Subsampled = TRUE,
    Responded = !is.na(Responded), # Only TRUE if actually responded
    CompletionDate = as.Date(as.numeric(CompletionDate), origin = "1899-12-30"),
    Mode = case_when(
      str_detect(tolower(Mode), "^mail") ~ "Mail",
      str_detect(tolower(Mode), "^postcard") ~ "Mail",
      str_detect(tolower(Mode), "^text") ~ "Text",
      str_detect(tolower(Mode), "^email") ~ "Email",
      str_detect(tolower(Mode), "^web") ~ "Web",
      .default = NA
    ),
    Undeliverable_Email1 = str_detect(Notes, "Undeliverable via: Email 1"),
    Undeliverable_Email2 = str_detect(Notes, "Undeliverable via: Email 2"),
    Undeliverable_Text1 = str_detect(Notes, "Undeliverable via: Text 1"),
    Undeliverable_Text2 = str_detect(Notes, "Undeliverable via: Text 2"),
    Undeliverable_MailLetter1 = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Letter 1\\)"
    ),
    Undeliverable_MailLetter2 = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Letter 2\\)"
    ),
    Undeliverable_MailPostcard = str_detect(
      Notes,
      "Undeliverable via: Mail \\(Postcard\\)"
    ),
    across(starts_with("Undeliverable_"), \(x) replace_na(x, FALSE))
  )

library(gt)

gt(
  ds_responses %>%
    filter(!is.na(Mode)) %>%
    group_by(Mode) %>%
    summarise(
      Total = n(),
      Responded = sum(Responded),
      ResponseRate = Responded / Total
    ) %>%
    ungroup() %>%
    mutate(a = sum(Responded)) %>%
    mutate(ResponsePerc = round(Responded / a * 100, 1))
)

library(tidyverse)
library(lubridate)

tasks <- tribble(
  ~section          , ~task                  , ~date        ,
  "Mail"            , "Initial Packet Sent"  , "2025-11-12" ,
  "Mail"            , "Final Packet Sent"    , "2025-12-08" ,
  "Postcard"        , "Postcard Reminder"    , "2025-11-19" ,
  "Email"           , "Initial Email Invite" , "2025-11-20" ,
  "Email"           , "Final Email Reminder" , "2025-12-10" ,
  "Text Schedule 1" , "Initial"              , "2025-11-12" ,
  "Text Schedule 1" , "Reminder"             , "2025-11-20" ,
  "Text Schedule 2" , "Initial"              , "2025-11-20" ,
  "Text Schedule 2" , "Reminder"             , "2025-12-11"
) |>
  mutate(
    date = ymd(date),
    section = factor(section, levels = rev(unique(section)))
  )

ggplot(tasks, aes(x = date, y = section)) +
  # geom_segment(
  #   data = tasks |>
  #     group_by(section) |>
  #     summarise(start = min(tasks$date), end = max(tasks$date)),
  #   aes(x = start, xend = end, y = section, yend = section),
  #   linewidth = 8,
  #   alpha = 0.18
  # ) +
  geom_point(size = 7, shape = 18) +
  geom_text(
    aes(label = task),
    hjust = -0.1,
    size = 7
  ) +
  scale_x_date(
    breaks = seq(
      ymd("2025-11-02"),
      ymd("2025-12-31"),
      by = "7 days"
    ),
    date_labels = "%b %d",
    limits = c(
      ymd("2025-11-02"),
      ymd("2025-12-31")
    )
  ) +
  labs(
    x = NULL,
    y = NULL,
    title = ""
  ) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 22),
    axis.text.x = element_text(size = 22, angle = 45, hjust = 1),
    plot.title = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )
ggsave(
  "./response_timeline.png",
  width = 12,
  height = 6
)


tmp <- ds_responses %>%
  filter(!is.na(CompletionDate)) %>%
  #filter(CompletionDate <= ymd("2025-11-19")) %>%
  filter(Condition == 1) %>%
  group_by(Mode) %>%
  summarize(all = n())

ds_responses %>% filter(Condition == 1)

ds_responses %>%
  filter(Condition == 1) %>%
  group_by(Mode) %>%
  summarize(all = n())

ds_responses %>%
  filter(Mode == 1) %>%
  group_by(Condition, Mode) %>%
  summarize(all = n())

#ds_responses <-
readxl::read_excel(
  "../../Data/TrackingForm_Client.xlsx"
  #"./Data/DataAggregation1/TrackingForm_Client.xlsx"
) %>%
  mutate(Mode = `Mode of completion (Mail, web, phone)`) %>%
  filter(
    Mode %in%
      c(
        "Mail",
        "Web Letter 2",
        "Web Letter 1",
        "Mail (Letter 2)",
        "Mail (Letter 1)",
        "mail",
        "Web letter 1",
        NA
      )
  ) %>% #", NA)) %>% #, "Email 1", "Email 2", NA)) %>%
  mutate(
    Sent_Mail = 1,
    CompletionDate = as.Date(
      as.numeric(`Date of completion`),
      origin = "1899-12-30"
    ),
    Flight = NA,
    Flight = ifelse(CompletionDate <= as.Date("2025-12-10"), 1, Flight),
    Flight = ifelse(CompletionDate > as.Date("2025-12-10"), 2, Flight),
    #(!is.na(`Date Mail 1 Sent`) | !is.na(`Date Mail 2 Sent`)),
    #Sent_Text = (!is.na(`Date Text 1 Sent`) | !is.na(`Date Text 2 Sent`))
  ) %>%
  group_by(Mode, Sent_Mail, Flight) %>%
  summarize(all = n())


#ds_responses <-
readxl::read_excel(
  "../../Data/TrackingForm_Client.xlsx"
  #"./Data/DataAggregation1/TrackingForm_Client.xlsx"
) %>%
  mutate(Mode = `Mode of completion (Mail, web, phone)`) %>%
  filter(
    Mode %in%
      c(
        "Text 1",
        "Text 2",
        NA
      )
  ) %>%
  mutate(
    Sent_Text = (!is.na(`Date Text 1 Sent`) | !is.na(`Date Text 2 Sent`))
  ) %>%
  group_by(Mode, Sent_MailText, Condition) %>%
  summarize(all = n())
