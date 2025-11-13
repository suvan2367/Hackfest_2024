🧩 Novo Nordisk Protocol Extractor
📘 Overview

The Novo Nordisk Protocol Extractor is an interactive R Shiny application that automates the extraction and management of Inclusion and Exclusion Criteria, as well as Objectives and Endpoints, from clinical trial protocol documents (PDF or DOCX format). It is designed to support protocol version tracking, data consistency, and structured dataset generation for clinical data analysis and reporting.

⚙️ Features

📂 Upload Protocol Files: Supports both .pdf and .docx files.

🧠 Automatic Text Extraction: Extracts inclusion/exclusion sections or objectives/endpoints from protocols.

🧹 Data Cleaning: Cleans non-ASCII and special characters for consistency.

🔁 Version Control: Detects and compares multiple protocol versions, highlighting text changes.

📊 Structured Output: Generates a CSV file (combined_data.csv) in CDISC-like format.

🧾 Python Integration: Runs an external Python script (final.py) for table extraction (objectives/endpoints).

💬 Interactive UI: Built with shiny, shinyjs, and shinythemes for a responsive and branded interface.

🧼 Session Management: Clear or reset data without restarting the app.

🧰 Technology Stack

Frontend/UI: R Shiny, ShinyJS, Shinythemes

Backend (Extraction): R (stringr, tidyverse, pdftools, docxtractr)

Auxiliary Processing: Python (final.py for table extraction)

Output Format: CSV (structured inclusion/exclusion dataset)

🧠 Example Use Case

Upload a protocol PDF (Version 1) and extract inclusion/exclusion criteria.

Upload Version 2 of the protocol — the app automatically compares versions and appends differences.

Export the combined dataset for downstream data management or CDISC mapping.
