-- ================================================================
-- ITI EXAMINATION SYSTEM - CRUD PROCEDURES USAGE GUIDE
-- ================================================================
-- Quick Reference Guide for all 72 CRUD Stored Procedures
-- ================================================================

/*
========================================
TABLE OF CONTENTS
========================================
1. INSTRUCTOR          (Procedures 1-4)
2. INTAKE              (Procedures 5-8)
3. DEPARTMENT          (Procedures 9-12)
4. TRACK               (Procedures 13-16)
5. TRACK_INTAKE        (Procedures 17-20)
6. INSTRUCTOR_TRACK    (Procedures 21-24)
7. STUDENT             (Procedures 25-28)
8. STUDENT_INFO        (Procedures 29-32)
9. COURSE              (Procedures 33-36)
10. STUDENT_COURSE     (Procedures 37-40)
11. INSTRUCTOR_COURSE  (Procedures 41-44)
12. TOPIC              (Procedures 45-48)
13. QUESTION           (Procedures 49-52)
14. CHOICES            (Procedures 53-56)
15. EXAM               (Procedures 57-60)
16. EXAM_QUES          (Procedures 61-64)
17. EXAM_SUBMIT        (Procedures 65-68)
18. STUDENT_ANSWER     (Procedures 69-72)

========================================
USAGE EXAMPLES
========================================
*/

-- ================================================================
-- 1. INSTRUCTOR PROCEDURES
-- ================================================================
use ITI_EXAMINATION
-- INSERT a new instructor
EXEC sp_InsertInstructor 
    @instructor_id = 'INST016',
    @instructor_name = 'Sara Ahmed Ali',
    @date_of_birth = '1990-05-15',
    @salary = 11000.00,
    @gender = 'F',
    @hire_date = '2024-01-15';

-- SELECT all instructors
EXEC sp_SelectInstructor;

-- SELECT specific instructor
EXEC sp_SelectInstructor @instructor_id = 'INST001';

-- UPDATE instructor
EXEC sp_UpdateInstructor 
    @instructor_id = 'INST016',
    @salary = 11500.00;

-- DELETE instructor
EXEC sp_DeleteInstructor @instructor_id = 'INST016';

-- ================================================================
-- 2. INTAKE PROCEDURES
-- ================================================================

-- INSERT new intake
EXEC sp_InsertIntake 
    @intake_number = 'INT2026-01',
    @start_date = '2026-01-15',
    @end_date = '2026-06-30';

-- SELECT all intakes
EXEC sp_SelectIntake;

-- SELECT specific intake
EXEC sp_SelectIntake @intake_number = 'INT2025-01';

-- UPDATE intake
EXEC sp_UpdateIntake 
    @intake_number = 'INT2026-01',
    @end_date = '2026-07-15';

-- DELETE intake
EXEC sp_DeleteIntake @intake_number = 'INT2026-01';

-- ================================================================
-- 3. DEPARTMENT PROCEDURES
-- ================================================================

-- INSERT department
EXEC sp_InsertDepartment 
    @dept_id = 'DEPT004',
    @dept_name = 'Business Intelligence',
    @description = 'BI and Analytics',
    @dept_manager_id = 'INST005';

-- SELECT all departments (with manager names)
EXEC sp_SelectDepartment;

-- SELECT specific department
EXEC sp_SelectDepartment @dept_id = 'DEPT001';

-- UPDATE department
EXEC sp_UpdateDepartment 
    @dept_id = 'DEPT004',
    @dept_manager_id = 'INST007';

-- DELETE department
EXEC sp_DeleteDepartment @dept_id = 'DEPT004';

-- ================================================================
-- 4. TRACK PROCEDURES
-- ================================================================

-- INSERT track
EXEC sp_InsertTrack 
    @track_id = 'TRK007',
    @track_name = 'Cybersecurity',
    @track_manager_id = 'INST011',
    @dept_id = 'DEPT003';

-- SELECT all tracks (with manager and department names)
EXEC sp_SelectTrack;

-- SELECT specific track
EXEC sp_SelectTrack @track_id = 'TRK001';

-- UPDATE track
EXEC sp_UpdateTrack 
    @track_id = 'TRK007',
    @track_manager_id = 'INST015';

