-- ================================================================
-- STORED PROCEDURE: Generate Random Exam for Course
-- ================================================================
-- Purpose: Automatically create an exam with random questions from course question pool
-- 
-- Parameters:
--   @course_id          - Which course to create exam for
--   @exam_title         - Title/name of the exam
--   @num_mcq            - Number of MCQ questions to include
--   @num_truefalse      - Number of True/False questions to include
--   @duration_minutes   - Exam duration in minutes
--   @created_by_inst_id - Instructor creating the exam
--   @passing_percentage - Passing percentage (default 60%)
--   @exam_id_out        - OUTPUT: Returns the generated exam_id
--
-- Features:
--   - Randomly selects questions from course question pool
--   - Validates sufficient questions exist
--   - Distributes marks appropriately
--   - Creates exam and assigns questions automatically
--   - Returns new exam_id for further use
--
-- Usage Example:
--   DECLARE @new_exam_id NVARCHAR(20);
--   EXEC sp_GenerateRandomExam 
--       @course_id = 'CRS001',
--       @exam_title = 'C# Midterm Exam - Random',
--       @num_mcq = 8,
--       @num_truefalse = 4,
--       @duration_minutes = 90,
--       @created_by_inst_id = 'INST001',
--       @passing_percentage = 60,
--       @exam_id_out = @new_exam_id OUTPUT;
--   
--   PRINT 'New Exam Created: ' + @new_exam_id;
-- ================================================================

USE ITI_EXAMINATION;
GO

-- Drop if exists
IF OBJECT_ID('sp_GenerateRandomExam', 'P') IS NOT NULL
    DROP PROCEDURE sp_GenerateRandomExam;
GO

