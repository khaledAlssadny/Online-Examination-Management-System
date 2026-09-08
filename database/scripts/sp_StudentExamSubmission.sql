-- ================================================================
-- STORED PROCEDURE: Student Exam Submission System
-- ================================================================
-- Purpose: Allow students to start, answer, and submit exams
-- 
-- This system provides 3 main procedures:
--   1. sp_StartExam         - Student starts taking an exam
--   2. sp_SubmitAnswer      - Student submits answer to a question
--   3. sp_SubmitExam        - Student submits the complete exam
--
-- Additional helper procedures:
--   4. sp_GetExamQuestions  - Get all questions for an exam
--   5. sp_GetStudentProgress - Check student's progress on exam
--   6. sp_GradeExam         - Auto-grade a submitted exam
--
-- ================================================================

USE ITI_EXAMINATION;
GO

-- ================================================================
-- PROCEDURE 1: Start Exam
-- ================================================================
-- Purpose: Student begins taking an exam
-- Creates a submission record and returns submission ID
-- ================================================================

IF OBJECT_ID('sp_StartExam', 'P') IS NOT NULL
    DROP PROCEDURE sp_StartExam;
GO

CREATE PROCEDURE sp_StartExam
    @student_id INT,
    @exam_id NVARCHAR(20),
    @submission_id_out NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @attempt_number INT;
    DECLARE @exam_status NVARCHAR(20);
    DECLARE @submission_id NVARCHAR(50);
    
    BEGIN TRY
        -- ================================================================
        -- VALIDATION
        -- ================================================================
        
        -- Check if student exists
        IF NOT EXISTS (SELECT 1 FROM STUDENT WHERE stud_id = @student_id)
        BEGIN
            RAISERROR('Student ID %d does not exist', 16, 1, @student_id);
            RETURN;
        END
        
        -- Check if exam exists
        IF NOT EXISTS (SELECT 1 FROM EXAM WHERE exam_id = @exam_id)
        BEGIN
            RAISERROR('Exam ID %s does not exist', 16, 1, @exam_id);
            RETURN;
        END
        
        -- Check if exam is active
        SELECT @exam_status = status FROM EXAM WHERE exam_id = @exam_id;
        IF @exam_status != 'active'
        BEGIN
            RAISERROR('Exam %s is not active (status: %s)', 16, 1, @exam_id, @exam_status);
            RETURN;
        END
        
        -- Check if student is enrolled in the course
        IF NOT EXISTS (
            SELECT 1 
            FROM STUDENT s
            JOIN EXAM e ON e.exam_id = @exam_id
            WHERE s.stud_id = @student_id 
              AND s.track_id IN (
                  SELECT track_id 
                  FROM COURSE 
                  WHERE course_id = e.course_id
              )
        )
        BEGIN
            PRINT 'Warning: Student may not be enrolled in this course';
        END
        
        -- Check if student already has an in-progress submission
        IF EXISTS (
            SELECT 1 
            FROM EXAM_SUBMIT 
            WHERE student_id = @student_id 
              AND exam_id = @exam_id 
              AND status = 'in_progress'
        )
        BEGIN
            -- Return existing submission
            SELECT @submission_id = stud_submit_id
            FROM EXAM_SUBMIT
            WHERE student_id = @student_id 
              AND exam_id = @exam_id 
              AND status = 'in_progress';
            
            SET @submission_id_out = @submission_id;
            
            PRINT '========================================';
            PRINT 'RESUMING EXISTING EXAM';
            PRINT '========================================';
            PRINT CONCAT('Submission ID: ', @submission_id);
            PRINT 'You can continue answering questions.';
            RETURN;
        END
        
        -- ================================================================
        -- DETERMINE ATTEMPT NUMBER
        -- ================================================================
        
        SELECT @attempt_number = ISNULL(MAX(attempt_number), 0) + 1
        FROM EXAM_SUBMIT
        WHERE student_id = @student_id 
          AND exam_id = @exam_id;
        
        -- ================================================================
        -- CREATE SUBMISSION (Trigger will generate submission_id)
        -- ================================================================
        
        -- Note: The trigger will create the submission_id automatically
        -- Format: SUB{student_id}-{exam_id}-A{attempt}
        INSERT INTO EXAM_SUBMIT (
            student_id,
            exam_id,
            start_time,
            submit_time,
            submit_date,
            total_score,
            attempt_number,
            status
        )
        VALUES (
            @student_id,
            @exam_id,
            GETDATE(),
            NULL,
            NULL,
            NULL,
            @attempt_number,
            'in_progress'
        );
        
        -- Get the generated submission_id
        SET @submission_id = CONCAT('SUB', @student_id, '-', @exam_id, '-A', @attempt_number);
        SET @submission_id_out = @submission_id;
        
        -- ================================================================
        -- SUCCESS MESSAGE
        -- ================================================================
        
        PRINT '========================================';
        PRINT 'EXAM STARTED SUCCESSFULLY';
        PRINT '========================================';
        PRINT CONCAT('Student ID: ', @student_id);
        PRINT CONCAT('Exam ID: ', @exam_id);
        PRINT CONCAT('Submission ID: ', @submission_id);
        PRINT CONCAT('Attempt Number: ', @attempt_number);
        PRINT CONCAT('Start Time: ', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'));
        
        -- Show exam info
        SELECT 
            @exam_id as exam_id,
            exam_title,
            total_marks,
            passing_score,
            duration_minutes,
            (SELECT COUNT(*) FROM EXAM_QUES WHERE exam_id = @exam_id) as total_questions
        FROM EXAM
        WHERE exam_id = @exam_id;
        
        PRINT ' ';
        PRINT 'Use sp_GetExamQuestions to see the questions.';
        PRINT 'Use sp_SubmitAnswer to answer each question.';
        PRINT 'Use sp_SubmitExam when finished.';
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- ================================================================
-- PROCEDURE 2: Get Exam Questions
-- ================================================================
-- Purpose: Retrieve all questions for an exam (for display to student)
-- ================================================================

IF OBJECT_ID('sp_GetExamQuestions', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetExamQuestions;
GO

CREATE PROCEDURE sp_GetExamQuestions
    @exam_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate exam exists
    IF NOT EXISTS (SELECT 1 FROM EXAM WHERE exam_id = @exam_id)
    BEGIN
        RAISERROR('Exam ID %s does not exist', 16, 1, @exam_id);
        RETURN;
    END
    
    -- Return all questions with their choices
    SELECT 
        eq.exam_question_id,
        eq.question_order,
        q.question_content,
        q.question_type,
        eq.marks_allocated,
        -- Get all choices for this question
        (
            SELECT 
                choice_id,
                choice_content,
                choice_order
            FROM CHOICES
            WHERE question_id = q.question_id
            ORDER BY choice_order
            FOR JSON PATH
        ) as choices_json
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    WHERE eq.exam_id = @exam_id
    ORDER BY eq.question_order;
    
    PRINT ' ';
    PRINT CONCAT('Total Questions: ', @@ROWCOUNT);
END
GO

-- ================================================================
-- PROCEDURE 3: Submit Answer to a Question
-- ================================================================
-- Purpose: Student submits answer to a single question
-- Validates answer and stores it
-- ================================================================

IF OBJECT_ID('sp_SubmitAnswer', 'P') IS NOT NULL
    DROP PROCEDURE sp_SubmitAnswer;
GO

CREATE PROCEDURE sp_SubmitAnswer
    @submission_id NVARCHAR(50),
    @exam_question_id NVARCHAR(50),
    @selected_choice_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @is_correct BIT;
    DECLARE @marks_earned DECIMAL(5,2);
    DECLARE @marks_allocated INT;
    DECLARE @question_id INT;
    DECLARE @submission_status NVARCHAR(20);
    
    BEGIN TRY
        -- ================================================================
        -- VALIDATION
        -- ================================================================
        
        -- Check if submission exists
        IF NOT EXISTS (SELECT 1 FROM EXAM_SUBMIT WHERE stud_submit_id = @submission_id)
        BEGIN
            RAISERROR('Submission ID %s does not exist', 16, 1, @submission_id);
            RETURN;
        END
        
        -- Check if submission is still in progress
        SELECT @submission_status = status
        FROM EXAM_SUBMIT
        WHERE stud_submit_id = @submission_id;
        
        IF @submission_status != 'in_progress'
        BEGIN
            RAISERROR('Cannot submit answer - exam is already %s', 16, 1, @submission_status);
            RETURN;
        END
        
        -- Check if exam question exists
        IF NOT EXISTS (SELECT 1 FROM EXAM_QUES WHERE exam_question_id = @exam_question_id)
        BEGIN
            RAISERROR('Exam question ID %s does not exist', 16, 1, @exam_question_id);
            RETURN;
        END
        
        -- Get question_id from exam_question_id
        SELECT @question_id = question_id, @marks_allocated = marks_allocated
        FROM EXAM_QUES
        WHERE exam_question_id = @exam_question_id;
        
        -- Validate choice belongs to this question
        IF NOT EXISTS (
            SELECT 1 
            FROM CHOICES 
            WHERE choice_id = @selected_choice_id 
              AND question_id = @question_id
        )
        BEGIN
            RAISERROR('Choice %s does not belong to this question', 16, 1, @selected_choice_id);
            RETURN;
        END
        
        -- ================================================================
        -- CHECK IF ANSWER IS CORRECT
        -- ================================================================
        
        SELECT @is_correct = is_correct
        FROM CHOICES
        WHERE choice_id = @selected_choice_id;
        
        -- Calculate marks earned
        IF @is_correct = 1
            SET @marks_earned = @marks_allocated;
        ELSE
            SET @marks_earned = 0;
        
        -- ================================================================
        -- SAVE ANSWER (Update if exists, Insert if new)
        -- ================================================================
        
        -- Check if answer already exists for this question
        IF EXISTS (
            SELECT 1 
            FROM STUDENT_ANSWER 
            WHERE student_exam_id = @submission_id 
              AND exam_question_id = @exam_question_id
        )
        BEGIN
            -- Update existing answer
            UPDATE STUDENT_ANSWER
            SET 
                selected_choice_id = @selected_choice_id,
                is_correct = @is_correct,
                marks_earned = @marks_earned,
                answered_at = GETDATE()
            WHERE student_exam_id = @submission_id 
              AND exam_question_id = @exam_question_id;
            
            PRINT CONCAT('✓ Answer updated for question ', @exam_question_id);
        END
        ELSE
        BEGIN
            -- Insert new answer (trigger will generate answer_id)
            INSERT INTO STUDENT_ANSWER (
                student_exam_id,
                exam_question_id,
                selected_choice_id,
                is_correct,
                marks_earned,
                answered_at
            )
            VALUES (
                @submission_id,
                @exam_question_id,
                @selected_choice_id,
                @is_correct,
                @marks_earned,
                GETDATE()
            );
            
            PRINT CONCAT('✓ Answer submitted for question ', @exam_question_id);
        END
        
        -- Show result (without revealing correct answer during exam)
        PRINT CONCAT('  Selected: ', @selected_choice_id);
        PRINT '  Status: Answer saved';
        
        -- Show progress
        DECLARE @answered INT, @total INT;
        
        SELECT @answered = COUNT(*)
        FROM STUDENT_ANSWER
        WHERE student_exam_id = @submission_id;
        
        SELECT @total = COUNT(*)
        FROM EXAM_QUES eq
        JOIN EXAM_SUBMIT es ON eq.exam_id = es.exam_id
        WHERE es.stud_submit_id = @submission_id;
        
        PRINT ' ';
        PRINT CONCAT('Progress: ', @answered, '/', @total, ' questions answered');
        
        IF @answered = @total
        BEGIN
            PRINT ' ';
            PRINT '========================================';
            PRINT 'ALL QUESTIONS ANSWERED!';
            PRINT 'Use sp_SubmitExam to submit your exam.';
            PRINT '========================================';
        END
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- ================================================================
-- PROCEDURE 4: Submit Complete Exam
-- ================================================================
-- Purpose: Student finalizes exam submission and triggers grading
-- ================================================================

IF OBJECT_ID('sp_SubmitExam', 'P') IS NOT NULL
    DROP PROCEDURE sp_SubmitExam;
GO

CREATE PROCEDURE sp_SubmitExam
    @submission_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @total_score DECIMAL(5,2);
    DECLARE @total_questions INT;
    DECLARE @answered_questions INT;
    DECLARE @submission_status NVARCHAR(20);
    
    BEGIN TRY
        -- ================================================================
        -- VALIDATION
        -- ================================================================
        
        -- Check if submission exists
        IF NOT EXISTS (SELECT 1 FROM EXAM_SUBMIT WHERE stud_submit_id = @submission_id)
        BEGIN
            RAISERROR('Submission ID %s does not exist', 16, 1, @submission_id);
            RETURN;
        END
        
        -- Check if already submitted
        SELECT @submission_status = status
        FROM EXAM_SUBMIT
        WHERE stud_submit_id = @submission_id;
        
        IF @submission_status != 'in_progress'
        BEGIN
            RAISERROR('Exam already %s - cannot submit again', 16, 1, @submission_status);
            RETURN;
        END
        
        -- ================================================================
        -- CHECK IF ALL QUESTIONS ANSWERED
        -- ================================================================
        
        -- Count total questions in exam
        SELECT @total_questions = COUNT(*)
        FROM EXAM_QUES eq
        JOIN EXAM_SUBMIT es ON eq.exam_id = es.exam_id
        WHERE es.stud_submit_id = @submission_id;
        
        -- Count answered questions
        SELECT @answered_questions = COUNT(*)
        FROM STUDENT_ANSWER
        WHERE student_exam_id = @submission_id;
        
        -- Warn if not all questions answered
        IF @answered_questions < @total_questions
        BEGIN
            PRINT 'WARNING: Not all questions have been answered!';
            PRINT CONCAT('Answered: ', @answered_questions, '/', @total_questions);
            PRINT 'Unanswered questions will score 0 marks.';
            PRINT ' ';
        END
        
        -- ================================================================
        -- CALCULATE TOTAL SCORE
        -- ================================================================
        
        SELECT @total_score = ISNULL(SUM(marks_earned), 0)
        FROM STUDENT_ANSWER
        WHERE student_exam_id = @submission_id;
        
        -- ================================================================
        -- UPDATE SUBMISSION
        -- ================================================================
        
        UPDATE EXAM_SUBMIT
        SET 
            submit_time = GETDATE(),
            submit_date = CAST(GETDATE() AS DATE),
            total_score = @total_score,
            status = 'submitted'  -- Will be 'graded' after manual review if needed
        WHERE stud_submit_id = @submission_id;
        
        -- Auto-grade if all questions are objective (MCQ/TrueFalse)
        -- This sets status to 'graded' automatically
        EXEC sp_GradeExam @submission_id = @submission_id;
        
        -- ================================================================
        -- SHOW RESULTS
        -- ================================================================
        
        PRINT '========================================';
        PRINT 'EXAM SUBMITTED SUCCESSFULLY';
        PRINT '========================================';
        
        -- Get exam details
        SELECT 
            es.stud_submit_id as submission_id,
            es.student_id,
            CONCAT(si.f_name, ' ', si.last_name) as student_name,
            es.exam_id,
            e.exam_title,
            e.total_marks,
            e.passing_score,
            es.total_score,
            CASE 
                WHEN es.total_score >= e.passing_score THEN 'PASSED ✓'
                ELSE 'FAILED ✗'
            END as result,
            CAST((es.total_score / e.total_marks * 100) AS DECIMAL(5,2)) as percentage,
            FORMAT(es.start_time, 'yyyy-MM-dd HH:mm:ss') as start_time,
            FORMAT(es.submit_time, 'yyyy-MM-dd HH:mm:ss') as submit_time,
            DATEDIFF(MINUTE, es.start_time, es.submit_time) as duration_minutes,
            @answered_questions as questions_answered,
            @total_questions as total_questions,
            es.status
        FROM EXAM_SUBMIT es
        JOIN EXAM e ON es.exam_id = e.exam_id
        JOIN STUDENT_INFO si ON es.student_id = si.stud_id
        WHERE es.stud_submit_id = @submission_id;
        
        PRINT ' ';
        PRINT 'Use sp_ViewSubmissionDetails to see your answers.';
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- ================================================================
-- PROCEDURE 5: Auto-Grade Exam
-- ================================================================
-- Purpose: Automatically grade exam (already done during answer submission)
-- ================================================================

IF OBJECT_ID('sp_GradeExam', 'P') IS NOT NULL
    DROP PROCEDURE sp_GradeExam;
GO

CREATE PROCEDURE sp_GradeExam
    @submission_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @total_score DECIMAL(5,2);
    
    -- Recalculate total score (answers are already graded)
    SELECT @total_score = ISNULL(SUM(marks_earned), 0)
    FROM STUDENT_ANSWER
    WHERE student_exam_id = @submission_id;
    
    -- Update submission with final score and graded status
    UPDATE EXAM_SUBMIT
    SET 
        total_score = @total_score,
        status = 'graded'
    WHERE stud_submit_id = @submission_id;
    
    PRINT CONCAT('✓ Exam graded. Total Score: ', @total_score);
END
GO

-- ================================================================
-- PROCEDURE 6: Get Student Progress
-- ================================================================
-- Purpose: Check student's progress on an in-progress exam
-- ================================================================

IF OBJECT_ID('sp_GetStudentProgress', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetStudentProgress;
GO

CREATE PROCEDURE sp_GetStudentProgress
    @submission_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate submission exists
    IF NOT EXISTS (SELECT 1 FROM EXAM_SUBMIT WHERE stud_submit_id = @submission_id)
    BEGIN
        RAISERROR('Submission ID %s does not exist', 16, 1, @submission_id);
        RETURN;
    END
    
    PRINT '========================================';
    PRINT 'EXAM PROGRESS';
    PRINT '========================================';
    
    -- Show overall progress
    SELECT 
        es.stud_submit_id,
        es.exam_id,
        e.exam_title,
        es.status,
        FORMAT(es.start_time, 'yyyy-MM-dd HH:mm:ss') as start_time,
        DATEDIFF(MINUTE, es.start_time, GETDATE()) as elapsed_minutes,
        e.duration_minutes as allowed_minutes,
        COUNT(sa.answer_id) as questions_answered,
        (SELECT COUNT(*) FROM EXAM_QUES WHERE exam_id = es.exam_id) as total_questions
    FROM EXAM_SUBMIT es
    JOIN EXAM e ON es.exam_id = e.exam_id
    LEFT JOIN STUDENT_ANSWER sa ON es.stud_submit_id = sa.student_exam_id
    WHERE es.stud_submit_id = @submission_id
    GROUP BY es.stud_submit_id, es.exam_id, e.exam_title, es.status, 
             es.start_time, e.duration_minutes;
    
    PRINT ' ';
    PRINT 'Answered Questions:';
    PRINT '-------------------';
    
    -- Show which questions are answered
    SELECT 
        eq.question_order,
        eq.exam_question_id,
        CASE WHEN sa.answer_id IS NOT NULL THEN 'Answered ✓' ELSE 'Not Answered' END as status,
        FORMAT(sa.answered_at, 'HH:mm:ss') as answered_at
    FROM EXAM_QUES eq
    JOIN EXAM_SUBMIT es ON eq.exam_id = es.exam_id
    LEFT JOIN STUDENT_ANSWER sa ON eq.exam_question_id = sa.exam_question_id 
                                AND sa.student_exam_id = es.stud_submit_id
    WHERE es.stud_submit_id = @submission_id
    ORDER BY eq.question_order;
END
GO

-- ================================================================
-- PROCEDURE 7: View Submission Details (After Submission)
-- ================================================================
-- Purpose: View complete submission with all answers and results
-- ================================================================

IF OBJECT_ID('sp_ViewSubmissionDetails', 'P') IS NOT NULL
    DROP PROCEDURE sp_ViewSubmissionDetails;
GO

CREATE PROCEDURE sp_ViewSubmissionDetails
    @submission_id NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate submission exists
    IF NOT EXISTS (SELECT 1 FROM EXAM_SUBMIT WHERE stud_submit_id = @submission_id)
    BEGIN
        RAISERROR('Submission ID %s does not exist', 16, 1, @submission_id);
        RETURN;
    END
    
    PRINT '========================================';
    PRINT 'SUBMISSION DETAILS';
    PRINT '========================================';
    
    -- Header info
    SELECT 
        es.stud_submit_id,
        es.student_id,
        CONCAT(si.f_name, ' ', si.last_name) as student_name,
        es.exam_id,
        e.exam_title,
        es.attempt_number,
        es.status,
        es.total_score,
        e.total_marks,
        e.passing_score,
        CASE 
            WHEN es.total_score >= e.passing_score THEN 'PASSED'
            ELSE 'FAILED'
        END as result,
        FORMAT(es.start_time, 'yyyy-MM-dd HH:mm:ss') as start_time,
        FORMAT(es.submit_time, 'yyyy-MM-dd HH:mm:ss') as submit_time,
        DATEDIFF(MINUTE, es.start_time, es.submit_time) as duration_minutes
    FROM EXAM_SUBMIT es
    JOIN EXAM e ON es.exam_id = e.exam_id
    JOIN STUDENT_INFO si ON es.student_id = si.stud_id
    WHERE es.stud_submit_id = @submission_id;
    
    PRINT ' ';
    PRINT 'Detailed Answers:';
    PRINT '=================';
    
    -- Detailed answers
    SELECT 
        eq.question_order as '#',
        LEFT(q.question_content, 50) + '...' as question,
        c_selected.choice_content as your_answer,
        c_correct.choice_content as correct_answer,
        CASE 
            WHEN sa.is_correct = 1 THEN 'Correct ✓'
            ELSE 'Wrong ✗'
        END as result,
        sa.marks_earned as marks_earned,
        eq.marks_allocated as max_marks
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    LEFT JOIN STUDENT_ANSWER sa ON eq.exam_question_id = sa.exam_question_id 
                                 AND sa.student_exam_id = @submission_id
    LEFT JOIN CHOICES c_selected ON sa.selected_choice_id = c_selected.choice_id
    LEFT JOIN CHOICES c_correct ON q.question_id = c_correct.question_id 
                                 AND c_correct.is_correct = 1
    WHERE eq.exam_id = (SELECT exam_id FROM EXAM_SUBMIT WHERE stud_submit_id = @submission_id)
    ORDER BY eq.question_order;
END
GO

-- ================================================================
-- CREATION COMPLETE
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'STORED PROCEDURES CREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT 'Student Exam Procedures:';
PRINT '  1. sp_StartExam           - Start taking an exam';
PRINT '  2. sp_GetExamQuestions    - View exam questions';
PRINT '  3. sp_SubmitAnswer        - Submit answer to a question';
PRINT '  4. sp_SubmitExam          - Submit complete exam';
PRINT '  5. sp_GetStudentProgress  - Check progress';
PRINT '  6. sp_ViewSubmissionDetails - View results';
PRINT '';

GO

-- ================================================================
-- COMPLETE USAGE EXAMPLE
-- ================================================================

PRINT '========================================';
PRINT 'COMPLETE EXAM FLOW EXAMPLE';
PRINT '========================================';
PRINT '';

-- ================================================================
-- STEP 1: Student starts the exam
-- ================================================================
PRINT '-- STEP 1: Start the exam';
PRINT '----------------------------';

EXEC sp_ActivateExam @exam_id = 'EX20260122269';

DECLARE @submission_id NVARCHAR(50);

EXEC sp_StartExam 
    @student_id = 1001,
    @exam_id = 'EX20260118399',
    @submission_id_out = @submission_id OUTPUT;

PRINT '';
PRINT CONCAT('Submission ID: ', @submission_id);
PRINT '';

-- ================================================================
-- STEP 2: Get exam questions
-- ================================================================
PRINT '-- STEP 2: View exam questions';
PRINT '----------------------------';

EXEC sp_GetExamQuestions @exam_id = 'EX20260122269';
PRINT '';

-- ================================================================
-- STEP 3: Submit answers
-- ================================================================
PRINT '-- STEP 3: Submit answers to questions';
PRINT '----------------------------';
SELECT * FROM EXAM_SUBMIT
--THE NEW SUB EXAM SUB1001-EX20260118399-A2
-- Answer Question 1


EXEC sp_SubmitAnswer 
    @submission_id = 'SUB1001-EX20260118399-A2',
    @exam_question_id = 'EX20260118399-Q001',
    @selected_choice_id = 'CH007';
PRINT '';

-- Answer Question 2
EXEC sp_SubmitAnswer 
    @submission_id = 'SUB1001-EX20260118399-A2',
    @exam_question_id = 'EX20260118399-Q002',
    @selected_choice_id = 'CH002';
PRINT '';

-- Answer Question 3
EXEC sp_SubmitAnswer 
    @submission_id = 'SUB1001-EX20260118399-A2',
    @exam_question_id = 'EX20260118399-Q003',
    @selected_choice_id = 'CH005';
PRINT '';

-- Answer Question 4
EXEC sp_SubmitAnswer 
    @submission_id = @submission_id,
    @exam_question_id = 'EX001-Q004',
    @selected_choice_id = 'CH001';
PRINT '';

-- Answer Question 5
EXEC sp_SubmitAnswer 
    @submission_id = @submission_id,
    @exam_question_id = 'EX001-Q005',
    @selected_choice_id = 'CH005';
PRINT '';

-- ================================================================
-- STEP 4: Check progress (optional)
-- ================================================================
PRINT '-- STEP 4: Check progress';
PRINT '----------------------------';

EXEC sp_GetStudentProgress @submission_id = @submission_id;
PRINT '';

EXEC sp_GetStudentProgress @submission_id = 'SUB1001-EX20260118399-A2';
PRINT '';

-- ================================================================
-- STEP 5: Submit the complete exam
-- ================================================================
PRINT '-- STEP 5: Submit the exam';
PRINT '----------------------------';

EXEC sp_SubmitExam @submission_id = @submission_id;
PRINT '';

EXEC sp_SubmitExam @submission_id = 'SUB1001-EX20260118399-A2';
PRINT '';

-- ================================================================
-- STEP 6: View detailed results
-- ================================================================
PRINT '-- STEP 6: View detailed results';
PRINT '----------------------------';

EXEC sp_ViewSubmissionDetails @submission_id = @submission_id;

EXEC sp_ViewSubmissionDetails @submission_id = 'SUB1001-EX20260118399-A2';

PRINT '';
PRINT '========================================';
PRINT 'COMPLETE EXAMPLE FINISHED!';
PRINT '========================================';

GO