-- DELETE track
EXEC sp_DeleteTrack @track_id = 'TRK007';

-- ================================================================
-- 5. TRACK_INTAKE PROCEDURES
-- ================================================================

-- INSERT track-intake relationship
EXEC sp_InsertTrackIntake 
    @track_id = 'TRK001',
    @intake_number = 'INT2026-01',
    @start_date = '2026-01-15',
    @end_date = '2026-06-30',
    @capacity = 30;

-- SELECT all track-intake relationships
EXEC sp_SelectTrackIntake;

-- SELECT by track
EXEC sp_SelectTrackIntake @track_id = 'TRK001';

-- SELECT by intake
EXEC sp_SelectTrackIntake @intake_number = 'INT2025-01';

-- UPDATE track-intake
EXEC sp_UpdateTrackIntake 
    @track_id = 'TRK001',
    @intake_number = 'INT2026-01',
    @capacity = 35;

-- DELETE track-intake
EXEC sp_DeleteTrackIntake 
    @track_id = 'TRK001',
    @intake_number = 'INT2026-01';

-- ================================================================
-- 6. INSTRUCTOR_TRACK PROCEDURES
-- ================================================================

-- INSERT instructor-track assignment
EXEC sp_InsertInstructorTrack 
    @instructor_id = 'INST008',
    @track_id = 'TRK001',
    @assignment_date = '2024-01-15',
    @role = 'Senior Instructor';

-- SELECT all assignments
EXEC sp_SelectInstructorTrack;

-- SELECT by instructor
EXEC sp_SelectInstructorTrack @instructor_id = 'INST001';

-- SELECT by track
EXEC sp_SelectInstructorTrack @track_id = 'TRK001';

-- UPDATE assignment
EXEC sp_UpdateInstructorTrack 
    @instructor_id = 'INST008',
    @track_id = 'TRK001',
    @role = 'Lead Instructor';

-- DELETE assignment
EXEC sp_DeleteInstructorTrack 
    @instructor_id = 'INST008',
    @track_id = 'TRK001';

-- ================================================================
-- 7. STUDENT PROCEDURES
-- ================================================================

-- INSERT student
EXEC sp_InsertStudent 
    @stud_id = 7001,
    @login = 'new.student',
    @password = 'Pass@2024',
    @track_id = 'TRK001';

-- SELECT all students
EXEC sp_SelectStudent;

-- SELECT specific student
EXEC sp_SelectStudent @stud_id = 1001;

-- UPDATE student
EXEC sp_UpdateStudent 
    @stud_id = 7001,
    @password = 'NewPass@2024';

-- DELETE student
EXEC sp_DeleteStudent @stud_id = 7001;

-- ================================================================
-- 8. STUDENT_INFO PROCEDURES
-- ================================================================

-- INSERT student info
EXEC sp_InsertStudentInfo 
    @stud_id = 7001,
    @f_name = 'Omar',
    @mid_name = 'Ali',
    @last_name = 'Hassan',
    @gender = 'M',
    @faculty = 'Engineering',
    @phone = '01234567890',
    @FB_email = 'omar.ali@example.com',
    @city = 'Cairo',
    @street = '15 Nasr City',
    @date_of_birth = '2002-03-15',
    @zip_code = '11765';

-- SELECT all student info
EXEC sp_SelectStudentInfo;

-- SELECT specific student info
EXEC sp_SelectStudentInfo @stud_id = 1001;

-- UPDATE student info
EXEC sp_UpdateStudentInfo 
    @stud_id = 7001,
    @phone = '01098765432',
    @city = 'Giza';

-- DELETE student info
EXEC sp_DeleteStudentInfo @stud_id = 7001;

-- ================================================================
-- 9. COURSE PROCEDURES
-- ================================================================

-- INSERT course
EXEC sp_InsertCourse 
    @course_id = 'CRS030',
    @course_name = 'Advanced Database Design',
    @credit_hour = 4,
    @category = 'Database',
    @introduce_by = 'INST003',
    @track_id = 'TRK001';

-- SELECT all courses
EXEC sp_SelectCourse;

