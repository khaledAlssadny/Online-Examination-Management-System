-- ================================================================
-- ITI EXAMINATION SYSTEM - COMPLETE CRUD STORED PROCEDURES
-- ================================================================
-- Purpose: Create INSERT, SELECT, UPDATE, DELETE procedures for all tables
-- 
-- Tables covered (18 total):
--   1. INSTRUCTOR              7. STUDENT               13. QUESTION
--   2. INTAKE                  8. STUDENT_INFO          14. CHOICES
--   3. DEPARTMENT              9. COURSE                15. EXAM
--   4. TRACK                  10. STUDENT_COURSE        16. EXAM_QUES
--   5. TRACK_INTAKE           11. INSTRUCTOR_COURSE     17. EXAM_SUBMIT
--   6. INSTRUCTOR_TRACK       12. TOPIC                 18. STUDENT_ANSWER
--
-- For each table, 4 procedures are created:
--   - sp_Insert[TableName]
--   - sp_Select[TableName]
--   - sp_Update[TableName]
--   - sp_Delete[TableName]
--
-- Total procedures: 72 (18 tables × 4 operations)
-- ================================================================

USE ITI_EXAMINATION;
GO

PRINT '========================================';
PRINT 'Creating CRUD Procedures for 18 Tables';
PRINT 'Total Procedures: 72 (18 × 4)';
PRINT '========================================';
PRINT '';
GO

