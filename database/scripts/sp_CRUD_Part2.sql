-- ================================================================
-- ITI EXAMINATION SYSTEM - CRUD PROCEDURES PART 2
-- ================================================================
-- Tables 10-18 (Remaining 9 tables, 36 procedures)
-- ================================================================

USE ITI_EXAMINATION;
GO

PRINT '========================================';
PRINT 'CRUD Procedures Part 2: Tables 10-18';
PRINT 'Procedures 37-72';
PRINT '========================================';
PRINT '';
GO

-- ================================================================
-- TABLE 10: STUDENT_COURSE
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertStudentCourse', 'P') IS NOT NULL DROP PROCEDURE sp_InsertStudentCourse;
GO
CREATE PROCEDURE sp_InsertStudentCourse
    @student_id INT,
    @course_id NVARCHAR(20),
    @enrollment_date DATE = NULL,
    @completion_date DATE = NULL,
    @grade NVARCHAR(5) = NULL,
    @status NVARCHAR(20) = 'enrolled'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO STUDENT_COURSE (student_id, course_id, enrollment_date, completion_date, grade, status)
        VALUES (@student_id, @course_id, ISNULL(@enrollment_date, GETDATE()), @completion_date, @grade, @status);
        
        PRINT '✓ Student-Course enrollment inserted successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectStudentCourse', 'P') IS NOT NULL DROP PROCEDURE sp_SelectStudentCourse;
GO
CREATE PROCEDURE sp_SelectStudentCourse
    @student_id INT = NULL,
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT sc.*, c.course_name, 
           CONCAT(si.f_name, ' ', si.last_name) as student_name
    FROM STUDENT_COURSE sc
    JOIN COURSE c ON sc.course_id = c.course_id
    JOIN STUDENT_INFO si ON sc.student_id = si.stud_id
    WHERE (@student_id IS NULL OR sc.student_id = @student_id)
      AND (@course_id IS NULL OR sc.course_id = @course_id)
    ORDER BY sc.enrollment_date DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateStudentCourse', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateStudentCourse;
GO
CREATE PROCEDURE sp_UpdateStudentCourse
    @student_id INT,
    @course_id NVARCHAR(20),
    @enrollment_date DATE = NULL,
    @completion_date DATE = NULL,
    @grade NVARCHAR(5) = NULL,
    @status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE STUDENT_COURSE
        SET 
            enrollment_date = ISNULL(@enrollment_date, enrollment_date),
            completion_date = ISNULL(@completion_date, completion_date),
            grade = ISNULL(@grade, grade),
            status = ISNULL(@status, status)
        WHERE student_id = @student_id AND course_id = @course_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Student-Course enrollment updated successfully';
        ELSE
            PRINT '✗ Student-Course enrollment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteStudentCourse', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteStudentCourse;
GO
CREATE PROCEDURE sp_DeleteStudentCourse
    @student_id INT,
    @course_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM STUDENT_COURSE 
        WHERE student_id = @student_id AND course_id = @course_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Student-Course enrollment deleted successfully';
        ELSE
            PRINT '✗ Student-Course enrollment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ STUDENT_COURSE procedures created (40/72)';
GO

-- ================================================================
-- TABLE 11: INSTRUCTOR_COURSE
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertInstructorCourse', 'P') IS NOT NULL DROP PROCEDURE sp_InsertInstructorCourse;
GO
CREATE PROCEDURE sp_InsertInstructorCourse
    @instructor_id NVARCHAR(20),
    @course_id NVARCHAR(20),
    @course_date DATE,
    @for_year INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO INSTRUCTOR_COURSE (instructor_id, course_id, course_date, for_year)
        VALUES (@instructor_id, @course_id, @course_date, @for_year);
        
        PRINT '✓ Instructor-Course assignment inserted successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectInstructorCourse', 'P') IS NOT NULL DROP PROCEDURE sp_SelectInstructorCourse;