-- SELECT specific course
EXEC sp_SelectCourse @course_id = 'CRS001';

-- UPDATE course
EXEC sp_UpdateCourse 
    @course_id = 'CRS030',
    @credit_hour = 5;

-- DELETE course
EXEC sp_DeleteCourse @course_id = 'CRS030';

-- ================================================================
-- 10. STUDENT_COURSE PROCEDURES
-- ================================================================

-- INSERT student-course enrollment
EXEC sp_InsertStudentCourse 
    @student_id = 1001,
    @course_id = 'CRS005',
    @enrollment_date = '2024-01-20',
    @status = 'enrolled';

-- SELECT all enrollments
EXEC sp_SelectStudentCourse;

-- SELECT by student
EXEC sp_SelectStudentCourse @student_id = 1001;

-- SELECT by course
EXEC sp_SelectStudentCourse @course_id = 'CRS001';

-- UPDATE enrollment
EXEC sp_UpdateStudentCourse 
    @student_id = 1001,
    @course_id = 'CRS005',
    @completion_date = '2024-05-15',
    @grade = 'A',
    @status = 'completed';

-- DELETE enrollment
EXEC sp_DeleteStudentCourse 
    @student_id = 1001,
    @course_id = 'CRS005';

-- ================================================================
-- 11. INSTRUCTOR_COURSE PROCEDURES
-- ================================================================

-- INSERT instructor-course assignment
EXEC sp_InsertInstructorCourse 
    @instructor_id = 'INST001',
    @course_id = 'CRS001',
    @course_date = '2025-01-20',
    @for_year = 2025;

-- SELECT all assignments
EXEC sp_SelectInstructorCourse;

-- SELECT by instructor
EXEC sp_SelectInstructorCourse @instructor_id = 'INST001';

-- SELECT by course
EXEC sp_SelectInstructorCourse @course_id = 'CRS001';

-- UPDATE assignment
EXEC sp_UpdateInstructorCourse 
    @instructor_id = 'INST001',
    @course_id = 'CRS001',
    @course_date_old = '2025-01-20',
    @course_date_new = '2025-02-01';

-- DELETE assignment
EXEC sp_DeleteInstructorCourse 
    @instructor_id = 'INST001',
    @course_id = 'CRS001',
    @course_date = '2025-02-01';

-- ================================================================
-- 12. TOPIC PROCEDURES
-- ================================================================

-- INSERT topic
EXEC sp_InsertTopic 
    @topic_id = 'TOP031',
    @course_id = 'CRS001',
    @topic_name = 'Advanced C# Features',
    @topic_description = 'LINQ, async/await, delegates',
    @topic_order = 6;

-- SELECT all topics
EXEC sp_SelectTopic;

-- SELECT specific topic
EXEC sp_SelectTopic @topic_id = 'TOP001';

-- SELECT topics by course
EXEC sp_SelectTopic @course_id = 'CRS001';

-- UPDATE topic
EXEC sp_UpdateTopic 
    @topic_id = 'TOP031',
    @topic_name = 'C# Advanced Concepts',
    @topic_order = 5;

-- DELETE topic
EXEC sp_DeleteTopic @topic_id = 'TOP031';

-- ================================================================
-- 13. QUESTION PROCEDURES
-- ================================================================

-- INSERT question (returns question_id)
DECLARE @new_question_id INT;
EXEC sp_InsertQuestion 
    @course_id = 'CRS001',
    @created_by_inst_id = 'INST001',
    @question_content = 'What is polymorphism in C#?',
    @question_type = 'MCQ',
    @marks = 3,
    @difficulty_level = 'Medium',
    @question_id_out = @new_question_id OUTPUT;

PRINT 'New Question ID: ' + CAST(@new_question_id AS NVARCHAR(10));

-- SELECT all questions
EXEC sp_SelectQuestion;

-- SELECT specific question
EXEC sp_SelectQuestion @question_id = 1;

-- SELECT questions by course
EXEC sp_SelectQuestion @course_id = 'CRS001';

-- UPDATE question
EXEC sp_UpdateQuestion 
    @question_id = @new_question_id,
    @difficulty_level = 'Hard';