CREATE PROCEDURE sp_GenerateRandomExam
    @course_id NVARCHAR(20),
    @exam_title NVARCHAR(200),
    @num_mcq INT,
    @num_truefalse INT,
    @duration_minutes INT,
    @created_by_inst_id NVARCHAR(20),
    @passing_percentage DECIMAL(5,2) = 60.0,  -- Default 60%
    @exam_id_out NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- ================================================================
    -- VARIABLE DECLARATIONS
    -- ================================================================
    DECLARE @total_questions INT;
    DECLARE @available_mcq INT;
    DECLARE @available_truefalse INT;
    DECLARE @total_marks INT;
    DECLARE @passing_score INT;
    DECLARE @exam_id NVARCHAR(20);
    DECLARE @marks_per_mcq INT;
    DECLARE @marks_per_tf INT;
    DECLARE @question_order INT;
    DECLARE @error_msg NVARCHAR(500);
    
    -- Transaction control
    DECLARE @transaction_started BIT = 0;
    
    BEGIN TRY
        -- ================================================================
        -- STEP 1: VALIDATION
        -- ================================================================
        
        -- Validate course exists
        IF NOT EXISTS (SELECT 1 FROM COURSE WHERE course_id = @course_id)
        BEGIN
            RAISERROR('Course ID %s does not exist', 16, 1, @course_id);
            RETURN;
        END
        
        -- Validate instructor exists
        IF NOT EXISTS (SELECT 1 FROM INSTRUCTOR WHERE instructor_id = @created_by_inst_id)
        BEGIN
            RAISERROR('Instructor ID %s does not exist', 16, 1, @created_by_inst_id);
            RETURN;
        END
        
        -- Validate positive numbers
        IF @num_mcq < 0 OR @num_truefalse < 0
        BEGIN
            RAISERROR('Number of questions cannot be negative', 16, 1);
            RETURN;
        END
        
        -- Validate at least one question requested
        SET @total_questions = @num_mcq + @num_truefalse;
        IF @total_questions = 0
        BEGIN
            RAISERROR('Exam must have at least one question', 16, 1);
            RETURN;
        END
        
        -- Validate duration
        IF @duration_minutes <= 0
        BEGIN
            RAISERROR('Exam duration must be greater than 0 minutes', 16, 1);
            RETURN;
        END
        
        -- ================================================================
        -- STEP 2: CHECK AVAILABLE QUESTIONS IN COURSE
        -- ================================================================
        
        -- Count available MCQ questions
        SELECT @available_mcq = COUNT(*)
        FROM QUESTION
        WHERE course_id = @course_id 
          AND question_type = 'MCQ';
        
        -- Count available True/False questions
        SELECT @available_truefalse = COUNT(*)
        FROM QUESTION
        WHERE course_id = @course_id 
          AND question_type = 'TrueFalse';
        
        -- Validate sufficient questions available
        IF @num_mcq > @available_mcq
        BEGIN
            SET @error_msg = CONCAT(
                'Insufficient MCQ questions. Requested: ', @num_mcq,
                ', Available: ', @available_mcq
            );
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END
        
        IF @num_truefalse > @available_truefalse
        BEGIN
            SET @error_msg = CONCAT(
                'Insufficient True/False questions. Requested: ', @num_truefalse,
                ', Available: ', @available_truefalse
            );
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END
        
        -- ================================================================
        -- STEP 3: CALCULATE MARKS DISTRIBUTION
        -- ================================================================
        
        -- Standard mark allocation:
        -- MCQ questions: 3 marks each
        -- True/False questions: 2 marks each
        SET @marks_per_mcq = 3;
        SET @marks_per_tf = 2;
        
        SET @total_marks = (@num_mcq * @marks_per_mcq) + (@num_truefalse * @marks_per_tf);
        SET @passing_score = CEILING(@total_marks * (@passing_percentage / 100.0));
        
        -- ================================================================
        -- STEP 4: GENERATE UNIQUE EXAM ID
        -- ================================================================
        
        -- Generate exam ID format: EX + timestamp-based unique number
        SET @exam_id = CONCAT('EX', 
            FORMAT(GETDATE(), 'yyyyMMdd'),
            RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3)
        );
        
        -- Ensure uniqueness (very unlikely to conflict, but safe)
        WHILE EXISTS (SELECT 1 FROM EXAM WHERE exam_id = @exam_id)
        BEGIN
            SET @exam_id = CONCAT('EX', 
                FORMAT(GETDATE(), 'yyyyMMdd'),
                RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS NVARCHAR(3)), 3)
            );
        END
        
        -- ================================================================
        -- STEP 5: START TRANSACTION AND CREATE EXAM
        -- ================================================================
        
        BEGIN TRANSACTION;
        SET @transaction_started = 1;
        
        -- Insert the exam
        INSERT INTO EXAM (
            exam_id,
            course_id,
            created_by_inst_id,
            exam_title,
            total_marks,
            passing_score,
            duration_minutes,
            created_date,
            total_result,
            status
        )
        VALUES (
            @exam_id,
            @course_id,
            @created_by_inst_id,
            @exam_title,
            @total_marks,
            @passing_score,
            @duration_minutes,
            GETDATE(),
            NULL,
            'draft'  -- New exam starts as draft
        );
        
        PRINT CONCAT('✓ Exam created: ', @exam_id);
        PRINT CONCAT('  Title: ', @exam_title);
        PRINT CONCAT('  Total Marks: ', @total_marks);
        PRINT CONCAT('  Passing Score: ', @passing_score, ' (', @passing_percentage, '%)');
        PRINT '';
        
        -- ================================================================
        -- STEP 6: SELECT AND ASSIGN RANDOM MCQ QUESTIONS
        -- ================================================================
        
        SET @question_order = 1;
        
        IF @num_mcq > 0
        BEGIN
            PRINT CONCAT('Selecting ', @num_mcq, ' random MCQ questions...');
            
            -- Insert random MCQ questions into EXAM_QUES
            -- Note: This uses the trigger to auto-generate exam_question_id
            INSERT INTO EXAM_QUES (exam_id, question_id, question_order, marks_allocated)
            SELECT TOP (@num_mcq)
                @exam_id,
                question_id,
                ROW_NUMBER() OVER (ORDER BY NEWID()) as question_order,
                @marks_per_mcq
            FROM QUESTION
            WHERE course_id = @course_id 
              AND question_type = 'MCQ'
            ORDER BY NEWID();  -- Random selection
            
            SET @question_order = @question_order + @num_mcq;
            PRINT CONCAT('✓ Added ', @num_mcq, ' MCQ questions (', @marks_per_mcq, ' marks each)');
        END
        
        -- ================================================================
        -- STEP 7: SELECT AND ASSIGN RANDOM TRUE/FALSE QUESTIONS
        -- ================================================================
        
        IF @num_truefalse > 0
        BEGIN
            PRINT CONCAT('Selecting ', @num_truefalse, ' random True/False questions...');
            
            -- Insert random True/False questions into EXAM_QUES
            INSERT INTO EXAM_QUES (exam_id, question_id, question_order, marks_allocated)
            SELECT TOP (@num_truefalse)
                @exam_id,
                question_id,
                ROW_NUMBER() OVER (ORDER BY NEWID()) + (@num_mcq) as question_order,
                @marks_per_tf
            FROM QUESTION
            WHERE course_id = @course_id 
              AND question_type = 'TrueFalse'
            ORDER BY NEWID();  -- Random selection
            
            PRINT CONCAT('✓ Added ', @num_truefalse, ' True/False questions (', @marks_per_tf, ' marks each)');
        END
        
        -- ================================================================
        -- STEP 8: COMMIT AND RETURN
        -- ================================================================
        
        COMMIT TRANSACTION;
        SET @transaction_started = 0;
        
        -- Set output parameter
        SET @exam_id_out = @exam_id;
        
        PRINT '';
        PRINT '========================================';
        PRINT 'EXAM GENERATED SUCCESSFULLY!';
        PRINT '========================================';
        PRINT CONCAT('Exam ID: ', @exam_id);
        PRINT CONCAT('Total Questions: ', @total_questions);
        PRINT CONCAT('  - MCQ: ', @num_mcq);
        PRINT CONCAT('  - True/False: ', @num_truefalse);
        PRINT CONCAT('Duration: ', @duration_minutes, ' minutes');
        PRINT 'Status: draft (use sp_ActivateExam to make it active)';
        PRINT '';
        
    END TRY
    BEGIN CATCH
        -- Rollback if transaction is active
        IF @transaction_started = 1
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Transaction rolled back due to error.';
        END
        
        -- Re-throw the error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN;
    END CATCH