GO
CREATE PROCEDURE sp_SelectInstructorCourse
    @instructor_id NVARCHAR(20) = NULL,
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ic.*, i.instructor_name, c.course_name
    FROM INSTRUCTOR_COURSE ic
    JOIN INSTRUCTOR i ON ic.instructor_id = i.instructor_id
    JOIN COURSE c ON ic.course_id = c.course_id
    WHERE (@instructor_id IS NULL OR ic.instructor_id = @instructor_id)
      AND (@course_id IS NULL OR ic.course_id = @course_id)
    ORDER BY ic.for_year DESC, ic.course_date DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateInstructorCourse', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateInstructorCourse;
GO
CREATE PROCEDURE sp_UpdateInstructorCourse
    @instructor_id NVARCHAR(20),
    @course_id NVARCHAR(20),
    @course_date_old DATE,
    @course_date_new DATE = NULL,
    @for_year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE INSTRUCTOR_COURSE
        SET 
            course_date = ISNULL(@course_date_new, course_date),
            for_year = ISNULL(@for_year, for_year)
        WHERE instructor_id = @instructor_id 
          AND course_id = @course_id 
          AND course_date = @course_date_old;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Instructor-Course assignment updated successfully';
        ELSE
            PRINT '✗ Instructor-Course assignment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteInstructorCourse', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteInstructorCourse;
GO
CREATE PROCEDURE sp_DeleteInstructorCourse
    @instructor_id NVARCHAR(20),
    @course_id NVARCHAR(20),
    @course_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM INSTRUCTOR_COURSE 
        WHERE instructor_id = @instructor_id 
          AND course_id = @course_id 
          AND course_date = @course_date;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Instructor-Course assignment deleted successfully';
        ELSE
            PRINT '✗ Instructor-Course assignment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ INSTRUCTOR_COURSE procedures created (44/72)';
GO

