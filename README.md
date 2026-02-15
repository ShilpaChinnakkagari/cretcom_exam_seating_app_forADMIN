**cretcom_exam_seating_forADMIN **
-------------------------------------------------------
_Problem:_
Exam seating details are usually managed manually by staff, which involves repeatedly updating notice boards and sharing information verbally. This process is time-consuming, error-prone, and difficult to manage when student data or room allocations change frequently.
_
Solution:_
This admin-side Flutter application provides a centralized way for administrators to manage exam seating data using a Google Spreadsheet. The admin can control the Google Sheet link and API key used by the student-facing exam seating app, ensuring real-time and accurate updates.

**What it does:**
---------------------
1.Allows the admin to manage the Google Spreadsheet used for exam seating allocation.
2.Stores and updates the Google Sheets API key securely for data access.
3.Acts as the backend control app for the cretcom_exam_seating_app.
4.Ensures any update made by the admin is instantly reflected for students.
5. Reduces manual effort and avoids confusion during exams.

**Usage Flow**
-----------------------
1.Admin updates student exam seating details in Google Sheets.
2.Admin configures the spreadsheet link and API key using this app.
3.Student app fetches updated data directly from the configured sheet.
4.Students can check their exam room and bench details without crowding notice boards.

From ADMIN side - APP
---------------------
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/f721b0e4-0ad6-401d-acc7-687593fd85d2" />

Google Sheet - that admin manages
---------------------------------
<img width="1172" height="394" alt="Screenshot 2026-02-15 151807" src="https://github.com/user-attachments/assets/dbfea2ce-df6f-4dac-98e0-9cd6f987b868" />