-- DELETE question
EXEC sp_DeleteQuestion @question_id = @new_question_id;

-- ================================================================
-- 14. CHOICES PROCEDURES
-- ================================================================

-- INSERT choice
EXEC sp_InsertChoice 
    @choice_id = 'CH161',
    @question_id = 1,
    @choice_content = 'Ability to take many forms',
    @is_correct = 1,
    @choice_order = 'A';

-- SELECT all choices
EXEC sp_SelectChoice;

-- SELECT specific choice
EXEC sp_SelectChoice @choice_id = 'CH001';

-- SELECT choices for a question
EXEC sp_SelectChoice @question_id = 1;

-- UPDATE choice
EXEC sp_UpdateChoice 
    @choice_id = 'CH161',
    @choice_content = 'Ability of objects to take multiple forms';

-- DELETE choice
EXEC sp_DeleteChoice @choice_id = 'CH161';

-- ================================================================
-- 15. EXAM PROCEDURES
-- ================================================================

-- INSERT exam
EXEC sp_InsertExam 
    @exam_id = 'EX020',
    @course_id = 'CRS001',
    @created_by_inst_id = 'INST001',
    @exam_title = 'C# Advanced Concepts - Quiz',
    @total_marks = 25,
    @passing_score = 15,
    @duration_minutes = 45,
    @status = 'draft';

-- SELECT all exams
EXEC sp_SelectExam;

-- SELECT specific exam
EXEC sp_SelectExam @exam_id = 'EX001';

-- SELECT exams by course
EXEC sp_SelectExam @course_id = 'CRS001';

-- UPDATE exam (activate it)
EXEC sp_UpdateExam 
    @exam_id = 'EX020',
    @status = 'active';

-- DELETE exam
EXEC sp_DeleteExam @exam_id = 'EX020';

-- ================================================================
-- 16. EXAM_QUES PROCEDURES
-- ================================================================

-- INSERT exam question
EXEC sp_InsertExamQues 
    @exam_id = 'EX001',
    @question_id = 1,
    @question_order = 6,
    @marks_allocated = 5;

-- SELECT all exam questions
EXEC sp_SelectExamQues;

-- SELECT exam questions for specific exam
EXEC sp_SelectExamQues @exam_id = 'EX001';

-- UPDATE exam question
EXEC sp_UpdateExamQues 
    @exam_question_id = 1,
    @marks_allocated = 6;

-- DELETE exam question
EXEC sp_DeleteExamQues @exam_question_id = 1;

-- ================================================================
-- 17. EXAM_SUBMIT PROCEDURES
-- ================================================================

-- INSERT exam submission (student starts exam)
EXEC sp_InsertExamSubmit 
    @student_id = 1001,
    @exam_id = 'EX001',
    @attempt_number = 1,
    @status = 'in_progress';

-- SELECT all submissions
EXEC sp_SelectExamSubmit;

-- SELECT by student
EXEC sp_SelectExamSubmit @student_id = 1001;

-- SELECT by exam
EXEC sp_SelectExamSubmit @exam_id = 'EX001';

-- UPDATE submission (mark as submitted)
EXEC sp_UpdateExamSubmit 
    @stud_submit_id = 'SUB1001-EX001-A1',
    @submit_time = '2024-01-20 10:30:00',
    @submit_date = '2024-01-20',
    @total_score = 18.50,
    @status = 'submitted';

-- DELETE submission
EXEC sp_DeleteExamSubmit @stud_submit_id = 'SUB1001-EX001-A1';

-- ================================================================
-- 18. STUDENT_ANSWER PROCEDURES
-- ================================================================

-- INSERT student answer
EXEC sp_InsertStudentAnswer 
    @student_exam_id = 'SUB1001-EX001-A1',
    @exam_question_id = 1,
    @selected_choice_id = 'CH001',
    @is_correct = 1,
    @marks_earned = 4.00;

-- SELECT all answers
EXEC sp_SelectStudentAnswer;

-- SELECT answers for a submission
EXEC sp_SelectStudentAnswer @student_exam_id = 'SUB1001-EX001-A1';

