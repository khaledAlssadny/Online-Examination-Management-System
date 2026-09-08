-- ================================================================
-- ITI EXAMINATION SYSTEM - REPORTING STORED PROCEDURES
-- ================================================================
-- Purpose: Comprehensive reporting and analytics procedures
-- 
-- Procedures included:
--   1. sp_GetStudentsCountByTrackOrDept    - Student enrollment counts
--   2. sp_GetStudentCoursesAndGrades       - Student's courses and grades
--   3. sp_GetInstructorCoursesAndStudents  - Instructor's courses and enrollment
--   4. sp_GetCourseTopics                  - Topics for a course
--   5. sp_GetExamQuestionsAndChoices       - Exam questions with all choices
--   6. sp_GetStudentExamAnswersWithModel   - Student answers vs correct answers
-- ================================================================

USE ITI_EXAMINATION;
GO

-- ================================================================
-- PROCEDURE 1: Get Students Count by Track or Department
-- ================================================================
-- Purpose: Count students enrolled in a track or all tracks in a department
-- Parameters: @track_id OR @dept_id (provide one, not both)
-- ================================================================

IF OBJECT_ID('sp_GetStudentsCountByTrackOrDept', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetStudentsCountByTrackOrDept;
GO

CREATE PROCEDURE sp_GetStudentsCountByTrackOrDept
    @track_id NVARCHAR(20) = NULL,
    @dept_id  NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

     SELECT 
            s.stud_id,
            CONCAT(si.f_name, ' ', si.mid_name, ' ', si.last_name) as student_name,
            si.gender,
            si.city,
            si.phone,
            si.FB_email,
            DATEDIFF(YEAR, si.date_of_birth, GETDATE()) as age
        FROM STUDENT s
        JOIN STUDENT_INFO si ON s.stud_id = si.stud_id
        WHERE s.track_id = @track_id
        ORDER BY si.f_name, si.last_name;
END;
GO

-- ================================================================
-- PROCEDURE 2: Get Student's Courses and Grades
-- ================================================================
-- Purpose: Show all courses a student is enrolled in with grades
-- Parameters: @stud_id
-- ================================================================

IF OBJECT_ID('sp_GetStudentCoursesAndGrades', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetStudentCoursesAndGrades;
GO

CREATE PROCEDURE sp_GetStudentCoursesAndGrades
    @stud_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.course_id,
        c.course_name,
        c.category,
        c.credit_hour,
        sc.enrollment_date,
        sc.completion_date,
        sc.grade,
        sc.status,
        CASE 
            WHEN sc.grade IN ('A','A-','B+','B','B-','C+','C') THEN 'Pass'
            WHEN sc.grade IN ('C-','D+','D','F') THEN 'Fail'
            WHEN sc.status = 'enrolled' THEN 'In Progress'
            ELSE 'N/A'
        END AS pass_fail
    FROM STUDENT_COURSE sc
    JOIN COURSE c ON sc.course_id = c.course_id
    WHERE sc.student_id = @stud_id
    ORDER BY sc.enrollment_date DESC;
END;
GO

-- ================================================================
-- PROCEDURE 3: Get Instructor's Courses and Students
-- ================================================================
-- Purpose: Show courses taught by instructor and student enrollment
-- Parameters: @instructor_id
-- ================================================================

IF OBJECT_ID('sp_GetInstructorCoursesAndStudents', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetInstructorCoursesAndStudents;
GO

CREATE PROCEDURE sp_GetInstructorCoursesAndStudents
    @instructor_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.course_id,
        c.course_name,
        c.category,
        c.credit_hour,
        t.track_name,
        ic.for_year,
        ic.course_date,
        COUNT(DISTINCT sc.student_id) AS students_enrolled
    FROM INSTRUCTOR_COURSE ic
    JOIN COURSE c ON ic.course_id = c.course_id
    JOIN TRACK t ON c.track_id = t.track_id
    LEFT JOIN STUDENT_COURSE sc ON c.course_id = sc.course_id
    WHERE ic.instructor_id = @instructor_id
    GROUP BY 
        c.course_id, c.course_name, c.category, c.credit_hour,
        t.track_name, ic.for_year, ic.course_date
    ORDER BY ic.for_year DESC, ic.course_date DESC;
END;
GO

-- ================================================================
-- PROCEDURE 4: Get Course Topics
-- ================================================================
-- Purpose: List all topics in a course
-- Parameters: @course_id
-- ================================================================

IF OBJECT_ID('sp_GetCourseTopics', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetCourseTopics;
GO

CREATE PROCEDURE sp_GetCourseTopics
    @course_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        topic_id,
        topic_order,
        topic_name,
        topic_description
    FROM TOPIC
    WHERE course_id = @course_id
    ORDER BY topic_order;
END;
GO

-- ================================================================
-- PROCEDURE 5: Get Exam Questions and Choices
-- ================================================================
-- Purpose: Show all questions in an exam with their choices
-- Parameters: @exam_id
-- ================================================================

IF OBJECT_ID('sp_GetExamQuestionsAndChoices', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetExamQuestionsAndChoices;
GO

CREATE PROCEDURE sp_GetExamQuestionsAndChoices
    @exam_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        eq.exam_question_id,
        eq.question_order,
        q.question_type,
        q.question_content,
        eq.marks_allocated,
        ch.choice_id,
        ch.choice_order,
        ch.choice_content,
        ch.is_correct
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    LEFT JOIN CHOICES ch ON q.question_id = ch.question_id
    WHERE eq.exam_id = @exam_id
    ORDER BY eq.question_order, ch.choice_order;
END;
GO

-- ================================================================
-- PROCEDURE 6: Get Student Exam Answers with Model Answer
-- ================================================================
-- Purpose: Show student's answers compared to correct answers
-- Parameters: @exam_id, @student_id
-- ================================================================

IF OBJECT_ID('sp_GetStudentExamAnswersWithModel', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetStudentExamAnswersWithModel;
GO

CREATE PROCEDURE sp_GetStudentExamAnswersWithModel
    @exam_id NVARCHAR(20),
    @student_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @submission_id NVARCHAR(50);

    SELECT TOP 1 
        @submission_id = stud_submit_id
    FROM EXAM_SUBMIT
    WHERE student_id = @student_id AND exam_id = @exam_id
    ORDER BY attempt_number DESC;

    SELECT 
        eq.question_order,
        q.question_type,
        q.question_content,
        eq.marks_allocated,
        ch_student.choice_content AS student_answer,
        ch_correct.choice_content AS model_answer,
        CASE 
            WHEN sa.is_correct = 1 THEN 'Correct'
            WHEN sa.is_correct = 0 THEN 'Wrong'
            ELSE 'Not Answered'
        END AS result,
        ISNULL(sa.marks_earned, 0) AS marks_earned
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    LEFT JOIN CHOICES ch_correct 
        ON q.question_id = ch_correct.question_id 
       AND ch_correct.is_correct = 1
    LEFT JOIN STUDENT_ANSWER sa 
        ON eq.exam_question_id = sa.exam_question_id
       AND sa.student_exam_id = @submission_id
    LEFT JOIN CHOICES ch_student 
        ON sa.selected_choice_id = ch_student.choice_id
    WHERE eq.exam_id = @exam_id
    ORDER BY eq.question_order;
END;
GO

-- ================================================================
-- CREATION COMPLETE
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'ALL REPORTING PROCEDURES CREATED!';
PRINT '========================================';
PRINT '';
PRINT 'Available Procedures:';
PRINT '  1. sp_GetStudentsCountByTrackOrDept';
PRINT '  2. sp_GetStudentCoursesAndGrades';
PRINT '  3. sp_GetInstructorCoursesAndStudents';
PRINT '  4. sp_GetCourseTopics';
PRINT '  5. sp_GetExamQuestionsAndChoices';
PRINT '  6. sp_GetStudentExamAnswersWithModel';
PRINT '';

GO

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

PRINT '========================================';
PRINT 'USAGE EXAMPLES';
PRINT '========================================';
PRINT '';

-- Example 1: Get students by track
PRINT '-- Example 1: Get students in a track';
PRINT '--------------------------------------';
EXEC sp_GetStudentsCountByTrackOrDept @track_id = 'TRK001';
PRINT '';

-- Example 2: Get students by department
PRINT '-- Example 2: Get students in a department';
PRINT '-------------------------------------------';
EXEC sp_GetStudentsCountByTrackOrDept @dept_id = 'DEPT001';
PRINT '';

-- Example 3: Get student's courses and grades
PRINT '-- Example 3: Student academic record';
PRINT '--------------------------------------';
EXEC sp_GetStudentCoursesAndGrades @stud_id = 1001;
PRINT '';

-- Example 4: Get instructor's courses
PRINT '-- Example 4: Instructor teaching report';
PRINT '-----------------------------------------';
EXEC sp_GetInstructorCoursesAndStudents @instructor_id = 'INST001';
PRINT '';

-- Example 5: Get course topics
PRINT '-- Example 5: Course topics';
PRINT '----------------------------';
EXEC sp_GetCourseTopics @course_id = 'CRS001';
PRINT '';

-- Example 6: Get exam questions
PRINT '-- Example 6: Exam questions and choices';
PRINT '-----------------------------------------';
EXEC sp_GetExamQuestionsAndChoices @exam_id = 'EX001';
PRINT '';

-- Example 7: Get student exam answers with model
PRINT '-- Example 7: Student exam review';
PRINT '----------------------------------';
EXEC sp_GetStudentExamAnswersWithModel 
    @exam_id = 'EX001', 
    @student_id = 1001;

PRINT '';
PRINT '========================================';
PRINT 'ALL EXAMPLES COMPLETED!';
PRINT '========================================';

GO