-- ================================================================
-- TABLE 1: INSTRUCTOR
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertInstructor', 'P') IS NOT NULL DROP PROCEDURE sp_InsertInstructor;
GO
CREATE PROCEDURE sp_InsertInstructor
    @instructor_id NVARCHAR(20),
    @instructor_name NVARCHAR(100),
    @date_of_birth DATE,
    @salary DECIMAL(10, 2),
    @gender NCHAR(1),
    @hire_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO INSTRUCTOR (instructor_id, instructor_name, date_of_birth, salary, gender, hire_date)
        VALUES (@instructor_id, @instructor_name, @date_of_birth, @salary, @gender, ISNULL(@hire_date, GETDATE()));
        
        PRINT CONCAT('✓ Instructor ', @instructor_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectInstructor', 'P') IS NOT NULL DROP PROCEDURE sp_SelectInstructor;
GO
CREATE PROCEDURE sp_SelectInstructor
    @instructor_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @instructor_id IS NULL
        SELECT * FROM INSTRUCTOR ORDER BY instructor_name;
    ELSE
        SELECT * FROM INSTRUCTOR WHERE instructor_id = @instructor_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateInstructor', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateInstructor;
GO
CREATE PROCEDURE sp_UpdateInstructor
    @instructor_id NVARCHAR(20),
    @instructor_name NVARCHAR(100) = NULL,
    @date_of_birth DATE = NULL,
    @salary DECIMAL(10, 2) = NULL,
    @gender NCHAR(1) = NULL,
    @hire_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE INSTRUCTOR
        SET 
            instructor_name = ISNULL(@instructor_name, instructor_name),
            date_of_birth = ISNULL(@date_of_birth, date_of_birth),
            salary = ISNULL(@salary, salary),
            gender = ISNULL(@gender, gender),
            hire_date = ISNULL(@hire_date, hire_date)
        WHERE instructor_id = @instructor_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Instructor ', @instructor_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Instructor ', @instructor_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteInstructor', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteInstructor;
GO
CREATE PROCEDURE sp_DeleteInstructor
    @instructor_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM INSTRUCTOR WHERE instructor_id = @instructor_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Instructor ', @instructor_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Instructor ', @instructor_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ INSTRUCTOR procedures created (4/72)';
GO

-- ================================================================
-- TABLE 2: INTAKE
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertIntake', 'P') IS NOT NULL DROP PROCEDURE sp_InsertIntake;
GO
CREATE PROCEDURE sp_InsertIntake
    @intake_number NVARCHAR(20),
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO INTAKE (intake_number, start_date, end_date)
        VALUES (@intake_number, @start_date, @end_date);
        
        PRINT CONCAT('✓ Intake ', @intake_number, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectIntake', 'P') IS NOT NULL DROP PROCEDURE sp_SelectIntake;
GO
CREATE PROCEDURE sp_SelectIntake
    @intake_number NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @intake_number IS NULL
        SELECT * FROM INTAKE ORDER BY start_date DESC;
    ELSE
        SELECT * FROM INTAKE WHERE intake_number = @intake_number;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateIntake', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateIntake;
GO
CREATE PROCEDURE sp_UpdateIntake
    @intake_number NVARCHAR(20),
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE INTAKE
        SET 
            start_date = ISNULL(@start_date, start_date),
            end_date = ISNULL(@end_date, end_date)
        WHERE intake_number = @intake_number;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Intake ', @intake_number, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Intake ', @intake_number, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteIntake', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteIntake;
GO
CREATE PROCEDURE sp_DeleteIntake
    @intake_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM INTAKE WHERE intake_number = @intake_number;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Intake ', @intake_number, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Intake ', @intake_number, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ INTAKE procedures created (8/72)';
GO

-- ================================================================
-- TABLE 3: DEPARTMENT
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertDepartment', 'P') IS NOT NULL DROP PROCEDURE sp_InsertDepartment;
GO
CREATE PROCEDURE sp_InsertDepartment
    @dept_id NVARCHAR(20),
    @dept_name NVARCHAR(100),
    @description NVARCHAR(500) = NULL,
    @dept_manager_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO DEPARTMENT (dept_id, dept_name, description, dept_manager_id)
        VALUES (@dept_id, @dept_name, @description, @dept_manager_id);
        
        PRINT CONCAT('✓ Department ', @dept_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectDepartment', 'P') IS NOT NULL DROP PROCEDURE sp_SelectDepartment;
GO
CREATE PROCEDURE sp_SelectDepartment
    @dept_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @dept_id IS NULL
        SELECT d.*, i.instructor_name as manager_name 
        FROM DEPARTMENT d
        JOIN INSTRUCTOR i ON d.dept_manager_id = i.instructor_id
        ORDER BY d.dept_name;
    ELSE
        SELECT d.*, i.instructor_name as manager_name 
        FROM DEPARTMENT d
        JOIN INSTRUCTOR i ON d.dept_manager_id = i.instructor_id
        WHERE d.dept_id = @dept_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateDepartment', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateDepartment;
GO
CREATE PROCEDURE sp_UpdateDepartment
    @dept_id NVARCHAR(20),
    @dept_name NVARCHAR(100) = NULL,
    @description NVARCHAR(500) = NULL,
    @dept_manager_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE DEPARTMENT
        SET 
            dept_name = ISNULL(@dept_name, dept_name),
            description = ISNULL(@description, description),
            dept_manager_id = ISNULL(@dept_manager_id, dept_manager_id)
        WHERE dept_id = @dept_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Department ', @dept_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Department ', @dept_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteDepartment', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteDepartment;
GO
CREATE PROCEDURE sp_DeleteDepartment
    @dept_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM DEPARTMENT WHERE dept_id = @dept_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Department ', @dept_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Department ', @dept_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ DEPARTMENT procedures created (12/72)';
GO

-- ================================================================
-- TABLE 4: TRACK
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertTrack', 'P') IS NOT NULL DROP PROCEDURE sp_InsertTrack;
GO
CREATE PROCEDURE sp_InsertTrack
    @track_id NVARCHAR(20),
    @track_name NVARCHAR(100),
    @track_manager_id NVARCHAR(20),
    @dept_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO TRACK (track_id, track_name, track_manager_id, dept_id)
        VALUES (@track_id, @track_name, @track_manager_id, @dept_id);
        
        PRINT CONCAT('✓ Track ', @track_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectTrack', 'P') IS NOT NULL DROP PROCEDURE sp_SelectTrack;
GO
CREATE PROCEDURE sp_SelectTrack
    @track_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @track_id IS NULL
        SELECT t.*, i.instructor_name as manager_name, d.dept_name
        FROM TRACK t
        JOIN INSTRUCTOR i ON t.track_manager_id = i.instructor_id
        JOIN DEPARTMENT d ON t.dept_id = d.dept_id
        ORDER BY t.track_name;
    ELSE
        SELECT t.*, i.instructor_name as manager_name, d.dept_name
        FROM TRACK t
        JOIN INSTRUCTOR i ON t.track_manager_id = i.instructor_id
        JOIN DEPARTMENT d ON t.dept_id = d.dept_id
        WHERE t.track_id = @track_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateTrack', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateTrack;
GO
CREATE PROCEDURE sp_UpdateTrack
    @track_id NVARCHAR(20),
    @track_name NVARCHAR(100) = NULL,
    @track_manager_id NVARCHAR(20) = NULL,
    @dept_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE TRACK
        SET 
            track_name = ISNULL(@track_name, track_name),
            track_manager_id = ISNULL(@track_manager_id, track_manager_id),
            dept_id = ISNULL(@dept_id, dept_id)
        WHERE track_id = @track_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Track ', @track_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Track ', @track_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteTrack', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteTrack;
GO
CREATE PROCEDURE sp_DeleteTrack
    @track_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM TRACK WHERE track_id = @track_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Track ', @track_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Track ', @track_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ TRACK procedures created (16/72)';
GO

-- ================================================================
-- TABLE 5: TRACK_INTAKE
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertTrackIntake', 'P') IS NOT NULL DROP PROCEDURE sp_InsertTrackIntake;
GO
CREATE PROCEDURE sp_InsertTrackIntake
    @track_id NVARCHAR(20),
    @intake_number NVARCHAR(20),
    @start_date DATE,
    @end_date DATE = NULL,
    @capacity INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO TRACK_INTAKE (track_id, intake_number, start_date, end_date, capacity)
        VALUES (@track_id, @intake_number, @start_date, @end_date, @capacity);
        
        PRINT '✓ Track-Intake relationship inserted successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectTrackIntake', 'P') IS NOT NULL DROP PROCEDURE sp_SelectTrackIntake;
GO
CREATE PROCEDURE sp_SelectTrackIntake
    @track_id NVARCHAR(20) = NULL,
    @intake_number NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @track_id IS NULL AND @intake_number IS NULL
        SELECT ti.*, t.track_name, i.start_date as intake_start, i.end_date as intake_end
        FROM TRACK_INTAKE ti
        JOIN TRACK t ON ti.track_id = t.track_id
        JOIN INTAKE i ON ti.intake_number = i.intake_number
        ORDER BY ti.start_date DESC;
    ELSE IF @track_id IS NOT NULL AND @intake_number IS NULL
        SELECT ti.*, t.track_name, i.start_date as intake_start, i.end_date as intake_end
        FROM TRACK_INTAKE ti
        JOIN TRACK t ON ti.track_id = t.track_id
        JOIN INTAKE i ON ti.intake_number = i.intake_number
        WHERE ti.track_id = @track_id
        ORDER BY ti.start_date DESC;
    ELSE IF @track_id IS NULL AND @intake_number IS NOT NULL
        SELECT ti.*, t.track_name, i.start_date as intake_start, i.end_date as intake_end
        FROM TRACK_INTAKE ti
        JOIN TRACK t ON ti.track_id = t.track_id
        JOIN INTAKE i ON ti.intake_number = i.intake_number
        WHERE ti.intake_number = @intake_number
        ORDER BY t.track_name;
    ELSE
        SELECT ti.*, t.track_name, i.start_date as intake_start, i.end_date as intake_end
        FROM TRACK_INTAKE ti
        JOIN TRACK t ON ti.track_id = t.track_id
        JOIN INTAKE i ON ti.intake_number = i.intake_number
        WHERE ti.track_id = @track_id AND ti.intake_number = @intake_number;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateTrackIntake', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateTrackIntake;
GO
CREATE PROCEDURE sp_UpdateTrackIntake
    @track_id NVARCHAR(20),
    @intake_number NVARCHAR(20),
    @start_date DATE = NULL,
    @end_date DATE = NULL,
    @capacity INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE TRACK_INTAKE
        SET 
            start_date = ISNULL(@start_date, start_date),
            end_date = ISNULL(@end_date, end_date),
            capacity = ISNULL(@capacity, capacity)
        WHERE track_id = @track_id AND intake_number = @intake_number;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Track-Intake relationship updated successfully';
        ELSE
            PRINT '✗ Track-Intake relationship not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteTrackIntake', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteTrackIntake;
GO
CREATE PROCEDURE sp_DeleteTrackIntake
    @track_id NVARCHAR(20),
    @intake_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM TRACK_INTAKE 
        WHERE track_id = @track_id AND intake_number = @intake_number;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Track-Intake relationship deleted successfully';
        ELSE
            PRINT '✗ Track-Intake relationship not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ TRACK_INTAKE procedures created (20/72)';
GO

-- ================================================================
-- TABLE 6: INSTRUCTOR_TRACK
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertInstructorTrack', 'P') IS NOT NULL DROP PROCEDURE sp_InsertInstructorTrack;
GO
CREATE PROCEDURE sp_InsertInstructorTrack
    @instructor_id NVARCHAR(20),
    @track_id NVARCHAR(20),
    @assignment_date DATE = NULL,
    @role NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO INSTRUCTOR_TRACK (instructor_id, track_id, assignment_date, role)
        VALUES (@instructor_id, @track_id, ISNULL(@assignment_date, GETDATE()), @role);
        
        PRINT '✓ Instructor-Track assignment inserted successfully';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectInstructorTrack', 'P') IS NOT NULL DROP PROCEDURE sp_SelectInstructorTrack;
GO
CREATE PROCEDURE sp_SelectInstructorTrack
    @instructor_id NVARCHAR(20) = NULL,
    @track_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT it.*, i.instructor_name, t.track_name
    FROM INSTRUCTOR_TRACK it
    JOIN INSTRUCTOR i ON it.instructor_id = i.instructor_id
    JOIN TRACK t ON it.track_id = t.track_id
    WHERE (@instructor_id IS NULL OR it.instructor_id = @instructor_id)
      AND (@track_id IS NULL OR it.track_id = @track_id)
    ORDER BY it.assignment_date DESC;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateInstructorTrack', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateInstructorTrack;
GO
CREATE PROCEDURE sp_UpdateInstructorTrack
    @instructor_id NVARCHAR(20),
    @track_id NVARCHAR(20),
    @assignment_date DATE = NULL,
    @role NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE INSTRUCTOR_TRACK
        SET 
            assignment_date = ISNULL(@assignment_date, assignment_date),
            role = ISNULL(@role, role)
        WHERE instructor_id = @instructor_id AND track_id = @track_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Instructor-Track assignment updated successfully';
        ELSE
            PRINT '✗ Instructor-Track assignment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteInstructorTrack', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteInstructorTrack;
GO
CREATE PROCEDURE sp_DeleteInstructorTrack
    @instructor_id NVARCHAR(20),
    @track_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM INSTRUCTOR_TRACK 
        WHERE instructor_id = @instructor_id AND track_id = @track_id;
        
        IF @@ROWCOUNT > 0
            PRINT '✓ Instructor-Track assignment deleted successfully';
        ELSE
            PRINT '✗ Instructor-Track assignment not found';
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ INSTRUCTOR_TRACK procedures created (24/72)';
GO

-- ================================================================
-- TABLE 7: STUDENT
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertStudent', 'P') IS NOT NULL DROP PROCEDURE sp_InsertStudent;
GO
CREATE PROCEDURE sp_InsertStudent
    @stud_id INT,
    @login NVARCHAR(50),
    @password NVARCHAR(255),
    @track_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO STUDENT (stud_id, login, password, track_id)
        VALUES (@stud_id, @login, @password, @track_id);
        
        PRINT CONCAT('✓ Student ', @stud_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectStudent', 'P') IS NOT NULL DROP PROCEDURE sp_SelectStudent;
GO
CREATE PROCEDURE sp_SelectStudent
    @stud_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @stud_id IS NULL
        SELECT s.*, t.track_name
        FROM STUDENT s
        JOIN TRACK t ON s.track_id = t.track_id
        ORDER BY s.stud_id;
    ELSE
        SELECT s.*, t.track_name
        FROM STUDENT s
        JOIN TRACK t ON s.track_id = t.track_id
        WHERE s.stud_id = @stud_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateStudent', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateStudent;
GO
CREATE PROCEDURE sp_UpdateStudent
    @stud_id INT,
    @login NVARCHAR(50) = NULL,
    @password NVARCHAR(255) = NULL,
    @track_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE STUDENT
        SET 
            login = ISNULL(@login, login),
            password = ISNULL(@password, password),
            track_id = ISNULL(@track_id, track_id)
        WHERE stud_id = @stud_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Student ', @stud_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Student ', @stud_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteStudent', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteStudent;
GO
CREATE PROCEDURE sp_DeleteStudent
    @stud_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM STUDENT WHERE stud_id = @stud_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Student ', @stud_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Student ', @stud_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ STUDENT procedures created (28/72)';
GO

-- ================================================================
-- TABLE 8: STUDENT_INFO
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertStudentInfo', 'P') IS NOT NULL DROP PROCEDURE sp_InsertStudentInfo;
GO
CREATE PROCEDURE sp_InsertStudentInfo
    @stud_id INT,
    @f_name NVARCHAR(50),
    @mid_name NVARCHAR(50) = NULL,
    @last_name NVARCHAR(50),
    @gender NCHAR(1),
    @faculty NVARCHAR(100) = NULL,
    @phone NVARCHAR(15) = NULL,
    @FB_email NVARCHAR(100) = NULL,
    @city NVARCHAR(50) = NULL,
    @street NVARCHAR(100) = NULL,
    @date_of_birth DATE,
    @zip_code NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO STUDENT_INFO (stud_id, f_name, mid_name, last_name, gender, faculty, 
                                  phone, FB_email, city, street, date_of_birth, zip_code)
        VALUES (@stud_id, @f_name, @mid_name, @last_name, @gender, @faculty,
                @phone, @FB_email, @city, @street, @date_of_birth, @zip_code);
        
        PRINT CONCAT('✓ Student Info for ', @stud_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectStudentInfo', 'P') IS NOT NULL DROP PROCEDURE sp_SelectStudentInfo;
GO
CREATE PROCEDURE sp_SelectStudentInfo
    @stud_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @stud_id IS NULL
        SELECT * FROM STUDENT_INFO ORDER BY f_name, last_name;
    ELSE
        SELECT * FROM STUDENT_INFO WHERE stud_id = @stud_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateStudentInfo', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateStudentInfo;
GO
CREATE PROCEDURE sp_UpdateStudentInfo
    @stud_id INT,
    @f_name NVARCHAR(50) = NULL,
    @mid_name NVARCHAR(50) = NULL,
    @last_name NVARCHAR(50) = NULL,
    @gender NCHAR(1) = NULL,
    @faculty NVARCHAR(100) = NULL,
    @phone NVARCHAR(15) = NULL,
    @FB_email NVARCHAR(100) = NULL,
    @city NVARCHAR(50) = NULL,
    @street NVARCHAR(100) = NULL,
    @date_of_birth DATE = NULL,
    @zip_code NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE STUDENT_INFO
        SET 
            f_name = ISNULL(@f_name, f_name),
            mid_name = ISNULL(@mid_name, mid_name),
            last_name = ISNULL(@last_name, last_name),
            gender = ISNULL(@gender, gender),
            faculty = ISNULL(@faculty, faculty),
            phone = ISNULL(@phone, phone),
            FB_email = ISNULL(@FB_email, FB_email),
            city = ISNULL(@city, city),
            street = ISNULL(@street, street),
            date_of_birth = ISNULL(@date_of_birth, date_of_birth),
            zip_code = ISNULL(@zip_code, zip_code)
        WHERE stud_id = @stud_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Student Info for ', @stud_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Student Info for ', @stud_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteStudentInfo', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteStudentInfo;
GO
CREATE PROCEDURE sp_DeleteStudentInfo
    @stud_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM STUDENT_INFO WHERE stud_id = @stud_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Student Info for ', @stud_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Student Info for ', @stud_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ STUDENT_INFO procedures created (32/72)';
GO

-- ================================================================
-- TABLE 9: COURSE
-- ================================================================

-- INSERT
IF OBJECT_ID('sp_InsertCourse', 'P') IS NOT NULL DROP PROCEDURE sp_InsertCourse;
GO
CREATE PROCEDURE sp_InsertCourse
    @course_id NVARCHAR(20),
    @course_name NVARCHAR(150),
    @credit_hour INT,
    @category NVARCHAR(50) = NULL,
    @introduce_by NVARCHAR(20) = NULL,
    @track_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO COURSE (course_id, course_name, credit_hour, category, introduce_by, track_id)
        VALUES (@course_id, @course_name, @credit_hour, @category, @introduce_by, @track_id);
        
        PRINT CONCAT('✓ Course ', @course_id, ' inserted successfully');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SELECT
IF OBJECT_ID('sp_SelectCourse', 'P') IS NOT NULL DROP PROCEDURE sp_SelectCourse;
GO
CREATE PROCEDURE sp_SelectCourse
    @course_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @course_id IS NULL
        SELECT c.*, t.track_name, i.instructor_name as introduced_by_name
        FROM COURSE c
        JOIN TRACK t ON c.track_id = t.track_id
        LEFT JOIN INSTRUCTOR i ON c.introduce_by = i.instructor_id
        ORDER BY c.course_name;
    ELSE
        SELECT c.*, t.track_name, i.instructor_name as introduced_by_name
        FROM COURSE c
        JOIN TRACK t ON c.track_id = t.track_id
        LEFT JOIN INSTRUCTOR i ON c.introduce_by = i.instructor_id
        WHERE c.course_id = @course_id;
END
GO

-- UPDATE
IF OBJECT_ID('sp_UpdateCourse', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateCourse;
GO
CREATE PROCEDURE sp_UpdateCourse
    @course_id NVARCHAR(20),
    @course_name NVARCHAR(150) = NULL,
    @credit_hour INT = NULL,
    @category NVARCHAR(50) = NULL,
    @introduce_by NVARCHAR(20) = NULL,
    @track_id NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE COURSE
        SET 
            course_name = ISNULL(@course_name, course_name),
            credit_hour = ISNULL(@credit_hour, credit_hour),
            category = ISNULL(@category, category),
            introduce_by = ISNULL(@introduce_by, introduce_by),
            track_id = ISNULL(@track_id, track_id)
        WHERE course_id = @course_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Course ', @course_id, ' updated successfully');
        ELSE
            PRINT CONCAT('✗ Course ', @course_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- DELETE
IF OBJECT_ID('sp_DeleteCourse', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteCourse;
GO
CREATE PROCEDURE sp_DeleteCourse
    @course_id NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM COURSE WHERE course_id = @course_id;
        
        IF @@ROWCOUNT > 0
            PRINT CONCAT('✓ Course ', @course_id, ' deleted successfully');
        ELSE
            PRINT CONCAT('✗ Course ', @course_id, ' not found');
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ COURSE procedures created (36/72)';
GO

-- ================================================================
-- Continue with remaining tables (10-18)...
-- Due to length, creating a second file
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'Part 1 Complete: 9/18 tables (36/72 procedures)';
PRINT 'Continue with Part 2...';
PRINT '========================================';
GO