-- UPDATE answer (student changes answer)
EXEC sp_UpdateStudentAnswer 
    @answer_id = 1,
    @selected_choice_id = 'CH002',
    @is_correct = 0,
    @marks_earned = 0.00;

-- DELETE answer
EXEC sp_DeleteStudentAnswer @answer_id = 1;

-- ================================================================
-- COMPLETE WORKFLOW EXAMPLES
-- ================================================================

/*
Example 1: Enroll a New Student
================================
*/

-- Step 1: Create student account
EXEC sp_InsertStudent 
    @stud_id = 8001,
    @login = 'new.student2024',
    @password = 'SecurePass@123',
    @track_id = 'TRK001';

-- Step 2: Add student information
EXEC sp_InsertStudentInfo 
    @stud_id = 8001,
    @f_name = 'Ahmed',
    @mid_name = 'Khaled',
    @last_name = 'Mahmoud',
    @gender = 'M',
    @faculty = 'Engineering',
    @phone = '01055554444',
    @FB_email = 'ahmed.k@example.com',
    @city = 'Cairo',
    @street = '20 Heliopolis',
    @date_of_birth = '2002-06-15',
    @zip_code = '11361';

-- Step 3: Enroll in courses
EXEC sp_InsertStudentCourse 
    @student_id = 8001,
    @course_id = 'CRS001',
    @status = 'enrolled';

/*
Example 2: Create and Activate an Exam
=======================================
*/

-- Step 1: Create exam
EXEC sp_InsertExam 
    @exam_id = 'EX_NEW',
    @course_id = 'CRS001',
    @created_by_inst_id = 'INST001',
    @exam_title = 'C# Fundamentals - New Quiz',
    @total_marks = 20,
    @passing_score = 12,
    @duration_minutes = 60,
    @status = 'draft';

-- Step 2: Add questions to exam
EXEC sp_InsertExamQues @exam_id = 'EX_NEW', @question_id = 1, @question_order = 1, @marks_allocated = 4;
EXEC sp_InsertExamQues @exam_id = 'EX_NEW', @question_id = 2, @question_order = 2, @marks_allocated = 4;
EXEC sp_InsertExamQues @exam_id = 'EX_NEW', @question_id = 3, @question_order = 3, @marks_allocated = 6;

-- Step 3: Activate exam
EXEC sp_UpdateExam @exam_id = 'EX_NEW', @status = 'active';

/*
Example 3: Student Takes Exam
==============================
*/

-- Step 1: Start exam
EXEC sp_InsertExamSubmit 
    @student_id = 8001,
    @exam_id = 'EX_NEW',
    @attempt_number = 1,
    @status = 'in_progress';

-- Step 2: Submit answers
EXEC sp_InsertStudentAnswer @student_exam_id = 'SUB8001-EX_NEW-A1', @exam_question_id = 1, @selected_choice_id = 'CH001', @is_correct = 1, @marks_earned = 4.00;
EXEC sp_InsertStudentAnswer @student_exam_id = 'SUB8001-EX_NEW-A1', @exam_question_id = 2, @selected_choice_id = 'CH005', @is_correct = 1, @marks_earned = 4.00;
EXEC sp_InsertStudentAnswer @student_exam_id = 'SUB8001-EX_NEW-A1', @exam_question_id = 3, @selected_choice_id = 'CH009', @is_correct = 1, @marks_earned = 6.00;

-- Step 3: Submit exam
EXEC sp_UpdateExamSubmit 
    @stud_submit_id = 'SUB8001-EX_NEW-A1',
    @submit_time = GETDATE(),
    @submit_date = CAST(GETDATE() AS DATE),
    @total_score = 14.00,
    @status = 'submitted';

-- ================================================================
-- CLEANUP EXAMPLES
-- ================================================================

-- Delete the test student and all related data (cascades)
EXEC sp_DeleteStudent @stud_id = 8001;

-- Delete the test exam (cascades to exam questions and submissions)
EXEC sp_DeleteExam @exam_id = 'EX_NEW';

-- ================================================================
-- END OF USAGE GUIDE
-- ================================================================

PRINT '========================================';
PRINT 'CRUD Procedures Usage Guide Complete';
PRINT '72 Procedures across 18 tables';
PRINT '========================================';