END
GO

-- ================================================================
-- BONUS: HELPER STORED PROCEDURE - Activate Exam
-- ================================================================
-- Purpose: Change exam status from 'draft' to 'active'
-- ================================================================

IF OBJECT_ID('sp_ActivateExam', 'P') IS NOT NULL
    DROP PROCEDURE sp_ActivateExam;
GO

CREATE PROCEDURE sp_ActivateExam
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
    
    -- Validate exam has questions
    IF NOT EXISTS (SELECT 1 FROM EXAM_QUES WHERE exam_id = @exam_id)
    BEGIN
        RAISERROR('Cannot activate exam %s - no questions assigned', 16, 1, @exam_id);
        RETURN;
    END
    
    -- Update status
    UPDATE EXAM
    SET status = 'active'
    WHERE exam_id = @exam_id;
    
    PRINT CONCAT('✓ Exam ', @exam_id, ' is now ACTIVE and ready for students');
END
GO

-- ================================================================
-- BONUS: HELPER STORED PROCEDURE - View Exam Details
-- ================================================================
-- Purpose: Display complete exam information with all questions
-- ================================================================

IF OBJECT_ID('sp_ViewExamDetails', 'P') IS NOT NULL
    DROP PROCEDURE sp_ViewExamDetails;
GO

CREATE PROCEDURE sp_ViewExamDetails
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
    
    PRINT '========================================';
    PRINT 'EXAM DETAILS';
    PRINT '========================================';
    
    -- Exam header info
    SELECT 
        exam_id as 'Exam ID',
        exam_title as 'Title',
        c.course_name as 'Course',
        i.instructor_name as 'Created By',
        total_marks as 'Total Marks',
        passing_score as 'Passing Score',
        duration_minutes as 'Duration (min)',
        status as 'Status',
        FORMAT(created_date, 'yyyy-MM-dd') as 'Created Date'
    FROM EXAM e
    JOIN COURSE c ON e.course_id = c.course_id
    JOIN INSTRUCTOR i ON e.created_by_inst_id = i.instructor_id
    WHERE e.exam_id = @exam_id;
    
    PRINT '';
    PRINT 'Questions:';
    PRINT '========================================';
    
    -- Exam questions
    SELECT 
        eq.exam_question_id as 'Exam Question ID',
        eq.question_order as '#',
        q.question_type as 'Type',
        LEFT(q.question_content, 60) + '...' as 'Question',
        eq.marks_allocated as 'Marks',
        q.difficulty_level as 'Difficulty'
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    WHERE eq.exam_id = @exam_id
    ORDER BY eq.question_order;
    
    PRINT '';
    PRINT 'Statistics:';
    PRINT '========================================';
    
    -- Question statistics
    SELECT 
        question_type as 'Question Type',
        COUNT(*) as 'Count',
        SUM(marks_allocated) as 'Total Marks'
    FROM EXAM_QUES eq
    JOIN QUESTION q ON eq.question_id = q.question_id
    WHERE eq.exam_id = @exam_id
    GROUP BY question_type;