-- ================================================================
-- TABLE 12: TOPIC
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertTopic', 'P') IS NOT NULL DROP PROCEDURE sp_InsertTopic;
GO
CREATE PROCEDURE sp_InsertTopic
    @topic_id NVARCHAR(20),
    @course_id NVARCHAR(20),
    @topic_name NVARCHAR(150),
    @topic_description NVARCHAR(MAX) = NULL,
    @topic_order INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO TOPIC (topic_id, course_id, topic_name, topic_description, topic_order)
        VALUES (@topic_id, @course_id, @topic_name, @topic_description, @topic_order);
        
        PRINT CONCAT('✓ Topic ', @topic_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectTopic', 'P') IS NOT NULL DROP PROCEDURE sp_SelectTopic;
GO
CREATE PROCEDURE sp_SelectTopic
    @topic_id NVARCHAR(20) = NULL,
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @topic_id IS NOT NULL
        SELECT t.*, c.course_name
        FROM TOPIC t
        JOIN COURSE c ON t.course_id = c.course_id
        WHERE t.topic_id = @topic_id;
    ELSE IF @course_id IS NOT NULL
        SELECT t.*, c.course_name
        FROM TOPIC t
        JOIN COURSE c ON t.course_id = c.course_id
        WHERE t.course_id = @course_id
        ORDER BY t.topic_order;
    ELSE
        SELECT t.*, c.course_name
        FROM TOPIC t
        JOIN COURSE c ON t.course_id = c.course_id
        ORDER BY c.course_name, t.topic_order;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateTopic', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateTopic;
GO
CREATE PROCEDURE sp_UpdateTopic
    @topic_id NVARCHAR(20),
    @course_id NVARCHAR(20) = NULL,
    @topic_name NVARCHAR(150) = NULL,
    @topic_description NVARCHAR(MAX) = NULL,
    @topic_order INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE TOPIC
        SET 
            course_id = ISNULL(@course_id, course_id),
            topic_name = ISNULL(@topic_name, topic_name),
            topic_description = ISNULL(@topic_description, topic_description),
            topic_order = ISNULL(@topic_order, topic_order)
        WHERE topic_id = @topic_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Topic ', @topic_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Topic ', @topic_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteTopic', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteTopic;
GO
CREATE PROCEDURE sp_DeleteTopic
    @topic_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM TOPIC WHERE topic_id = @topic_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Topic ', @topic_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Topic ', @topic_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ TOPIC procedures created (48/72)';
GO

-- ================================================================
-- TABLE 13: QUESTION
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertQuestion', 'P') IS NOT NULL DROP PROCEDURE sp_InsertQuestion;
GO
CREATE PROCEDURE sp_InsertQuestion
    @course_id NVARCHAR(20),
    @created_by_inst_id NVARCHAR(20),
    @question_content NVARCHAR(MAX),
    @question_type NVARCHAR(20),
    @marks INT,
    @difficulty_level NVARCHAR(20) = NULL,
    @question_id_out INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO QUESTION (course_id, created_by_inst_id, question_content, 
                             question_type, marks, difficulty_level, created_date)
        VALUES (@course_id, @created_by_inst_id, @question_content,
                @question_type, @marks, @difficulty_level, GETDATE());
        
        SET @question_id_out = SCOPE_IDENTITY();
        PRINT CONCAT('✓ Question ', @question_id_out, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectQuestion', 'P') IS NOT NULL DROP PROCEDURE sp_SelectQuestion;
GO
CREATE PROCEDURE sp_SelectQuestion
    @question_id INT = NULL,
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT q.*, c.course_name, i.instructor_name as created_by
    FROM QUESTION q
    JOIN COURSE c ON q.course_id = c.course_id
    JOIN INSTRUCTOR i ON q.created_by_inst_id = i.instructor_id
    WHERE (@question_id IS NULL OR q.question_id = @question_id)
      AND (@course_id IS NULL OR q.course_id = @course_id)
    ORDER BY q.created_date DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateQuestion', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateQuestion;
GO
CREATE PROCEDURE sp_UpdateQuestion
    @question_id INT,
    @course_id NVARCHAR(20) = NULL,
    @question_content NVARCHAR(MAX) = NULL,
    @question_type NVARCHAR(20) = NULL,
    @marks INT = NULL,
    @difficulty_level NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE QUESTION
        SET 
            course_id = ISNULL(@course_id, course_id),
            question_content = ISNULL(@question_content, question_content),
            question_type = ISNULL(@question_type, question_type),
            marks = ISNULL(@marks, marks),
            difficulty_level = ISNULL(@difficulty_level, difficulty_level)
        WHERE question_id = @question_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Question ', @question_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Question ', @question_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteQuestion', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteQuestion;
GO
CREATE PROCEDURE sp_DeleteQuestion
    @question_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM QUESTION WHERE question_id = @question_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Question ', @question_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Question ', @question_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ QUESTION procedures created (52/72)';
GO

-- ================================================================
-- TABLE 14: CHOICES
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertChoice', 'P') IS NOT NULL DROP PROCEDURE sp_InsertChoice;
GO
CREATE PROCEDURE sp_InsertChoice
    @choice_id NVARCHAR(20),
    @question_id INT,
    @choice_content NVARCHAR(500),
    @is_correct BIT = 0,
    @choice_order NCHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO CHOICES (choice_id, question_id, choice_content, is_correct, choice_order)
        VALUES (@choice_id, @question_id, @choice_content, @is_correct, @choice_order);
        
        PRINT CONCAT('✓ Choice ', @choice_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectChoice', 'P') IS NOT NULL DROP PROCEDURE sp_SelectChoice;
GO
CREATE PROCEDURE sp_SelectChoice
    @choice_id NVARCHAR(20) = NULL,
    @question_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ch.*, q.question_content
    FROM CHOICES ch
    JOIN QUESTION q ON ch.question_id = q.question_id
    WHERE (@choice_id IS NULL OR ch.choice_id = @choice_id)
      AND (@question_id IS NULL OR ch.question_id = @question_id)
    ORDER BY ch.question_id, ch.choice_order;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateChoice', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateChoice;
GO
CREATE PROCEDURE sp_UpdateChoice
    @choice_id NVARCHAR(20),
    @question_id INT = NULL,
    @choice_content NVARCHAR(500) = NULL,
    @is_correct BIT = NULL,
    @choice_order NCHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE CHOICES
        SET 
            question_id = ISNULL(@question_id, question_id),
            choice_content = ISNULL(@choice_content, choice_content),
            is_correct = ISNULL(@is_correct, is_correct),
            choice_order = ISNULL(@choice_order, choice_order)
        WHERE choice_id = @choice_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Choice ', @choice_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Choice ', @choice_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteChoice', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteChoice;
GO
CREATE PROCEDURE sp_DeleteChoice
    @choice_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM CHOICES WHERE choice_id = @choice_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Choice ', @choice_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Choice ', @choice_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ CHOICES procedures created (56/72)';
GO

-- ================================================================
-- TABLE 15: EXAM
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertExam', 'P') IS NOT NULL DROP PROCEDURE sp_InsertExam;
GO
CREATE PROCEDURE sp_InsertExam
    @exam_id NVARCHAR(20),
    @course_id NVARCHAR(20),
    @created_by_inst_id NVARCHAR(20),
    @exam_title NVARCHAR(200),
    @total_marks INT,
    @passing_score INT,
    @duration_minutes INT,
    @total_result INT = NULL,
    @status NVARCHAR(20) = 'draft'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO EXAM (exam_id, course_id, created_by_inst_id, exam_title,
                         total_marks, passing_score, duration_minutes, 
                         created_date, total_result, status)
        VALUES (@exam_id, @course_id, @created_by_inst_id, @exam_title,
                @total_marks, @passing_score, @duration_minutes,
                GETDATE(), @total_result, @status);
        
        PRINT CONCAT('✓ Exam ', @exam_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectExam', 'P') IS NOT NULL DROP PROCEDURE sp_SelectExam;
GO
CREATE PROCEDURE sp_SelectExam
    @exam_id NVARCHAR(20) = NULL,
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT e.*, c.course_name, i.instructor_name as created_by
    FROM EXAM e
    JOIN COURSE c ON e.course_id = c.course_id
    JOIN INSTRUCTOR i ON e.created_by_inst_id = i.instructor_id
    WHERE (@exam_id IS NULL OR e.exam_id = @exam_id)
      AND (@course_id IS NULL OR e.course_id = @course_id)
    ORDER BY e.created_date DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateExam', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateExam;
GO
CREATE PROCEDURE sp_UpdateExam
    @exam_id NVARCHAR(20),
    @exam_title NVARCHAR(200) = NULL,
    @total_marks INT = NULL,
    @passing_score INT = NULL,
    @duration_minutes INT = NULL,
    @total_result INT = NULL,
    @status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE EXAM
        SET 
            exam_title = ISNULL(@exam_title, exam_title),
            total_marks = ISNULL(@total_marks, total_marks),
            passing_score = ISNULL(@passing_score, passing_score),
            duration_minutes = ISNULL(@duration_minutes, duration_minutes),
            total_result = ISNULL(@total_result, total_result),
            status = ISNULL(@status, status)
        WHERE exam_id = @exam_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Exam ', @exam_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Exam ', @exam_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteExam', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteExam;
GO
CREATE PROCEDURE sp_DeleteExam
    @exam_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM EXAM WHERE exam_id = @exam_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Exam ', @exam_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Exam ', @exam_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ EXAM procedures created (60/72)';
GO

-- ================================================================
-- TABLE 16: EXAM_QUES
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertExamQues', 'P') IS NOT NULL DROP PROCEDURE sp_InsertExamQues;
GO
CREATE PROCEDURE sp_InsertExamQues
    @exam_id NVARCHAR(20),
    @question_id INT,
    @question_order INT,
    @marks_allocated INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Note: Uses trigger for auto-ID generation
        INSERT INTO EXAM_QUES (exam_id, question_id, question_order, marks_allocated)
        VALUES (@exam_id, @question_id, @question_order, @marks_allocated);
        
        PRINT '✓ Exam question assigned successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectExamQues', 'P') IS NOT NULL DROP PROCEDURE sp_SelectExamQues;
GO
CREATE PROCEDURE sp_SelectExamQues
    @exam_question_id INT = NULL,
    @exam_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT eq.*, e.exam_title, q.question_content, q.question_type
    FROM EXAM_QUES eq
    JOIN EXAM e ON eq.exam_id = e.exam_id
    JOIN QUESTION q ON eq.question_id = q.question_id
    WHERE (@exam_question_id IS NULL OR eq.exam_question_id = @exam_question_id)
      AND (@exam_id IS NULL OR eq.exam_id = @exam_id)
    ORDER BY eq.exam_id, eq.question_order;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateExamQues', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateExamQues;
GO
CREATE PROCEDURE sp_UpdateExamQues
    @exam_question_id INT,
    @question_order INT = NULL,
    @marks_allocated INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE EXAM_QUES
        SET 
            question_order = ISNULL(@question_order, question_order),
            marks_allocated = ISNULL(@marks_allocated, marks_allocated)
        WHERE exam_question_id = @exam_question_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Exam question updated successfully';
        ELSE
            PRINT '✗ Exam question not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteExamQues', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteExamQues;
GO
CREATE PROCEDURE sp_DeleteExamQues
    @exam_question_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM EXAM_QUES WHERE exam_question_id = @exam_question_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Exam question deleted successfully';
        ELSE
            PRINT '✗ Exam question not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ EXAM_QUES procedures created (64/72)';
GO

-- ================================================================
-- TABLE 17: EXAM_SUBMIT
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertExamSubmit', 'P') IS NOT NULL DROP PROCEDURE sp_InsertExamSubmit;
GO
CREATE PROCEDURE sp_InsertExamSubmit
    @student_id INT,
    @exam_id NVARCHAR(20),
    @attempt_number INT = 1,
    @status NVARCHAR(20) = 'in_progress'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Uses trigger for auto-ID generation
        INSERT INTO EXAM_SUBMIT (student_id, exam_id, start_time, attempt_number, status)
        VALUES (@student_id, @exam_id, GETDATE(), @attempt_number, @status);
        
        PRINT '✓ Exam submission created successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectExamSubmit', 'P') IS NOT NULL DROP PROCEDURE sp_SelectExamSubmit;
GO
CREATE PROCEDURE sp_SelectExamSubmit
    @stud_submit_id NVARCHAR(20) = NULL,
    @student_id INT = NULL,
    @exam_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT es.*, e.exam_title, CONCAT(si.f_name, ' ', si.last_name) as student_name
    FROM EXAM_SUBMIT es
    JOIN EXAM e ON es.exam_id = e.exam_id
    JOIN STUDENT_INFO si ON es.student_id = si.stud_id
    WHERE (@stud_submit_id IS NULL OR es.stud_submit_id = @stud_submit_id)
      AND (@student_id IS NULL OR es.student_id = @student_id)
      AND (@exam_id IS NULL OR es.exam_id = @exam_id)
    ORDER BY es.start_time DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateExamSubmit', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateExamSubmit;
GO
CREATE PROCEDURE sp_UpdateExamSubmit
    @stud_submit_id NVARCHAR(20),
    @submit_time DATETIME = NULL,
    @submit_date DATE = NULL,
    @total_score DECIMAL(5, 2) = NULL,
    @status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE EXAM_SUBMIT
        SET 
            submit_time = ISNULL(@submit_time, submit_time),
            submit_date = ISNULL(@submit_date, submit_date),
            total_score = ISNULL(@total_score, total_score),
            status = ISNULL(@status, status)
        WHERE stud_submit_id = @stud_submit_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Exam submission updated successfully';
        ELSE
            PRINT '✗ Exam submission not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteExamSubmit', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteExamSubmit;
GO
CREATE PROCEDURE sp_DeleteExamSubmit
    @stud_submit_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM EXAM_SUBMIT WHERE stud_submit_id = @stud_submit_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Exam submission deleted successfully';
        ELSE
            PRINT '✗ Exam submission not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ EXAM_SUBMIT procedures created (68/72)';
GO

-- ================================================================
-- TABLE 18: STUDENT_ANSWER
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertStudentAnswer', 'P') IS NOT NULL DROP PROCEDURE sp_InsertStudentAnswer;
GO
CREATE PROCEDURE sp_InsertStudentAnswer
    @student_exam_id NVARCHAR(20),
    @exam_question_id INT,
    @selected_choice_id NVARCHAR(20),
    @is_correct BIT = NULL,
    @marks_earned DECIMAL(5, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Uses trigger for auto-ID generation
        INSERT INTO STUDENT_ANSWER (student_exam_id, exam_question_id, selected_choice_id, 
                                    is_correct, marks_earned, answered_at)
        VALUES (@student_exam_id, @exam_question_id, @selected_choice_id,
                @is_correct, @marks_earned, GETDATE());
        
        PRINT '✓ Student answer inserted successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectStudentAnswer', 'P') IS NOT NULL DROP PROCEDURE sp_SelectStudentAnswer;
GO
CREATE PROCEDURE sp_SelectStudentAnswer
    @answer_id INT = NULL,
    @student_exam_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT sa.*, 
           eq.question_order, 
           q.question_content,
           ch.choice_content as selected_answer
    FROM STUDENT_ANSWER sa
    JOIN EXAM_QUES eq ON sa.exam_question_id = eq.exam_question_id
    JOIN QUESTION q ON eq.question_id = q.question_id
    JOIN CHOICES ch ON sa.selected_choice_id = ch.choice_id
    WHERE (@answer_id IS NULL OR sa.answer_id = @answer_id)
      AND (@student_exam_id IS NULL OR sa.student_exam_id = @student_exam_id)
    ORDER BY sa.student_exam_id, eq.question_order;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateStudentAnswer', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateStudentAnswer;
GO
CREATE PROCEDURE sp_UpdateStudentAnswer
    @answer_id INT,
    @selected_choice_id NVARCHAR(20) = NULL,
    @is_correct BIT = NULL,
    @marks_earned DECIMAL(5, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE STUDENT_ANSWER
        SET 
            selected_choice_id = ISNULL(@selected_choice_id, selected_choice_id),
            is_correct = ISNULL(@is_correct, is_correct),
            marks_earned = ISNULL(@marks_earned, marks_earned),
            answered_at = GETDATE()
        WHERE answer_id = @answer_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Student answer updated successfully';
        ELSE
            PRINT '✗ Student answer not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteStudentAnswer', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteStudentAnswer;
GO
CREATE PROCEDURE sp_DeleteStudentAnswer
    @answer_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM STUDENT_ANSWER WHERE answer_id = @answer_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Student answer deleted successfully';
        ELSE
            PRINT '✗ Student answer not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ STUDENT_ANSWER procedures created (72/72)';
GO

-- ================================================================
-- COMPLETION SUMMARY
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'ALL CRUD PROCEDURES CREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT 'Total Tables: 18';
PRINT 'Total Procedures: 72 (4 per table)';
PRINT '';
PRINT 'Procedure Naming Convention:';
PRINT '  - sp_Insert[TableName]';
PRINT '  - sp_Select[TableName]';
PRINT '  - sp_Update[TableName]';
PRINT '  - sp_Delete[TableName]';
PRINT '';
PRINT '========================================';
GO