END
GO

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'STORED PROCEDURES CREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT 'Available Procedures:';
PRINT '  1. sp_GenerateRandomExam  - Generate exam with random questions';
PRINT '  2. sp_ActivateExam        - Activate a draft exam';
PRINT '  3. sp_ViewExamDetails     - View exam information';
PRINT '';
PRINT '========================================';
PRINT 'USAGE EXAMPLES:';
PRINT '========================================';
PRINT '';
PRINT '-- Example 1: Generate a C# exam';
PRINT 'DECLARE @new_exam NVARCHAR(20);';
PRINT 'EXEC sp_GenerateRandomExam ';
PRINT '    @course_id = ''CRS001'',';
PRINT '    @exam_title = ''C# Fundamentals - Final Exam'',';
PRINT '    @num_mcq = 8,';
PRINT '    @num_truefalse = 4,';
PRINT '    @duration_minutes = 90,';
PRINT '    @created_by_inst_id = ''INST001'',';
PRINT '    @passing_percentage = 65,';
PRINT '    @exam_id_out = @new_exam OUTPUT;';
PRINT '';
PRINT 'PRINT ''New Exam ID: '' + @new_exam;';
PRINT '';
PRINT '-- Example 2: Activate the exam';
PRINT 'EXEC sp_ActivateExam @exam_id = @new_exam;';
PRINT '';
PRINT '-- Example 3: View exam details';
PRINT 'EXEC sp_ViewExamDetails @exam_id = @new_exam;';
PRINT '';

GO

-- ================================================================
-- TEST: Generate a sample exam
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'RUNNING TEST: Generating Sample Exam';
PRINT '========================================';
PRINT '';

DECLARE @test_exam_id NVARCHAR(20);

EXEC sp_GenerateRandomExam 
    @course_id = 'CRS001',
    @exam_title = 'C# Programming - Auto-Generated Test Exam',
    @num_mcq = 2,
    @num_truefalse = 1,
    @duration_minutes = 60,
    @created_by_inst_id = 'INST001',
    @passing_percentage = 60,
    @exam_id_out = @test_exam_id OUTPUT;

PRINT '';
PRINT 'Viewing generated exam details...';
PRINT '';

EXEC sp_ViewExamDetails @exam_id = @test_exam_id;
EXEC sp_ViewExamDetails @exam_id = 'EX20260122269';
PRINT '';
PRINT 'Activating exam...';
PRINT '';

EXEC sp_ActivateExam @exam_id = @test_exam_id;
EXEC sp_ActivateExam @exam_id = 'EX20260122269';
PRINT '';
PRINT '========================================';
PRINT 'TEST COMPLETED SUCCESSFULLY!';
PRINT '========================================';

GO
