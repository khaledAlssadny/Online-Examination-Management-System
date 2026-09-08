

-- ================================================================
-- ITI EXAMINATION SYSTEM - COMPLETE DATABASE SCRIPT
-- ================================================================
/*
USE master;
GO

ALTER DATABASE ITI_EXAMINATION
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE ITI_EXAMINATION;
GO
*/
-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ITI_EXAMINATION')
BEGIN
    CREATE DATABASE ITI_EXAMINATION;
END
GO

USE ITI_EXAMINATION;
GO

-- ================================================================
-- STEP 1: CREATE INDEPENDENT TABLES (No Foreign Keys)
-- ================================================================

-- 1. INSTRUCTOR (Independent - no FK dependencies)
CREATE TABLE INSTRUCTOR (
    instructor_id NVARCHAR(20) PRIMARY KEY,
    instructor_name NVARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    gender NCHAR(1) NOT NULL,
    hire_date DATE NOT NULL DEFAULT GETDATE(),
    
    -- Check Constraints
    CONSTRAINT CHK_INSTRUCTOR_GENDER 
        CHECK (gender IN ('M', 'F')),
    CONSTRAINT CHK_INSTRUCTOR_DOB 
        CHECK (date_of_birth < GETDATE()),
    CONSTRAINT CHK_INSTRUCTOR_AGE 
        CHECK (DATEDIFF(YEAR, date_of_birth, GETDATE()) >= 21),
    CONSTRAINT CHK_INSTRUCTOR_SALARY 
        CHECK (salary >= 0)
);
GO

-- Add computed column for age
ALTER TABLE INSTRUCTOR 
ADD age AS DATEDIFF(YEAR, date_of_birth, GETDATE());
GO

-- 2. INTAKE (Independent - no FK dependencies)
CREATE TABLE INTAKE (
    intake_number NVARCHAR(20) PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Check Constraints
    CONSTRAINT CHK_INTAKE_DATES 
        CHECK (end_date > start_date),
    CONSTRAINT CHK_INTAKE_START 
        CHECK (start_date >= '2000-01-01')
);
GO

-- ================================================================
-- STEP 2: CREATE TABLES WITH INSTRUCTOR FK
-- ================================================================

-- 3. DEPARTMENT (Depends on INSTRUCTOR)
CREATE TABLE DEPARTMENT (
    dept_id NVARCHAR(20) PRIMARY KEY,
    dept_name NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(500) NULL,
    dept_manager_id NVARCHAR(20) NOT NULL,
    
    -- Foreign Key
    CONSTRAINT FK_DEPARTMENT_MANAGER 
        FOREIGN KEY (dept_manager_id) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- 4. TRACK (Depends on DEPARTMENT and INSTRUCTOR)
CREATE TABLE TRACK (
    track_id NVARCHAR(20) PRIMARY KEY,
    track_name NVARCHAR(100) NOT NULL UNIQUE,
    track_manager_id NVARCHAR(20) NOT NULL,
    dept_id NVARCHAR(20) NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT FK_TRACK_MANAGER 
        FOREIGN KEY (track_manager_id) 
        REFERENCES INSTRUCTOR(instructor_id),
       
    
    CONSTRAINT FK_TRACK_DEPARTMENT 
        FOREIGN KEY (dept_id) 
        REFERENCES DEPARTMENT(dept_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- ================================================================
-- STEP 3: CREATE ASSOCIATIVE TABLES
-- ================================================================

-- 5. TRACK_INTAKE (Associative)
CREATE TABLE TRACK_INTAKE (
    track_id NVARCHAR(20) NOT NULL,
    intake_number NVARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    capacity INT NULL,
    
    -- Composite Primary Key
    CONSTRAINT PK_TRACK_INTAKE 
        PRIMARY KEY (track_id, intake_number),
    
    -- Foreign Keys
    CONSTRAINT FK_TRACK_INTAKE_TRACK 
        FOREIGN KEY (track_id) 
        REFERENCES TRACK(track_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_TRACK_INTAKE_INTAKE 
        FOREIGN KEY (intake_number) 
        REFERENCES INTAKE(intake_number)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_TRACK_INTAKE_DATES 
        CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT CHK_TRACK_INTAKE_CAPACITY 
        CHECK (capacity IS NULL OR capacity > 0)
);
GO

-- 6. INSTRUCTOR_TRACK (Associative)
CREATE TABLE INSTRUCTOR_TRACK (
    instructor_id NVARCHAR(20) NOT NULL,
    track_id NVARCHAR(20) NOT NULL,
    assignment_date DATE NOT NULL DEFAULT GETDATE(),
    role NVARCHAR(50) NULL,
    
    -- Composite Primary Key
    CONSTRAINT PK_INSTRUCTOR_TRACK 
        PRIMARY KEY (instructor_id, track_id),
    
    -- Foreign Keys
    CONSTRAINT FK_INSTRUCTOR_TRACK_INSTRUCTOR 
        FOREIGN KEY (instructor_id) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE CASCADE,
        
    
    CONSTRAINT FK_INSTRUCTOR_TRACK_TRACK 
        FOREIGN KEY (track_id) 
        REFERENCES TRACK(track_id)
        ON DELETE CASCADE
   
);
GO

-- ================================================================
-- STEP 4: CREATE STUDENT TABLES
-- ================================================================

-- 7. STUDENT (Depends on TRACK)
CREATE TABLE STUDENT (
    stud_id INT PRIMARY KEY,
    login NVARCHAR(50) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    track_id NVARCHAR(20) NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT FK_STUDENT_TRACK 
        FOREIGN KEY (track_id) 
        REFERENCES TRACK(track_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_STUDENT_LOGIN 
        CHECK (LEN(login) >= 3),
    CONSTRAINT CHK_STUDENT_PASSWORD 
        CHECK (LEN(password) >= 8)
);
GO

-- 8. STUDENT_INFO (Depends on STUDENT - 1:1)
CREATE TABLE STUDENT_INFO (
    stud_id INT PRIMARY KEY,
    f_name NVARCHAR(50) NOT NULL,
    mid_name NVARCHAR(50) NULL,
    last_name NVARCHAR(50) NOT NULL,
    gender NCHAR(1) NOT NULL,
    faculty NVARCHAR(100) NULL,
    phone NVARCHAR(15) NULL UNIQUE,
    FB_email NVARCHAR(100) NULL UNIQUE,
    city NVARCHAR(50) NULL,
    street NVARCHAR(100) NULL,
    date_of_birth DATE NOT NULL,
    zip_code NVARCHAR(10) NULL,
    
    -- Foreign Key (1:1 relationship)
    CONSTRAINT FK_STUDENT_INFO_STUDENT 
        FOREIGN KEY (stud_id) 
        REFERENCES STUDENT(stud_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_STUDENT_INFO_GENDER 
        CHECK (gender IN ('M', 'F')),
    CONSTRAINT CHK_STUDENT_INFO_DOB 
        CHECK (date_of_birth < GETDATE()),
    CONSTRAINT CHK_STUDENT_INFO_AGE 
        CHECK (DATEDIFF(YEAR, date_of_birth, GETDATE()) >= 16)
);
GO

-- Add computed column for age
ALTER TABLE STUDENT_INFO 
ADD age AS DATEDIFF(YEAR, date_of_birth, GETDATE());
GO

-- ================================================================
-- STEP 5: CREATE COURSE TABLES
-- ================================================================

-- 9. COURSE (Depends on TRACK and INSTRUCTOR)
--CASCADE PROBLEMS
CREATE TABLE COURSE (
    course_id NVARCHAR(20) PRIMARY KEY,
    course_name NVARCHAR(150) NOT NULL,
    credit_hour INT NOT NULL,
    category NVARCHAR(50) NULL,
    introduce_by NVARCHAR(20) NULL,
    track_id NVARCHAR(20) NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT FK_COURSE_TRACK 
        FOREIGN KEY (track_id) 
        REFERENCES TRACK(track_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_COURSE_INTRODUCER 
        FOREIGN KEY (introduce_by) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT CHK_COURSE_CREDIT_HOUR 
        CHECK (credit_hour > 0 AND credit_hour <= 6),
    
    -- Unique constraint
    CONSTRAINT UQ_COURSE_NAME_TRACK 
        UNIQUE (course_name, track_id)
);
GO

-- 10. STUDENT_COURSE (Associative)
--CASCADE PROBLEMS
CREATE TABLE STUDENT_COURSE (
    student_id INT NOT NULL,
    course_id NVARCHAR(20) NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT GETDATE(),
    completion_date DATE NULL,
    grade NVARCHAR(5) NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'enrolled',
    
    -- Composite Primary Key
    CONSTRAINT PK_STUDENT_COURSE 
        PRIMARY KEY (student_id, course_id),
    
    -- Foreign Keys
    CONSTRAINT FK_STUDENT_COURSE_STUDENT 
        FOREIGN KEY (student_id) 
        REFERENCES STUDENT(stud_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_STUDENT_COURSE_COURSE 
        FOREIGN KEY (course_id) 
        REFERENCES COURSE(course_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT CHK_STUDENT_COURSE_STATUS 
        CHECK (status IN ('enrolled', 'completed', 'withdrawn', 'failed')),
    CONSTRAINT CHK_STUDENT_COURSE_DATES 
        CHECK (completion_date IS NULL OR completion_date >= enrollment_date),
    CONSTRAINT CHK_STUDENT_COURSE_GRADE 
        CHECK (grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F') OR grade IS NULL)
);
GO

-- 11. INSTRUCTOR_COURSE (Associative)
CREATE TABLE INSTRUCTOR_COURSE (
    instructor_id NVARCHAR(20) NOT NULL,
    course_id NVARCHAR(20) NOT NULL,
    course_date DATE NOT NULL,
    for_year INT NOT NULL,
    
    -- Composite Primary Key
    CONSTRAINT PK_INSTRUCTOR_COURSE 
        PRIMARY KEY (instructor_id, course_id, course_date),
    
    -- Foreign Keys
    CONSTRAINT FK_INSTRUCTOR_COURSE_INSTRUCTOR 
        FOREIGN KEY (instructor_id) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    CONSTRAINT FK_INSTRUCTOR_COURSE_COURSE 
        FOREIGN KEY (course_id) 
        REFERENCES COURSE(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_INSTRUCTOR_COURSE_YEAR 
        CHECK (for_year >= 2000 AND for_year <= 2100)
);
GO

-- 12. TOPIC (Depends on COURSE)
CREATE TABLE TOPIC (
    topic_id NVARCHAR(20) PRIMARY KEY,
    course_id NVARCHAR(20) NOT NULL,
    topic_name NVARCHAR(150) NOT NULL,
    topic_description NVARCHAR(MAX) NULL,
    topic_order INT NOT NULL,
    
    -- Foreign Key
    CONSTRAINT FK_TOPIC_COURSE 
        FOREIGN KEY (course_id) 
        REFERENCES COURSE(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_TOPIC_ORDER 
        CHECK (topic_order > 0),
    
    -- Unique constraint
    CONSTRAINT UQ_TOPIC_ORDER_COURSE 
        UNIQUE (course_id, topic_order)
);
GO

-- ================================================================
-- STEP 6: CREATE QUESTION AND EXAM TABLES
-- ================================================================

-- 13. QUESTION (Depends on COURSE and INSTRUCTOR)
-- CASCADE PROBLEMS
CREATE TABLE QUESTION (
    question_id INT PRIMARY KEY IDENTITY(1,1),
    course_id NVARCHAR(20) NOT NULL,
    created_by_inst_id NVARCHAR(20) NOT NULL,
    question_content NVARCHAR(MAX) NOT NULL,
    question_type NVARCHAR(20) NOT NULL,
    marks INT NOT NULL,
    difficulty_level NVARCHAR(20) NULL,
    created_date DATE NOT NULL DEFAULT GETDATE(),
    
    -- Foreign Keys
    CONSTRAINT FK_QUESTION_COURSE 
        FOREIGN KEY (course_id) 
        REFERENCES COURSE(course_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    CONSTRAINT FK_QUESTION_INSTRUCTOR 
        FOREIGN KEY (created_by_inst_id) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    
    -- Check Constraints
    CONSTRAINT CHK_QUESTION_TYPE 
        CHECK (question_type IN ('MCQ', 'TrueFalse')),
    CONSTRAINT CHK_QUESTION_MARKS 
        CHECK (marks > 0),
    CONSTRAINT CHK_QUESTION_DIFFICULTY 
        CHECK (difficulty_level IN ('Easy', 'Medium', 'Hard') OR difficulty_level IS NULL)
);
GO

-- 14. CHOICES (Depends on QUESTION)
CREATE TABLE CHOICES (
    choice_id NVARCHAR(20) PRIMARY KEY,
    question_id INT NOT NULL,
    choice_content NVARCHAR(500) NOT NULL,
    is_correct BIT NOT NULL DEFAULT 0,
    choice_order NCHAR(1) NULL,
    
    -- Foreign Key
    CONSTRAINT FK_CHOICES_QUESTION 
        FOREIGN KEY (question_id) 
        REFERENCES QUESTION(question_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Unique constraint
    CONSTRAINT UQ_CHOICES_ORDER 
        UNIQUE (question_id, choice_order)
);
GO

-- 15. EXAM (Depends on COURSE and INSTRUCTOR)
CREATE TABLE EXAM (
    exam_id NVARCHAR(20) PRIMARY KEY,
    course_id NVARCHAR(20) NOT NULL,
    created_by_inst_id NVARCHAR(20) NOT NULL,
    exam_title NVARCHAR(200) NOT NULL,
    total_marks INT NOT NULL,
    passing_score INT NOT NULL,
    duration_minutes INT NOT NULL,
    created_date DATE NOT NULL DEFAULT GETDATE(),
    total_result INT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'draft',
    
    -- Foreign Keys
    CONSTRAINT FK_EXAM_COURSE 
        FOREIGN KEY (course_id) 
        REFERENCES COURSE(course_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_EXAM_INSTRUCTOR 
        FOREIGN KEY (created_by_inst_id) 
        REFERENCES INSTRUCTOR(instructor_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT CHK_EXAM_TOTAL_MARKS 
        CHECK (total_marks > 0),
    CONSTRAINT CHK_EXAM_PASSING_SCORE 
        CHECK (passing_score > 0 AND passing_score <= total_marks),
    CONSTRAINT CHK_EXAM_DURATION 
        CHECK (duration_minutes > 0),
    CONSTRAINT CHK_EXAM_STATUS 
        CHECK (status IN ('draft', 'active', 'completed', 'archived'))
);
GO

-- ================================================================
-- STEP 8: CREATE TRIGGERS
-- ================================================================

-- Trigger 1: Ensure at least 2 choices per question
CREATE TRIGGER trg_question_min_choices
ON CHOICES
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT question_id 
        FROM QUESTION q
        WHERE (SELECT COUNT(*) FROM CHOICES WHERE question_id = q.question_id) < 2
    )
    BEGIN
        RAISERROR('Each question must have at least 2 choices', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger 2: Ensure exactly one correct choice per question
CREATE TRIGGER trg_question_one_correct
ON CHOICES
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT question_id 
        FROM CHOICES
        GROUP BY question_id
        HAVING SUM(CAST(is_correct AS INT)) <> 1
    )
    BEGIN
        RAISERROR('Each question must have exactly one correct choice', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Trigger 3: Validate choice belongs to question
CREATE TRIGGER trg_validate_answer_choice
ON STUDENT_ANSWER
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN EXAM_QUES eq ON i.exam_question_id = eq.exam_question_id
        JOIN CHOICES c ON i.selected_choice_id = c.choice_id
        WHERE c.question_id <> eq.question_id
    )
    BEGIN
        RAISERROR('Selected choice must belong to the question being answered', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ================================================================
-- SCRIPT COMPLETED SUCCESSFULLY
-- ================================================================

PRINT '========================================';
PRINT 'ITI EXAMINATION DATABASE CREATED SUCCESSFULLY';
PRINT '========================================';
PRINT 'Total Tables Created: 18';
PRINT 'Total Triggers Created: 3';
PRINT '========================================';
GO
-- ================================================================
-- ITI EXAMINATION SYSTEM - DATA INSERTION SCRIPT
-- ================================================================
/*
USE master;
GO

ALTER DATABASE ITI_EXAMINATION
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE ITI_EXAMINATION;
GO
*/
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ITI_EXAMINATION')
BEGIN
    CREATE DATABASE ITI_EXAMINATION;
END
GO
USE ITI_EXAMINATION;
GO

PRINT 'Starting Data Insertion...';
GO

-- ================================================================
-- INSTRUCTORS
-- ================================================================
INSERT INTO INSTRUCTOR (instructor_id, instructor_name, date_of_birth, salary, gender, hire_date) VALUES
    ('INST001', 'Ahmed Mohamed Hassan', '1985-03-15', 12000.00, 'M', '2015-09-01'),
    ('INST002', 'Fatma Ali Ibrahim', '1987-07-22', 11500.00, 'F', '2016-02-15'),
    ('INST003', 'Mohamed Sherif Mahmoud', '1983-11-10', 13500.00, 'M', '2014-08-20'),
    ('INST004', 'Nour Khaled Ahmed', '1989-05-18', 10500.00, 'F', '2017-03-10'),
    ('INST005', 'Omar Hassan Ali', '1984-09-25', 12500.00, 'M', '2015-11-01'),
    ('INST006', 'Heba Mostafa Said', '1988-12-30', 11000.00, 'F', '2016-09-15'),
    ('INST007', 'Khaled Ibrahim Farid', '1982-04-12', 14000.00, 'M', '2013-06-01'),
    ('INST008', 'Dina Yasser Mohamed', '1990-08-05', 10000.00, 'F', '2018-01-20'),
    ('INST009', 'Amr Samir Hassan', '1986-01-20', 11800.00, 'M', '2016-05-10'),
    ('INST010', 'Laila Ahmed Kamel', '1985-06-14', 12200.00, 'F', '2015-10-15'),
    ('INST011', 'Tarek Mahmoud Zaki', '1981-10-08', 14500.00, 'M', '2012-09-01'),
    ('INST012', 'Rania Essam Nabil', '1991-03-28', 9500.00, 'F', '2019-02-01'),
    ('INST013', 'Youssef Ahmed Taha', '1984-07-16', 13000.00, 'M', '2014-12-10'),
    ('INST014', 'Mariam Hassan Fouad', '1989-11-22', 10800.00, 'F', '2017-08-15'),
    ('INST015', 'Hesham Said Abdelrahman', '1983-02-19', 13200.00, 'M', '2014-03-20');


PRINT 'Instructors inserted: 15';
GO

-- ================================================================
-- INTAKES
-- ================================================================
INSERT INTO INTAKE (intake_number, start_date, end_date) VALUES
    ('INT2023-01', '2023-01-15', '2023-06-30'),
    ('INT2023-02', '2023-07-01', '2023-12-31'),
    ('INT2024-01', '2024-01-15', '2024-06-30'),
    ('INT2024-02', '2024-07-01', '2024-12-31'),
    ('INT2025-01', '2025-01-15', '2025-06-30');

PRINT 'Intakes inserted: 5';
GO

-- ================================================================
-- DEPARTMENTS
-- ================================================================
INSERT INTO DEPARTMENT (dept_id, dept_name, description, dept_manager_id) VALUES
    ('DEPT001', 'Software Development', 'Responsible for all software development tracks', 'INST003'),
    ('DEPT002', 'Data Science & AI', 'Covers data analytics and machine learning', 'INST007'),
    ('DEPT003', 'Infrastructure & Cloud', 'Manages cloud and DevOps programs', 'INST011');

PRINT 'Departments inserted: 3';
GO

-- ================================================================
-- TRACKS
-- ================================================================
INSERT INTO TRACK (track_id, track_name, track_manager_id, dept_id) VALUES
    ('TRK001', 'Full Stack .NET Development', 'INST001', 'DEPT001'),
    ('TRK002', 'MEAN Stack Development', 'INST002', 'DEPT001'),
    ('TRK003', 'Mobile Application Development', 'INST005', 'DEPT001'),
    ('TRK004', 'Data Science & Machine Learning', 'INST009', 'DEPT002'),
    ('TRK005', 'Artificial Intelligence', 'INST013', 'DEPT002'),
    ('TRK006', 'Cloud Computing & DevOps', 'INST015', 'DEPT003');

PRINT 'Tracks inserted: 6';
GO

-- ================================================================
-- TRACK_INTAKE
-- ================================================================
INSERT INTO TRACK_INTAKE (track_id, intake_number, start_date, end_date, capacity) VALUES
    ('TRK001', 'INT2023-01', '2023-01-15', '2023-06-30', 25),
    ('TRK002', 'INT2023-01', '2023-01-15', '2023-06-30', 20),
    ('TRK004', 'INT2023-01', '2023-01-15', '2023-06-30', 15),
    ('TRK001', 'INT2024-01', '2024-01-15', '2024-06-30', 30),
    ('TRK002', 'INT2024-01', '2024-01-15', '2024-06-30', 25),
    ('TRK003', 'INT2024-01', '2024-01-15', '2024-06-30', 25),
    ('TRK004', 'INT2024-01', '2024-01-15', '2024-06-30', 20),
    ('TRK005', 'INT2024-01', '2024-01-15', '2024-06-30', 20),
    ('TRK006', 'INT2024-01', '2024-01-15', '2024-06-30', 20),
    ('TRK001', 'INT2025-01', '2025-01-15', NULL, 35),
    ('TRK002', 'INT2025-01', '2025-01-15', NULL, 30),
    ('TRK003', 'INT2025-01', '2025-01-15', NULL, 25),
    ('TRK004', 'INT2025-01', '2025-01-15', NULL, 20),
    ('TRK005', 'INT2025-01', '2025-01-15', NULL, 20),
    ('TRK006', 'INT2025-01', '2025-01-15', NULL, 25);

PRINT 'Track-Intake relationships inserted: 15';
GO

-- ================================================================
-- INSTRUCTOR_TRACK
-- ================================================================
INSERT INTO INSTRUCTOR_TRACK (instructor_id, track_id, assignment_date, role) VALUES
    ('INST001', 'TRK001', '2015-09-01', 'Track Manager'),
    ('INST002', 'TRK002', '2016-02-15', 'Track Manager'),
    ('INST003', 'TRK001', '2014-08-20', 'Senior Instructor'),
    ('INST004', 'TRK002', '2017-03-10', 'Instructor'),
    ('INST005', 'TRK003', '2015-11-01', 'Track Manager'),
    ('INST006', 'TRK003', '2016-09-15', 'Instructor'),
    ('INST007', 'TRK004', '2013-06-01', 'Senior Instructor'),
    ('INST008', 'TRK001', '2018-01-20', 'Instructor'),
    ('INST009', 'TRK004', '2016-05-10', 'Track Manager'),
    ('INST010', 'TRK002', '2015-10-15', 'Senior Instructor'),
    ('INST011', 'TRK006', '2012-09-01', 'Senior Instructor'),
    ('INST012', 'TRK005', '2019-02-01', 'Instructor'),
    ('INST013', 'TRK005', '2014-12-10', 'Track Manager'),
    ('INST014', 'TRK004', '2017-08-15', 'Instructor'),
    ('INST015', 'TRK006', '2014-03-20', 'Track Manager');

PRINT 'Instructor-Track assignments inserted: 15';
GO

-- ================================================================
-- STUDENTS (60 students across 6 tracks)
-- ================================================================
INSERT INTO STUDENT (stud_id, login, password, track_id) VALUES
    -- TRK001 (15 students)
    (1001, 'ahmed.mohamed', 'Pass@2023', 'TRK001'),(1002, 'fatma.hassan', 'Secure123', 'TRK001'),
    (1003, 'mohamed.ali', 'Student@01', 'TRK001'),(1004, 'nour.khaled', 'MyPass456', 'TRK001'),
    (1005, 'omar.said', 'Login@789', 'TRK001'),(1006, 'heba.ahmed', 'Pass2024!', 'TRK001'),
    (1007, 'khaled.yasser', 'Stud@2023', 'TRK001'),(1008, 'dina.ibrahim', 'Secure@99', 'TRK001'),
    (1009, 'amr.hassan', 'MyLogin22', 'TRK001'),(1010, 'laila.mohamed', 'Pass@word1', 'TRK001'),
    (1011, 'tarek.ali', 'Student123', 'TRK001'),(1012, 'rania.said', 'Login2024', 'TRK001'),
    (1013, 'youssef.omar', 'Secure@45', 'TRK001'),(1014, 'mariam.khaled', 'Pass@ITI1', 'TRK001'),
    (1015, 'hesham.ahmed', 'MyPass@88', 'TRK001'),
    -- TRK002 (10 students)
    (2001, 'sara.mohamed', 'Mean@2023', 'TRK002'),(2002, 'adam.hassan', 'Stack@123', 'TRK002'),
    (2003, 'noha.ali', 'NodeJS@01', 'TRK002'),(2004, 'basel.khaled', 'Angular99', 'TRK002'),
    (2005, 'mona.said', 'Express@7', 'TRK002'),(2006, 'karim.ahmed', 'Mongo@456', 'TRK002'),
    (2007, 'aya.yasser', 'Stack2024', 'TRK002'),(2008, 'sherif.ibrahim', 'Mean@Pass', 'TRK002'),
    (2009, 'nadine.hassan', 'Angular@2', 'TRK002'),(2010, 'tamer.mohamed', 'Node@2023', 'TRK002'),
    -- TRK003 (10 students)
    (3001, 'ali.mohamed', 'Mobile@23', 'TRK003'),(3002, 'salma.hassan', 'Flutter@1', 'TRK003'),
    (3003, 'mahmoud.ali', 'Android99', 'TRK003'),(3004, 'yasmin.khaled', 'iOS@Pass1', 'TRK003'),
    (3005, 'adel.said', 'React@Nat', 'TRK003'),(3006, 'nada.ahmed', 'Mobile@45', 'TRK003'),
    (3007, 'mostafa.yasser', 'Flutter22', 'TRK003'),(3008, 'rana.ibrahim', 'Android@7', 'TRK003'),
    (3009, 'eslam.hassan', 'iOS@2024', 'TRK003'),(3010, 'hana.mohamed', 'ReactNat1', 'TRK003'),
    -- TRK004 (10 students)
    (4001, 'ziad.mohamed', 'DataSci@1', 'TRK004'),(4002, 'rana.hassan', 'Python@23', 'TRK004'),
    (4003, 'samy.ali', 'ML@Pass01', 'TRK004'),(4004, 'nada.khaled', 'Pandas@99', 'TRK004'),
    (4005, 'hazem.said', 'NumPy@456', 'TRK004'),(4006, 'menna.ahmed', 'DataSci2', 'TRK004'),
    (4007, 'waleed.yasser', 'Python@24', 'TRK004'),(4008, 'nagla.ibrahim', 'ML@Secure', 'TRK004'),
    (4009, 'ibrahim.hassan', 'Tensor@01', 'TRK004'),(4010, 'ghada.mohamed', 'Scikit@23', 'TRK004'),
    -- TRK005 (8 students)
    (5001, 'kamal.mohamed', 'AI@Pass23', 'TRK005'),(5002, 'dalia.hassan', 'DeepL@123', 'TRK005'),
    (5003, 'ashraf.ali', 'Neural@01', 'TRK005'),(5004, 'soha.khaled', 'AI@Model1', 'TRK005'),
    (5005, 'emad.said', 'TensorF@7', 'TRK005'),(5006, 'eman.ahmed', 'AI@2024!!', 'TRK005'),
    (5007, 'fady.yasser', 'DeepNet9', 'TRK005'),(5008, 'hend.ibrahim', 'AI@Secure', 'TRK005'),
    -- TRK006 (7 students)
    (6001, 'gamal.mohamed', 'Cloud@123', 'TRK006'),(6002, 'iman.hassan', 'AWS@Pass1', 'TRK006'),
    (6003, 'sameh.ali', 'Azure@234', 'TRK006'),(6004, 'wafaa.khaled', 'Docker@99', 'TRK006'),
    (6005, 'medhat.said', 'K8s@Pass7', 'TRK006'),(6006, 'nihad.ahmed', 'DevOps@24', 'TRK006'),
    (6007, 'saad.yasser', 'Cloud2024', 'TRK006');

PRINT 'Students inserted: 60';
GO

-- ================================================================
-- STUDENT_INFO (Sample of 20 students for brevity - expand as needed)
-- ================================================================
INSERT INTO STUDENT_INFO (stud_id, f_name, mid_name, last_name, gender, faculty, phone, FB_email, city, street, date_of_birth, zip_code) VALUES
    (1001, 'Ahmed', 'Mohamed', 'Hassan', 'M', 'Engineering', '01012345678', 'ahmed.m@example.com', 'Cairo', '15 Tahrir St', '2000-05-15', '11511'),
    (1002, 'Fatma', 'Ali', 'Hassan', 'F', 'Computer Science', '01123456789', 'fatma.h@example.com', 'Giza', '22 Pyramids Rd', '2001-08-22', '12311'),
    (1003, 'Mohamed', 'Khaled', 'Ali', 'M', 'Engineering', '01234567890', 'mohamed.a@example.com', 'Alexandria', '8 Corniche St', '1999-12-10', '21500'),
    (2001, 'Sara', 'Ali', 'Mohamed', 'F', 'Computer Science', '01067890123', 'sara.m@example.com', 'Cairo', '31 Abbasia', '2001-04-11', '11517'),
    (2002, 'Adam', 'Yasser', 'Hassan', 'M', 'Engineering', '01178901234', 'adam.h@example.com', 'Giza', '18 Agouza', '2000-09-17', '12654'),
    (3001, 'Ali', 'Hassan', 'Mohamed', 'M', 'Engineering', '01167890123', 'ali.m@example.com', 'Cairo', '8 Zamalek', '2001-02-26', '11211'),
    (3002, 'Salma', 'Ahmed', 'Hassan', 'F', 'Computer Science', '01278901234', 'salma.h@example.com', 'Giza', '35 Haram', '2000-07-12', '12556'),
    (4001, 'Ziad', 'Ibrahim', 'Mohamed', 'M', 'Engineering', '01267890124', 'ziad.m@example.com', 'Cairo', '4 Nasr City', '2000-06-13', '11765'),
    (4002, 'Rana', 'Said', 'Hassan', 'F', 'Science', '01078901235', 'rana.h@example.com', 'Alexandria', '26 Sporting', '2001-09-28', '21500'),
    (5001, 'Kamal', 'Yasser', 'Mohamed', 'M', 'Engineering', '01067890124', 'kamal.m@example.com', 'Cairo', '3 Zamalek', '2001-01-08', '11211'),
    (5002, 'Dalia', 'Ali', 'Hassan', 'F', 'Computer Science', '01178901235', 'dalia.h@example.com', 'Giza', '14 Mohandessin', '2000-09-21', '12411'),
    (6001, 'Gamal', 'Hassan', 'Mohamed', 'M', 'Engineering', '01245678902', 'gamal.m@example.com', 'Cairo', '10 Maadi', '2000-12-03', '11728'),
    (6002, 'Iman', 'Ali', 'Hassan', 'F', 'Computer Science', '01056789013', 'iman.h@example.com', 'Giza', '23 Sheikh Zayed', '2001-06-18', '12588'),
    (1004, 'Nour', 'Ahmed', 'Khaled', 'F', 'Computer Science', '01045678901', 'nour.k@example.com', 'Cairo', '45 Nasr City', '2002-03-18', '11765'),
    (1005, 'Omar', 'Said', 'Mahmoud', 'M', 'Engineering', '01156789012', 'omar.s@example.com', 'Cairo', '12 Heliopolis', '2000-09-25', '11361'),
    (2003, 'Noha', 'Khaled', 'Ali', 'F', 'Computer Science', '01289012345', 'noha.a@example.com', 'Cairo', '25 Garden City', '2002-01-23', '11451'),
    (2004, 'Basel', 'Ahmed', 'Khaled', 'M', 'Engineering', '01090123456', 'basel.k@example.com', 'Alexandria', '11 Sidi Gaber', '1999-11-05', '21523'),
    (3003, 'Mahmoud', 'Said', 'Ali', 'M', 'Engineering', '01089012345', 'mahmoud.a@example.com', 'Alexandria', '22 Mandara', '1999-09-18', '21599'),
    (4003, 'Samy', 'Mohamed', 'Ali', 'M', 'Engineering', '01189012346', 'samy.a@example.com', 'Cairo', '32 Madinaty', '1999-11-14', '11865'),
    (5003, 'Ashraf', 'Hassan', 'Ali', 'M', 'Engineering', '01289012346', 'ashraf.a@example.com', 'Alexandria', '17 Montazah', '1999-05-29', '21500');

PRINT 'Student Information inserted: 20 (Add remaining 40 as needed)';
GO

-- ================================================================
-- COURSES
-- ================================================================
INSERT INTO COURSE (course_id, course_name, credit_hour, category, introduce_by, track_id) VALUES
    -- TRK001 Courses
    ('CRS001', 'C# Programming Fundamentals', 4, 'Programming', 'INST001', 'TRK001'),
    ('CRS002', 'ASP.NET Core MVC', 5, 'Web Development', 'INST001', 'TRK001'),
    ('CRS003', 'Entity Framework Core', 4, 'Database', 'INST003', 'TRK001'),
    ('CRS004', 'SQL Server Advanced', 3, 'Database', 'INST003', 'TRK001'),
    ('CRS005', 'Web API Development', 4, 'Web Development', 'INST008', 'TRK001'),
    -- TRK002 Courses
    ('CRS006', 'JavaScript ES6+', 4, 'Programming', 'INST002', 'TRK002'),
    ('CRS007', 'Node.js Backend Development', 5, 'Backend', 'INST002', 'TRK002'),
    ('CRS008', 'MongoDB Database', 3, 'Database', 'INST004', 'TRK002'),
    ('CRS009', 'Angular Framework', 5, 'Frontend', 'INST010', 'TRK002'),
    ('CRS010', 'Express.js API Development', 4, 'Backend', 'INST002', 'TRK002'),
    -- TRK003 Courses
    ('CRS011', 'Java for Android', 4, 'Programming', 'INST005', 'TRK003'),
    ('CRS012', 'Android App Development', 5, 'Mobile', 'INST005', 'TRK003'),
    ('CRS013', 'iOS Swift Programming', 4, 'Programming', 'INST006', 'TRK003'),
    ('CRS014', 'Flutter Cross-Platform', 5, 'Mobile', 'INST006', 'TRK003'),
    ('CRS015', 'React Native', 4, 'Mobile', 'INST005', 'TRK003'),
    -- TRK004 Courses
    ('CRS016', 'Python for Data Science', 4, 'Programming', 'INST009', 'TRK004'),
    ('CRS017', 'Data Analysis with Pandas', 4, 'Data Analysis', 'INST009', 'TRK004'),
    ('CRS018', 'Machine Learning Basics', 5, 'AI/ML', 'INST007', 'TRK004'),
    ('CRS019', 'Data Visualization', 3, 'Data Analysis', 'INST014', 'TRK004'),
    ('CRS020', 'Statistical Analysis', 4, 'Statistics', 'INST007', 'TRK004'),
    -- TRK005 Courses
    ('CRS021', 'Deep Learning Fundamentals', 5, 'AI/ML', 'INST013', 'TRK005'),
    ('CRS022', 'Neural Networks', 5, 'AI/ML', 'INST013', 'TRK005'),
    ('CRS023', 'Computer Vision', 4, 'AI/ML', 'INST012', 'TRK005'),
    ('CRS024', 'Natural Language Processing', 4, 'AI/ML', 'INST012', 'TRK005'),
    -- TRK006 Courses
    ('CRS025', 'AWS Cloud Fundamentals', 4, 'Cloud', 'INST015', 'TRK006'),
    ('CRS026', 'Docker Containerization', 3, 'DevOps', 'INST015', 'TRK006'),
    ('CRS027', 'Kubernetes Orchestration', 4, 'DevOps', 'INST011', 'TRK006'),
    ('CRS028', 'CI/CD Pipelines', 3, 'DevOps', 'INST011', 'TRK006'),
    ('CRS029', 'Azure Cloud Services', 4, 'Cloud', 'INST015', 'TRK006');

PRINT 'Courses inserted: 29';
GO

-- ================================================================
-- STUDENT_COURSE ENROLLMENTS (Sample)
-- ================================================================
INSERT INTO STUDENT_COURSE (student_id, course_id, enrollment_date, completion_date, grade, status) VALUES
    (1001, 'CRS001', '2023-01-20', '2023-04-15', 'A', 'completed'),
    (1001, 'CRS002', '2023-05-01', '2023-08-20', 'B+', 'completed'),
    (1001, 'CRS003', '2023-09-01', NULL, NULL, 'enrolled'),
    (1002, 'CRS001', '2023-01-20', '2023-04-15', 'B', 'completed'),
    (1002, 'CRS002', '2023-05-01', '2023-08-20', 'B-', 'completed'),
    (1003, 'CRS001', '2023-01-20', '2023-04-15', 'A-', 'completed'),
    (1003, 'CRS002', '2023-05-01', '2023-08-20', 'A', 'completed'),
    (1003, 'CRS003', '2023-09-01', '2024-01-15', 'B+', 'completed'),
    (2001, 'CRS006', '2023-01-25', '2023-04-20', 'A', 'completed'),
    (2001, 'CRS007', '2023-05-05', '2023-08-25', 'A-', 'completed'),
    (2002, 'CRS006', '2023-01-25', '2023-04-20', 'B+', 'completed'),
    (3001, 'CRS011', '2023-07-10', '2023-10-15', 'A-', 'completed'),
    (3001, 'CRS012', '2023-11-01', NULL, NULL, 'enrolled'),
    (4001, 'CRS016', '2023-01-30', '2023-04-25', 'A', 'completed'),
    (4001, 'CRS017', '2023-05-10', '2023-08-28', 'A', 'completed'),
    (5001, 'CRS021', '2024-01-30', NULL, NULL, 'enrolled'),
    (6001, 'CRS025', '2023-07-15', '2023-10-20', 'A', 'completed');

PRINT 'Student-Course enrollments inserted: 17';
GO

-- ================================================================
-- INSTRUCTOR_COURSE ASSIGNMENTS (Sample)
-- ================================================================
INSERT INTO INSTRUCTOR_COURSE (instructor_id, course_id, course_date, for_year) VALUES
    ('INST001', 'CRS001', '2023-01-20', 2023),
    ('INST001', 'CRS002', '2023-05-01', 2023),
    ('INST001', 'CRS001', '2024-01-20', 2024),
    ('INST003', 'CRS003', '2023-09-01', 2023),
    ('INST003', 'CRS004', '2023-09-01', 2023),
    ('INST002', 'CRS006', '2023-01-25', 2023),
    ('INST002', 'CRS007', '2023-05-05', 2023),
    ('INST005', 'CRS011', '2023-07-10', 2023),
    ('INST005', 'CRS012', '2023-11-01', 2023),
    ('INST009', 'CRS016', '2023-01-30', 2023),
    ('INST009', 'CRS017', '2023-05-10', 2023),
    ('INST007', 'CRS018', '2023-09-10', 2023),
    ('INST013', 'CRS021', '2024-01-30', 2024),
    ('INST013', 'CRS022', '2024-01-30', 2024),
    ('INST015', 'CRS025', '2023-07-15', 2023),
    ('INST015', 'CRS026', '2023-11-05', 2023),
    ('INST011', 'CRS027', '2024-01-25', 2024);

PRINT 'Instructor-Course assignments inserted: 17';
GO

-- ================================================================
-- TOPICS (Sample topics for main courses)
-- ================================================================
INSERT INTO TOPIC (topic_id, course_id, topic_name, topic_description, topic_order) VALUES
    ('TOP001', 'CRS001', 'Introduction to C#', 'Overview of C# language', 1),
    ('TOP002', 'CRS001', 'Variables and Data Types', 'Working with primitive types', 2),
    ('TOP003', 'CRS001', 'Control Flow', 'If-else, loops in C#', 3),
    ('TOP004', 'CRS001', 'OOP Concepts', 'Classes, inheritance, polymorphism', 4),
    ('TOP005', 'CRS002', 'MVC Architecture', 'Model-View-Controller pattern', 1),
    ('TOP006', 'CRS002', 'Routing', 'URL routing configuration', 2),
    ('TOP007', 'CRS002', 'Controllers', 'Action methods', 3),
    ('TOP008', 'CRS006', 'ES6 Syntax', 'Let, const, arrow functions', 1),
    ('TOP009', 'CRS006', 'Promises', 'Asynchronous programming', 2),
    ('TOP010', 'CRS016', 'Python Basics', 'Syntax and data structures', 1);

PRINT 'Topics inserted: 10';
GO

-- ================================================================
-- QUESTIONS (Sample questions - 20 questions)
-- ================================================================
SET IDENTITY_INSERT QUESTION ON;

INSERT INTO QUESTION (question_id, course_id, created_by_inst_id, question_content, question_type, marks, difficulty_level, created_date) VALUES
    (1, 'CRS001', 'INST001', 'What is the correct way to declare a variable in C#?', 'MCQ', 2, 'Easy', '2023-01-10'),
    (2, 'CRS001', 'INST001', 'C# is a case-sensitive language.', 'TrueFalse', 1, 'Easy', '2023-01-10'),
    (3, 'CRS001', 'INST001', 'Which keyword is used for inheritance in C#?', 'MCQ', 2, 'Medium', '2023-01-10'),
    (4, 'CRS002', 'INST001', 'What does MVC stand for?', 'MCQ', 2, 'Easy', '2023-04-25'),
    (5, 'CRS002', 'INST001', 'In MVC, the View is responsible for business logic.', 'TrueFalse', 1, 'Easy', '2023-04-25'),
    (6, 'CRS003', 'INST003', 'What is Entity Framework?', 'MCQ', 2, 'Easy', '2023-08-25'),
    (7, 'CRS003', 'INST003', 'Entity Framework is an ORM framework.', 'TrueFalse', 1, 'Easy', '2023-08-25'),
    (8, 'CRS006', 'INST002', 'What is the correct way to declare a constant in ES6?', 'MCQ', 2, 'Easy', '2023-01-15'),
    (9, 'CRS006', 'INST002', 'Arrow functions have their own "this" context.', 'TrueFalse', 1, 'Medium', '2023-01-15'),
    (10, 'CRS007', 'INST002', 'What is Node.js?', 'MCQ', 2, 'Easy', '2023-04-30'),
    (11, 'CRS007', 'INST002', 'Node.js is single-threaded.', 'TrueFalse', 1, 'Medium', '2023-04-30'),
    (12, 'CRS011', 'INST005', 'What is an Activity in Android?', 'MCQ', 2, 'Easy', '2023-07-05'),
    (13, 'CRS011', 'INST005', 'Android apps are written only in Java.', 'TrueFalse', 1, 'Easy', '2023-07-05'),
    (14, 'CRS016', 'INST009', 'Which library is used for numerical computing in Python?', 'MCQ', 2, 'Easy', '2023-01-25'),
    (15, 'CRS016', 'INST009', 'Python is a compiled language.', 'TrueFalse', 1, 'Easy', '2023-01-25'),
    (16, 'CRS018', 'INST007', 'What is supervised learning?', 'MCQ', 3, 'Medium', '2023-09-05'),
    (17, 'CRS018', 'INST007', 'Decision trees can be used for both classification and regression.', 'TrueFalse', 1, 'Medium', '2023-09-05'),
    (18, 'CRS021', 'INST013', 'What is a neural network?', 'MCQ', 3, 'Medium', '2024-01-25'),
    (19, 'CRS021', 'INST013', 'Deep learning requires large amounts of data.', 'TrueFalse', 1, 'Easy', '2024-01-25'),
    (20, 'CRS025', 'INST015', 'What does EC2 stand for?', 'MCQ', 2, 'Easy', '2023-07-10');

SET IDENTITY_INSERT QUESTION OFF;

PRINT 'Questions inserted: 20';
GO

-- ================================================================
-- CHOICES (4 choices per MCQ, 2 per TrueFalse)
-- ================================================================
INSERT INTO CHOICES (choice_id, question_id, choice_content, is_correct, choice_order) VALUES
    -- Q1: Variable declaration
    ('CH001', 1, 'int x = 5;', 1, 'A'),('CH002', 1, 'var x = 5', 0, 'B'),
    ('CH003', 1, 'integer x = 5;', 0, 'C'),('CH004', 1, 'x = 5;', 0, 'D'),
    -- Q2: Case sensitive
    ('CH005', 2, 'True', 1, 'A'),('CH006', 2, 'False', 0, 'B'),
    -- Q3: Inheritance keyword
    ('CH007', 3, 'extends', 0, 'A'),('CH008', 3, 'inherits', 0, 'B'),
    ('CH009', 3, ':', 1, 'C'),('CH010', 3, 'implements', 0, 'D'),
    -- Q4: MVC
    ('CH011', 4, 'Model View Controller', 1, 'A'),('CH012', 4, 'Main View Component', 0, 'B'),
    ('CH013', 4, 'Multiple View Control', 0, 'C'),('CH014', 4, 'Managed Virtual Component', 0, 'D'),
    -- Q5: View responsibility
    ('CH015', 5, 'True', 0, 'A'),('CH016', 5, 'False', 1, 'B'),
    -- Q6: Entity Framework
    ('CH017', 6, 'A JavaScript framework', 0, 'A'),('CH018', 6, 'An ORM framework', 1, 'B'),
    ('CH019', 6, 'A CSS framework', 0, 'C'),('CH020', 6, 'A testing framework', 0, 'D'),
    -- Q7: ORM
    ('CH021', 7, 'True', 1, 'A'),('CH022', 7, 'False', 0, 'B'),
    -- Q8: ES6 const
    ('CH023', 8, 'const x = 5;', 1, 'A'),('CH024', 8, 'constant x = 5;', 0, 'B'),
    ('CH025', 8, 'let x = 5;', 0, 'C'),('CH026', 8, 'var x = 5;', 0, 'D'),
    -- Q9: Arrow functions
    ('CH027', 9, 'True', 0, 'A'),('CH028', 9, 'False', 1, 'B'),
    -- Q10: Node.js
    ('CH029', 10, 'A database', 0, 'A'),('CH030', 10, 'A JavaScript runtime', 1, 'B'),
    ('CH031', 10, 'A framework', 0, 'C'),('CH032', 10, 'A library', 0, 'D'),
    -- Q11: Single-threaded
    ('CH033', 11, 'True', 1, 'A'),('CH034', 11, 'False', 0, 'B'),
    -- Q12: Activity
    ('CH035', 12, 'A background service', 0, 'A'),('CH036', 12, 'A single screen with UI', 1, 'B'),
    ('CH037', 12, 'A database table', 0, 'C'),('CH038', 12, 'A network request', 0, 'D'),
    -- Q13: Android Java only
    ('CH039', 13, 'True', 0, 'A'),('CH040', 13, 'False', 1, 'B'),
    -- Q14: NumPy
    ('CH041', 14, 'Pandas', 0, 'A'),('CH042', 14, 'NumPy', 1, 'B'),
    ('CH043', 14, 'Matplotlib', 0, 'C'),('CH044', 14, 'SciPy', 0, 'D'),
    -- Q15: Python compiled
    ('CH045', 15, 'True', 0, 'A'),('CH046', 15, 'False', 1, 'B'),
    -- Q16: Supervised learning
    ('CH047', 16, 'Learning without labels', 0, 'A'),('CH048', 16, 'Learning with labeled data', 1, 'B'),
    ('CH049', 16, 'Reinforcement learning', 0, 'C'),('CH050', 16, 'Unsupervised learning', 0, 'D'),
    -- Q17: Decision trees
    ('CH051', 17, 'True', 1, 'A'),('CH052', 17, 'False', 0, 'B'),
    -- Q18: Neural network
    ('CH053', 18, 'A type of database', 0, 'A'),('CH054', 18, 'A computing system inspired by biological neural networks', 1, 'B'),
    ('CH055', 18, 'A networking protocol', 0, 'C'),('CH056', 18, 'A programming language', 0, 'D'),
    -- Q19: Deep learning data
    ('CH057', 19, 'True', 1, 'A'),('CH058', 19, 'False', 0, 'B'),
    -- Q20: EC2
    ('CH059', 20, 'Elastic Compute Cloud', 1, 'A'),('CH060', 20, 'Enhanced Cloud Computing', 0, 'B'),
    ('CH061', 20, 'Enterprise Cloud Cluster', 0, 'C'),('CH062', 20, 'Elastic Container Cloud', 0, 'D');

PRINT 'Choices inserted: 62';
GO

-- ================================================================
-- EXAMS (Sample exams for courses)
-- ================================================================
INSERT INTO EXAM (exam_id, course_id, created_by_inst_id, exam_title, total_marks, passing_score, duration_minutes, created_date, total_result, status) VALUES
    ('EX001', 'CRS001', 'INST001', 'C# Fundamentals - Midterm', 20, 12, 60, '2023-02-15', NULL, 'completed'),
    ('EX002', 'CRS001', 'INST001', 'C# Fundamentals - Final', 30, 18, 90, '2023-04-10', NULL, 'completed'),
    ('EX003', 'CRS002', 'INST001', 'ASP.NET MVC - Midterm', 25, 15, 75, '2023-06-20', NULL, 'completed'),
    ('EX004', 'CRS003', 'INST003', 'Entity Framework - Quiz', 15, 9, 45, '2023-10-05', NULL, 'completed'),
    ('EX005', 'CRS006', 'INST002', 'JavaScript ES6 - Midterm', 20, 12, 60, '2023-03-10', NULL, 'completed'),
    ('EX006', 'CRS007', 'INST002', 'Node.js - Final', 30, 18, 90, '2023-08-20', NULL, 'completed'),
    ('EX007', 'CRS011', 'INST005', 'Android Basics - Quiz', 15, 9, 45, '2023-08-15', NULL, 'completed'),
    ('EX008', 'CRS016', 'INST009', 'Python Data Science - Midterm', 20, 12, 60, '2023-03-15', NULL, 'completed'),
    ('EX009', 'CRS018', 'INST007', 'Machine Learning - Final', 30, 18, 90, '2023-12-15', NULL, 'active'),
    ('EX010', 'CRS025', 'INST015', 'AWS Cloud - Final', 25, 15, 75, '2023-10-15', NULL, 'completed');

PRINT 'Exams inserted: 10';
GO




-- ================================================================
-- DROP EXISTING TABLES (if redesigning)
-- ================================================================
/*
IF OBJECT_ID('STUDENT_ANSWER', 'U') IS NOT NULL DROP TABLE STUDENT_ANSWER;
IF OBJECT_ID('EXAM_SUBMIT', 'U') IS NOT NULL DROP TABLE EXAM_SUBMIT;
IF OBJECT_ID('EXAM_QUES', 'U') IS NOT NULL DROP TABLE EXAM_QUES;
*/

-- ================================================================
-- STEP 1: CREATE IMPROVED TABLES
-- ================================================================

-- 16. EXAM_QUES - With meaningful composite keys
PRINT 'Creating EXAM_QUES table...';
CREATE TABLE EXAM_QUES (
    exam_question_id NVARCHAR(50) PRIMARY KEY,  -- Format: "EX001-Q001"
    exam_id NVARCHAR(20) NOT NULL,
    question_id INT NOT NULL,
    question_order INT NOT NULL,
    marks_allocated INT NOT NULL,
    
    -- Foreign Keys with proper CASCADE
    CONSTRAINT FK_EXAM_QUES_EXAM 
        FOREIGN KEY (exam_id) 
        REFERENCES EXAM(exam_id)
        ON DELETE CASCADE      -- Exam deleted = question config deleted
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_EXAM_QUES_QUESTION 
        FOREIGN KEY (question_id) 
        REFERENCES QUESTION(question_id)
        ON DELETE NO ACTION      -- Allow question deletion to cascade
        ON UPDATE NO ACTION  ,
    
    -- Check Constraints
    CONSTRAINT CHK_EXAM_QUES_ORDER 
        CHECK (question_order > 0),
    CONSTRAINT CHK_EXAM_QUES_MARKS 
        CHECK (marks_allocated > 0),
    
    -- Unique Constraints
    CONSTRAINT UQ_EXAM_QUES_ORDER 
        UNIQUE (exam_id, question_order),
    CONSTRAINT UQ_EXAM_QUES_QUESTION 
        UNIQUE (exam_id, question_id)
);
GO

-- 17. EXAM_SUBMIT - With student-based meaningful keys
PRINT 'Creating EXAM_SUBMIT table...';
CREATE TABLE EXAM_SUBMIT (
    stud_submit_id NVARCHAR(50) PRIMARY KEY,  -- Format: "SUB1001-EX001-A1"
    student_id INT NOT NULL,
    exam_id NVARCHAR(20) NOT NULL,
    start_time DATETIME NOT NULL DEFAULT GETDATE(),
    submit_time DATETIME NULL,
    submit_date DATE NULL,
    total_score DECIMAL(5, 2) NULL,
    attempt_number INT NOT NULL DEFAULT 1,
    status NVARCHAR(20) NOT NULL DEFAULT 'in_progress',
    
    -- Foreign Keys with proper CASCADE
    CONSTRAINT FK_EXAM_SUBMIT_STUDENT 
        FOREIGN KEY (student_id) 
        REFERENCES STUDENT(stud_id)
        ON DELETE CASCADE      -- Student deleted = submissions deleted
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_EXAM_SUBMIT_EXAM 
        FOREIGN KEY (exam_id) 
        REFERENCES EXAM(exam_id)
        ON DELETE NO ACTION    -- PRESERVE HISTORY! Don't delete submissions if exam deleted
        ON UPDATE NO ACTION ,
    
    -- Check Constraints
    CONSTRAINT CHK_EXAM_SUBMIT_TIMES 
        CHECK (submit_time IS NULL OR submit_time >= start_time),
    CONSTRAINT CHK_EXAM_SUBMIT_ATTEMPT 
        CHECK (attempt_number > 0),
    CONSTRAINT CHK_EXAM_SUBMIT_STATUS 
        CHECK (status IN ('in_progress', 'submitted', 'graded')),
    CONSTRAINT CHK_EXAM_SUBMIT_SCORE 
        CHECK (total_score IS NULL OR total_score >= 0),
    
    -- Unique constraint
    CONSTRAINT UQ_EXAM_SUBMIT_ATTEMPT 
        UNIQUE (student_id, exam_id, attempt_number)
);
GO

-- 18. STUDENT_ANSWER - With submission-based meaningful keys
PRINT 'Creating STUDENT_ANSWER table...';
CREATE TABLE STUDENT_ANSWER (
    answer_id NVARCHAR(50) PRIMARY KEY,  -- Format: "SUB1001-EX001-A1-Q001"
    student_exam_id NVARCHAR(50) NOT NULL,
    exam_question_id NVARCHAR(50) NOT NULL,
    selected_choice_id NVARCHAR(20) NOT NULL,
    is_correct BIT NULL,
    marks_earned DECIMAL(5, 2) NULL,
    answered_at DATETIME NOT NULL DEFAULT GETDATE(),
    
    -- Foreign Keys with proper CASCADE
    CONSTRAINT FK_STUDENT_ANSWER_SUBMIT 
        FOREIGN KEY (student_exam_id) 
        REFERENCES EXAM_SUBMIT(stud_submit_id)
        ON DELETE CASCADE      -- Submission deleted = answers deleted
        ON UPDATE CASCADE,
    
    CONSTRAINT FK_STUDENT_ANSWER_EXAM_QUES 
        FOREIGN KEY (exam_question_id) 
        REFERENCES EXAM_QUES(exam_question_id)
        ON DELETE NO ACTION      -- Exam config deleted = answers can be deleted
        ON UPDATE NO ACTION,
    
    CONSTRAINT FK_STUDENT_ANSWER_CHOICE 
        FOREIGN KEY (selected_choice_id) 
        REFERENCES CHOICES(choice_id)
        ON DELETE NO ACTION    -- Preserve answer even if choice text changes
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT CHK_STUDENT_ANSWER_MARKS 
        CHECK (marks_earned IS NULL OR marks_earned >= 0),
    
    -- Unique constraint
    CONSTRAINT UQ_STUDENT_ANSWER 
        UNIQUE (student_exam_id, exam_question_id)
);
GO

-- ================================================================
-- STEP 2: CREATE AUTO-GENERATION TRIGGERS
-- ================================================================

PRINT 'Creating auto-generation triggers...';
GO

-- Trigger for EXAM_QUES: Auto-generate exam_question_id
CREATE TRIGGER trg_EXAM_QUES_AutoID
ON EXAM_QUES
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO EXAM_QUES (exam_question_id, exam_id, question_id, question_order, marks_allocated)
    SELECT 
        CONCAT(exam_id, '-Q', FORMAT(question_order, '000')) as exam_question_id,
        exam_id,
        question_id,
        question_order,
        marks_allocated
    FROM inserted;
END;
GO

-- Trigger for EXAM_SUBMIT: Auto-generate stud_submit_id
CREATE TRIGGER trg_EXAM_SUBMIT_AutoID
ON EXAM_SUBMIT
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO EXAM_SUBMIT (stud_submit_id, student_id, exam_id, start_time, submit_time, 
                             submit_date, total_score, attempt_number, status)
    SELECT 
        CONCAT('SUB', student_id, '-', exam_id, '-A', attempt_number) as stud_submit_id,
        student_id,
        exam_id,
        start_time,
        submit_time,
        submit_date,
        total_score,
        attempt_number,
        status
    FROM inserted;
END;
GO

-- Trigger for STUDENT_ANSWER: Auto-generate answer_id
CREATE TRIGGER trg_STUDENT_ANSWER_AutoID
ON STUDENT_ANSWER
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO STUDENT_ANSWER (answer_id, student_exam_id, exam_question_id, 
                                selected_choice_id, is_correct, marks_earned, answered_at)
    SELECT 
        CONCAT(student_exam_id, '-', RIGHT(exam_question_id, 4)) as answer_id,
        student_exam_id,
        exam_question_id,
        selected_choice_id,
        is_correct,
        marks_earned,
        answered_at
    FROM inserted;
END;
GO

PRINT 'Triggers created successfully!';
GO

-- ================================================================
-- STEP 3: INSERT SAMPLE DATA
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'Starting Data Insertion...';
PRINT '========================================';
GO

-- ================================================================
-- INSERT EXAM_QUES (Auto-generated keys: EX001-Q001, EX001-Q002, etc.)
-- ================================================================
PRINT 'Inserting EXAM_QUES...';
--SELECT *  FROM EXAM_QUES
--DELETE FROM EXAM_QUES;

-- Note: We insert WITHOUT specifying exam_question_id - trigger generates it!
INSERT INTO EXAM_QUES (exam_id, question_id, question_order, marks_allocated)
VALUES
    -- EX001: C# Fundamentals Midterm (5 questions)
    ('EX001', 1, 1, 4),
    ('EX001', 2, 2, 4),
    ('EX001', 3, 3, 6),
    ('EX001', 4, 4, 3),
    ('EX001', 5, 5, 3),
    
    -- EX002: C# Fundamentals Final (5 questions)
    ('EX002', 1, 1, 6),
    ('EX002', 2, 2, 5),
    ('EX002', 3, 3, 8),
    ('EX002', 4, 4, 6),
    ('EX002', 5, 5, 5),
    
    -- EX003: ASP.NET MVC Midterm (3 questions)
    ('EX003', 4, 1, 8),
    ('EX003', 5, 2, 7),
    ('EX003', 6, 3, 10),
    
    -- EX004: Entity Framework Quiz (2 questions)
    ('EX004', 6, 1, 8),
    ('EX004', 7, 2, 7),
    
    -- EX005: JavaScript ES6 Midterm (3 questions)
    ('EX005', 8, 1, 7),
    ('EX005', 9, 2, 6),
    ('EX005', 7, 3, 7),
    
    -- EX006: Node.js Final (3 questions)
    ('EX006', 10, 1, 10),
    ('EX006', 11, 2, 10),
    ('EX006', 12, 3, 10),
    
    -- EX007: Android Basics Quiz (2 questions)
    ('EX007', 12, 1, 8),
    ('EX007', 13, 2, 7),
    
    -- EX008: Python Data Science Midterm (3 questions)
    ('EX008', 14, 1, 7),
    ('EX008', 15, 2, 6),
    ('EX008', 16, 3, 7),
    
    -- EX009: Machine Learning Final (3 questions)
    ('EX009', 16, 1, 10),
    ('EX009', 17, 2, 10),
    ('EX009', 18, 3, 10),
    
    -- EX010: AWS Cloud Final (2 questions)
    ('EX010', 19, 1, 13),
    ('EX010', 20, 2, 12);

PRINT 'EXAM_QUES inserted: 31 records';
PRINT 'Sample generated keys: EX001-Q001, EX001-Q002, EX002-Q001, etc.';
GO

-- ================================================================
-- INSERT EXAM_SUBMIT (Auto-generated keys: SUB1001-EX001-A1, etc.)
-- ================================================================
PRINT 'Inserting EXAM_SUBMIT...';

-- Note: We insert WITHOUT specifying stud_submit_id - trigger generates it!
INSERT INTO EXAM_SUBMIT (student_id, exam_id, start_time, submit_time, submit_date, total_score, attempt_number, status)
VALUES
    -- Student 1001 submissions
    (1001, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 18.00, 1, 'graded'),
    (1001, 'EX002', '2023-04-10 10:00:00', '2023-04-10 11:30:00', '2023-04-10', 26.50, 1, 'graded'),
    (1001, 'EX003', '2023-06-20 09:00:00', '2023-06-20 10:15:00', '2023-06-20', 22.00, 1, 'graded'),
    (1001, 'EX001', '2023-02-20 09:00:00', '2023-02-20 10:00:00', '2023-02-20', 19.50, 2, 'graded'), -- Retake
    
    -- Student 1002 submissions
    (1002, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 15.00, 1, 'graded'),
    (1002, 'EX002', '2023-04-10 10:00:00', '2023-04-10 11:30:00', '2023-04-10', 22.00, 1, 'graded'),
    
    -- Student 1003 submissions
    (1003, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 19.00, 1, 'graded'),
    (1003, 'EX002', '2023-04-10 10:00:00', '2023-04-10 11:30:00', '2023-04-10', 28.00, 1, 'graded'),
    (1003, 'EX004', '2023-10-05 14:00:00', '2023-10-05 14:45:00', '2023-10-05', 13.50, 1, 'graded'),
    
    -- Student 2001 submissions (MEAN Stack)
    (2001, 'EX005', '2023-03-10 09:00:00', '2023-03-10 10:00:00', '2023-03-10', 18.50, 1, 'graded'),
    (2001, 'EX006', '2023-08-20 10:00:00', '2023-08-20 11:30:00', '2023-08-20', 27.00, 1, 'graded'),
    (2001, 'EX005', '2023-03-15 09:00:00', '2023-03-15 10:00:00', '2023-03-15', 19.00, 2, 'graded'), -- Retake
    
    -- Student 2002 submissions
    (2002, 'EX005', '2023-03-10 09:00:00', '2023-03-10 10:00:00', '2023-03-10', 16.50, 1, 'graded'),
    
    -- Student 3001 submissions (Mobile)
    (3001, 'EX007', '2023-08-15 14:00:00', '2023-08-15 14:45:00', '2023-08-15', 13.50, 1, 'graded'),
    
    -- Student 4001 submissions (Data Science)
    (4001, 'EX008', '2023-03-15 09:00:00', '2023-03-15 10:00:00', '2023-03-15', 19.00, 1, 'graded'),
    (4001, 'EX009', '2023-12-15 10:00:00', NULL, NULL, NULL, 1, 'in_progress'), -- Still taking exam
    
    -- Student 6001 submissions (Cloud)
    (6001, 'EX010', '2023-10-15 10:00:00', '2023-10-15 11:15:00', '2023-10-15', 23.50, 1, 'graded'),
    
    -- Student 1004 - In progress
    (1004, 'EX001', '2024-01-15 09:00:00', NULL, NULL, NULL, 1, 'in_progress');

PRINT 'EXAM_SUBMIT inserted: 18 records';
PRINT 'Sample generated keys: SUB1001-EX001-A1, SUB1001-EX001-A2, SUB2001-EX005-A1, etc.';
GO

-- ================================================================
-- INSERT STUDENT_ANSWER (Auto-generated keys: SUB1001-EX001-A1-Q001, etc.)
-- ================================================================
PRINT 'Inserting STUDENT_ANSWER...';
select * from EXAM_QUES
-- Note: We insert WITHOUT specifying answer_id - trigger generates it!
-- The trigger will create keys like: SUB1001-EX001-A1-Q001
INSERT INTO STUDENT_ANSWER (student_exam_id, exam_question_id, selected_choice_id, is_correct, marks_earned, answered_at)
VALUES
    -- SUB1001-EX001-A1: Student 1001, Exam EX001, Attempt 1 (Score: 18/20)
    ('SUB1001-EX001-A1', 'EX001-Q001', 'CH001', 1, 4.00, '2023-02-15 09:15:00'),
    ('SUB1001-EX001-A1', 'EX001-Q002', 'CH005', 1, 4.00, '2023-02-15 09:25:00'),
    ('SUB1001-EX001-A1', 'EX001-Q003', 'CH009', 1, 6.00, '2023-02-15 09:35:00'),
    ('SUB1001-EX001-A1', 'EX001-Q004', 'CH001', 1, 3.00, '2023-02-15 09:45:00'),
    ('SUB1001-EX001-A1', 'EX001-Q005', 'CH006', 0, 1.00, '2023-02-15 09:55:00'), -- Wrong answer
    
    -- SUB1001-EX002-A1: Student 1001, Exam EX002, Attempt 1 (Score: 26.5/30)
    ('SUB1001-EX002-A1', 'EX002-Q001', 'CH001', 1, 6.00, '2023-04-10 10:15:00'),
    ('SUB1001-EX002-A1', 'EX002-Q002', 'CH005', 1, 5.00, '2023-04-10 10:30:00'),
    ('SUB1001-EX002-A1', 'EX002-Q003', 'CH009', 1, 8.00, '2023-04-10 10:50:00'),
    ('SUB1001-EX002-A1', 'EX002-Q004', 'CH001', 1, 6.00, '2023-04-10 11:05:00'),
    ('SUB1001-EX002-A1', 'EX002-Q005', 'CH007', 0, 1.50, '2023-04-10 11:20:00'), -- Wrong answer
    
    -- SUB1001-EX003-A1: Student 1001, Exam EX003, Attempt 1 (Score: 22/25)
    ('SUB1001-EX003-A1', 'EX003-Q001', 'CH011', 1, 8.00, '2023-06-20 09:20:00'),
    ('SUB1001-EX003-A1', 'EX003-Q002', 'CH016', 1, 7.00, '2023-06-20 09:40:00'),
    ('SUB1001-EX003-A1', 'EX003-Q003', 'CH011', 1, 7.00, '2023-06-20 10:00:00'),
    
    -- SUB1001-EX001-A2: Student 1001, Exam EX001, Attempt 2 - RETAKE (Score: 19.5/20)
    ('SUB1001-EX001-A2', 'EX001-Q001', 'CH001', 1, 4.00, '2023-02-20 09:10:00'),
    ('SUB1001-EX001-A2', 'EX001-Q002', 'CH005', 1, 4.00, '2023-02-20 09:20:00'),
    ('SUB1001-EX001-A2', 'EX001-Q003', 'CH009', 1, 6.00, '2023-02-20 09:30:00'),
    ('SUB1001-EX001-A2', 'EX001-Q004', 'CH001', 1, 3.00, '2023-02-20 09:40:00'),
    ('SUB1001-EX001-A2', 'EX001-Q005', 'CH005', 1, 2.50, '2023-02-20 09:50:00'), -- Correct this time!
    
    -- SUB1002-EX001-A1: Student 1002, Exam EX001, Attempt 1 (Score: 15/20)
    ('SUB1002-EX001-A1', 'EX001-Q001', 'CH001', 1, 4.00, '2023-02-15 09:18:00'),
    ('SUB1002-EX001-A1', 'EX001-Q002', 'CH005', 1, 4.00, '2023-02-15 09:28:00'),
    ('SUB1002-EX001-A1', 'EX001-Q003', 'CH007', 0, 2.00, '2023-02-15 09:38:00'), -- Wrong
    ('SUB1002-EX001-A1', 'EX001-Q004', 'CH001', 1, 3.00, '2023-02-15 09:48:00'),
    ('SUB1002-EX001-A1', 'EX001-Q005', 'CH005', 1, 2.00, '2023-02-15 09:58:00'),
    
    -- SUB1002-EX002-A1: Student 1002, Exam EX002, Attempt 1 (Score: 22/30)
    ('SUB1002-EX002-A1', 'EX002-Q001', 'CH001', 1, 6.00, '2023-04-10 10:20:00'),
    ('SUB1002-EX002-A1', 'EX002-Q002', 'CH005', 1, 5.00, '2023-04-10 10:35:00'),
    ('SUB1002-EX002-A1', 'EX002-Q003', 'CH007', 0, 3.00, '2023-04-10 10:55:00'), -- Wrong
    ('SUB1002-EX002-A1', 'EX002-Q004', 'CH001', 1, 6.00, '2023-04-10 11:10:00'),
    ('SUB1002-EX002-A1', 'EX002-Q005', 'CH007', 0, 2.00, '2023-04-10 11:25:00'), -- Wrong
    
    -- SUB1003-EX001-A1: Student 1003, Exam EX001, Attempt 1 (Score: 19/20)
    ('SUB1003-EX001-A1', 'EX001-Q001', 'CH001', 1, 4.00, '2023-02-15 09:12:00'),
    ('SUB1003-EX001-A1', 'EX001-Q002', 'CH005', 1, 4.00, '2023-02-15 09:22:00'),
    ('SUB1003-EX001-A1', 'EX001-Q003', 'CH009', 1, 6.00, '2023-02-15 09:32:00'),
    ('SUB1003-EX001-A1', 'EX001-Q004', 'CH001', 1, 3.00, '2023-02-15 09:42:00'),
    ('SUB1003-EX001-A1', 'EX001-Q005', 'CH005', 1, 2.00, '2023-02-15 09:52:00'),
    
    -- SUB1003-EX002-A1: Student 1003, Exam EX002, Attempt 1 (Score: 28/30)
    ('SUB1003-EX002-A1', 'EX002-Q001', 'CH001', 1, 6.00, '2023-04-10 10:10:00'),
    ('SUB1003-EX002-A1', 'EX002-Q002', 'CH005', 1, 5.00, '2023-04-10 10:25:00'),
    ('SUB1003-EX002-A1', 'EX002-Q003', 'CH009', 1, 8.00, '2023-04-10 10:45:00'),
    ('SUB1003-EX002-A1', 'EX002-Q004', 'CH001', 1, 6.00, '2023-04-10 11:00:00'),
    ('SUB1003-EX002-A1', 'EX002-Q005', 'CH009', 1, 3.00, '2023-04-10 11:15:00'),
    
    -- SUB1003-EX004-A1: Student 1003, Exam EX004, Attempt 1 (Score: 13.5/15)
    ('SUB1003-EX004-A1', 'EX004-Q001', 'CH018', 1, 8.00, '2023-10-05 14:15:00'),
    ('SUB1003-EX004-A1', 'EX004-Q002', 'CH021', 1, 5.50, '2023-10-05 14:35:00'),
    
    -- SUB2001-EX005-A1: Student 2001, Exam EX005, Attempt 1 (Score: 18.5/20)
    ('SUB2001-EX005-A1', 'EX005-Q001', 'CH023', 1, 7.00, '2023-03-10 09:15:00'),
    ('SUB2001-EX005-A1', 'EX005-Q002', 'CH028', 1, 6.00, '2023-03-10 09:35:00'),
    ('SUB2001-EX005-A1', 'EX005-Q003', 'CH023', 1, 5.50, '2023-03-10 09:50:00'),
    
    -- SUB2001-EX006-A1: Student 2001, Exam EX006, Attempt 1 (Score: 27/30)
    ('SUB2001-EX006-A1', 'EX006-Q001', 'CH030', 1, 10.00, '2023-08-20 10:20:00'),
    ('SUB2001-EX006-A1', 'EX006-Q002', 'CH033', 1, 10.00, '2023-08-20 10:50:00'),
    ('SUB2001-EX006-A1', 'EX006-Q003', 'CH030', 1, 7.00, '2023-08-20 11:20:00'),
    
    -- SUB2001-EX005-A2: Student 2001, Exam EX005, Attempt 2 - RETAKE (Score: 19/20)
    ('SUB2001-EX005-A2', 'EX005-Q001', 'CH023', 1, 7.00, '2023-03-15 09:10:00'),
    ('SUB2001-EX005-A2', 'EX005-Q002', 'CH028', 1, 6.00, '2023-03-15 09:30:00'),
    ('SUB2001-EX005-A2', 'EX005-Q003', 'CH023', 1, 6.00, '2023-03-15 09:45:00'),
    
    -- SUB2002-EX005-A1: Student 2002, Exam EX005, Attempt 1 (Score: 16.5/20)
    ('SUB2002-EX005-A1', 'EX005-Q001', 'CH023', 1, 7.00, '2023-03-10 09:20:00'),
    ('SUB2002-EX005-A1', 'EX005-Q002', 'CH027', 0, 3.00, '2023-03-10 09:40:00'), -- Wrong
    ('SUB2002-EX005-A1', 'EX005-Q003', 'CH023', 1, 6.50, '2023-03-10 09:55:00'),
    
    -- SUB3001-EX007-A1: Student 3001, Exam EX007, Attempt 1 (Score: 13.5/15)
    ('SUB3001-EX007-A1', 'EX007-Q001', 'CH036', 1, 8.00, '2023-08-15 14:10:00'),
    ('SUB3001-EX007-A1', 'EX007-Q002', 'CH040', 1, 5.50, '2023-08-15 14:30:00'),
    
    -- SUB4001-EX008-A1: Student 4001, Exam EX008, Attempt 1 (Score: 19/20)
    ('SUB4001-EX008-A1', 'EX008-Q001', 'CH042', 1, 7.00, '2023-03-15 09:15:00'),
    ('SUB4001-EX008-A1', 'EX008-Q002', 'CH046', 1, 6.00, '2023-03-15 09:30:00'),
    ('SUB4001-EX008-A1', 'EX008-Q003', 'CH042', 1, 6.00, '2023-03-15 09:45:00'),
    
    -- SUB4001-EX009-A1: Student 4001, Exam EX009, Attempt 1 (IN PROGRESS - partial answers)
    ('SUB4001-EX009-A1', 'EX009-Q001', 'CH048', 1, 10.00, '2023-12-15 10:15:00'),
    ('SUB4001-EX009-A1', 'EX009-Q002', 'CH051', 1, 10.00, '2023-12-15 10:40:00'),
    -- Question 3 not answered yet (still in progress)
    
    -- SUB6001-EX010-A1: Student 6001, Exam EX010, Attempt 1 (Score: 23.5/25)
    ('SUB6001-EX010-A1', 'EX010-Q001', 'CH059', 1, 13.00, '2023-10-15 10:20:00'),
    ('SUB6001-EX010-A1', 'EX010-Q002', 'CH059', 1, 10.50, '2023-10-15 11:00:00'),
    
    -- SUB1004-EX001-A1: Student 1004, Exam EX001, Attempt 1 (IN PROGRESS - partial answers)
    ('SUB1004-EX001-A1', 'EX001-Q001', 'CH001', 1, 4.00, '2024-01-15 09:10:00'),
    ('SUB1004-EX001-A1', 'EX001-Q002', 'CH005', 1, 4.00, '2024-01-15 09:20:00');
    -- Questions 3-5 not answered yet (still in progress)

PRINT 'STUDENT_ANSWER inserted: 67 records';
PRINT 'Sample generated keys: SUB1001-EX001-A1-Q001, SUB1001-EX001-A1-Q002, etc.';
GO

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'DATA INSERTION COMPLETED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';

-- Show sample of generated keys
PRINT 'Sample EXAM_QUES keys:';
SELECT TOP 5 exam_question_id, exam_id, question_order, marks_allocated 
FROM EXAM_QUES 
ORDER BY exam_question_id;

PRINT '';
PRINT 'Sample EXAM_SUBMIT keys:';
SELECT TOP 5 stud_submit_id, student_id, exam_id, attempt_number, status, total_score
FROM EXAM_SUBMIT 
ORDER BY stud_submit_id;

PRINT '';
PRINT 'Sample STUDENT_ANSWER keys:';
SELECT TOP 5 answer_id, student_exam_id, exam_question_id, is_correct, marks_earned
FROM STUDENT_ANSWER 
ORDER BY answer_id;

PRINT '';
PRINT '========================================';
PRINT 'Summary Statistics:';
PRINT '========================================';

SELECT 
    'EXAM_QUES' as TableName,
    COUNT(*) as RecordCount
FROM EXAM_QUES
UNION ALL
SELECT 
    'EXAM_SUBMIT' as TableName,
    COUNT(*) as RecordCount
FROM EXAM_SUBMIT
UNION ALL
SELECT 
    'STUDENT_ANSWER' as TableName,
    COUNT(*) as RecordCount
FROM STUDENT_ANSWER;

GO

-- ================================================================
-- USEFUL QUERIES FOR THE NEW DESIGN
-- ================================================================

PRINT '';
PRINT '========================================';
PRINT 'Example Queries:';
PRINT '========================================';
GO

-- Query 1: Get all submissions for a student
PRINT '-- Query 1: All submissions for Student 1001:';
SELECT 
    stud_submit_id,
    exam_id,
    attempt_number,
    total_score,
    status,
    FORMAT(start_time, 'yyyy-MM-dd HH:mm') as start_time,
    FORMAT(submit_time, 'yyyy-MM-dd HH:mm') as submit_time
FROM EXAM_SUBMIT
WHERE student_id = 1001
ORDER BY start_time;
GO

-- Query 2: Get complete exam details with answers
PRINT '';
PRINT '-- Query 2: Complete submission details for SUB1001-EX001-A1:';
SELECT 
    sa.answer_id,
    sa.exam_question_id,
    q.question_content,
    c.choice_content as selected_answer,
    sa.is_correct,
    sa.marks_earned,
    eq.marks_allocated as max_marks
FROM STUDENT_ANSWER sa
JOIN EXAM_QUES eq ON sa.exam_question_id = eq.exam_question_id
JOIN QUESTION q ON eq.question_id = q.question_id
JOIN CHOICES c ON sa.selected_choice_id = c.choice_id
WHERE sa.student_exam_id = 'SUB1001-EX001-A1'
ORDER BY sa.exam_question_id;
GO

-- Query 3: Compare attempts (retakes)
PRINT '';
PRINT '-- Query 3: Compare Student 1001 attempts on EX001:';
SELECT 
    stud_submit_id,
    attempt_number,
    total_score,
    status,
    FORMAT(submit_time, 'yyyy-MM-dd HH:mm') as submit_time
FROM EXAM_SUBMIT
WHERE student_id = 1001 AND exam_id = 'EX001'
ORDER BY attempt_number;
GO

-- Query 4: Students currently taking exams (in_progress)
PRINT '';
PRINT '-- Query 4: Students currently taking exams:';
SELECT 
    es.stud_submit_id,
    es.student_id,
    si.f_name + ' ' + si.last_name as student_name,
    es.exam_id,
    e.exam_title,
    COUNT(sa.answer_id) as questions_answered,
    (SELECT COUNT(*) FROM EXAM_QUES WHERE exam_id = es.exam_id) as total_questions,
    FORMAT(es.start_time, 'yyyy-MM-dd HH:mm') as started_at
FROM EXAM_SUBMIT es
JOIN STUDENT s ON es.student_id = s.stud_id
JOIN STUDENT_INFO si ON s.stud_id = si.stud_id
JOIN EXAM e ON es.exam_id = e.exam_id
LEFT JOIN STUDENT_ANSWER sa ON es.stud_submit_id = sa.student_exam_id
WHERE es.status = 'in_progress'
GROUP BY es.stud_submit_id, es.student_id, si.f_name, si.last_name, 
         es.exam_id, e.exam_title, es.start_time;
GO

PRINT '';
PRINT '========================================';
PRINT 'ALL DONE! Your database is ready to use.';
PRINT '========================================';
PRINT '';
PRINT 'Key Features of this design:';
PRINT '1. Meaningful primary keys (EX001-Q001, SUB1001-EX001-A1, etc.)';
PRINT '2. Automatic key generation via triggers';
PRINT '3. Proper CASCADE handling for data integrity';
PRINT '4. Preserves historical data (submissions kept even if exam deleted)';
PRINT '5. Supports exam retakes (multiple attempts)';
PRINT '6. Tracks in-progress exams';
PRINT '';

GO
--************************************************************************************************************************************************
/*

-- << THis is the old code don't run it we changed above the new way for insert>>
-- ================================================================
-- EXAM_QUES (Questions assigned to exams)
-- ================================================================
SET IDENTITY_INSERT EXAM_QUES ON;

INSERT INTO EXAM_QUES (exam_question_id, exam_id, question_id, question_order, marks_allocated) VALUES
    -- EX001: C# Midterm (5 questions, 20 marks)
    (1, 'EX001', 1, 1, 4),(2, 'EX001', 2, 2, 4),(3, 'EX001', 3, 3, 6),
    (4, 'EX001', 1, 4, 3),(5, 'EX001', 2, 5, 3),
    -- EX002: C# Final (5 questions, 30 marks)
    (6, 'EX002', 1, 1, 6),(7, 'EX002', 2, 2, 5),(8, 'EX002', 3, 3, 8),
    (9, 'EX002', 1, 4, 6),(10, 'EX002', 3, 5, 5),
    -- EX003: ASP.NET Midterm (3 questions, 25 marks)
    (11, 'EX003', 4, 1, 8),(12, 'EX003', 5, 2, 7),(13, 'EX003', 4, 3, 10),
    -- EX004: EF Quiz (2 questions, 15 marks)
    (14, 'EX004', 6, 1, 8),(15, 'EX004', 7, 2, 7),
    -- EX005: JS Midterm (3 questions, 20 marks)
    (16, 'EX005', 8, 1, 7),(17, 'EX005', 9, 2, 6),(18, 'EX005', 8, 3, 7),
    -- EX006: Node.js Final (3 questions, 30 marks)
    (19, 'EX006', 10, 1, 10),(20, 'EX006', 11, 2, 10),(21, 'EX006', 10, 3, 10),
    -- EX007: Android Quiz (2 questions, 15 marks)
    (22, 'EX007', 12, 1, 8),(23, 'EX007', 13, 2, 7),
    -- EX008: Python Midterm (3 questions, 20 marks)
    (24, 'EX008', 14, 1, 7),(25, 'EX008', 15, 2, 6),(26, 'EX008', 14, 3, 7),
    -- EX009: ML Final (3 questions, 30 marks)
    (27, 'EX009', 16, 1, 10),(28, 'EX009', 17, 2, 10),(29, 'EX009', 16, 3, 10),
    -- EX010: AWS Final (2 questions, 25 marks)
    (30, 'EX010', 20, 1, 13),(31, 'EX010', 20, 2, 12);

SET IDENTITY_INSERT EXAM_QUES OFF;

PRINT 'Exam Questions assigned: 31';
GO

-- ================================================================
-- EXAM_SUBMIT (Student exam submissions)
-- ================================================================
INSERT INTO EXAM_SUBMIT (stud_submit_id, student_id, exam_id, start_time, submit_time, submit_date, total_score, attempt_number, status) VALUES
    ('SUB001', 1001, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 18.00, 1, 'graded'),
    ('SUB002', 1001, 'EX002', '2023-04-10 10:00:00', '2023-04-10 11:30:00', '2023-04-10', 26.50, 1, 'graded'),
    ('SUB003', 1001, 'EX003', '2023-06-20 09:00:00', '2023-06-20 10:15:00', '2023-06-20', 22.00, 1, 'graded'),
    ('SUB004', 1002, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 15.00, 1, 'graded'),
    ('SUB005', 1003, 'EX001', '2023-02-15 09:00:00', '2023-02-15 10:00:00', '2023-02-15', 19.00, 1, 'graded'),
    ('SUB006', 1003, 'EX002', '2023-04-10 10:00:00', '2023-04-10 11:30:00', '2023-04-10', 28.00, 1, 'graded'),
    ('SUB007', 1003, 'EX004', '2023-10-05 14:00:00', '2023-10-05 14:45:00', '2023-10-05', 13.50, 1, 'graded'),
    ('SUB008', 2001, 'EX005', '2023-03-10 09:00:00', '2023-03-10 10:00:00', '2023-03-10', 18.50, 1, 'graded'),
    ('SUB009', 2001, 'EX006', '2023-08-20 10:00:00', '2023-08-20 11:30:00', '2023-08-20', 27.00, 1, 'graded'),
    ('SUB010', 3001, 'EX007', '2023-08-15 14:00:00', '2023-08-15 14:45:00', '2023-08-15', 13.50, 1, 'graded'),
    ('SUB011', 4001, 'EX008', '2023-03-15 09:00:00', '2023-03-15 10:00:00', '2023-03-15', 19.00, 1, 'graded'),
    ('SUB012', 6001, 'EX010', '2023-10-15 10:00:00', '2023-10-15 11:15:00', '2023-10-15', 23.50, 1, 'graded'),
    ('SUB013', 1001, 'EX001', '2023-02-20 09:00:00', '2023-02-20 10:00:00', '2023-02-20', 19.50, 2, 'graded');

PRINT 'Exam Submissions inserted: 13';
GO

-- ================================================================
-- STUDENT_ANSWER (Student answers to exam questions)
-- ================================================================
SET IDENTITY_INSERT STUDENT_ANSWER ON;

INSERT INTO STUDENT_ANSWER (answer_id, student_exam_id, exam_question_id, selected_choice_id, is_correct, marks_earned) VALUES
    -- SUB001: Student 1001, EX001 - Score: 18/20
    (1, 'SUB001', 1, 'CH001', 1, 4.00),(2, 'SUB001', 2, 'CH005', 1, 4.00),
    (3, 'SUB001', 3, 'CH009', 1, 6.00),(4, 'SUB001', 4, 'CH001', 1, 3.00),
    (5, 'SUB001', 5, 'CH006', 0, 1.00),
    -- SUB002: Student 1001, EX002 - Score: 26.5/30
    (6, 'SUB002', 6, 'CH001', 1, 6.00),(7, 'SUB002', 7, 'CH005', 1, 5.00),
    (8, 'SUB002', 8, 'CH009', 1, 8.00),(9, 'SUB002', 9, 'CH001', 1, 6.00),
    (10, 'SUB002', 10, 'CH007', 0, 1.50),
    -- SUB003: Student 1001, EX003 - Score: 22/25
    (11, 'SUB003', 11, 'CH011', 1, 8.00),(12, 'SUB003', 12, 'CH016', 1, 7.00),
    (13, 'SUB003', 13, 'CH011', 1, 7.00),
    -- SUB004: Student 1002, EX001 - Score: 15/20
    (14, 'SUB004', 1, 'CH001', 1, 4.00),(15, 'SUB004', 2, 'CH005', 1, 4.00),
    (16, 'SUB004', 3, 'CH007', 0, 2.00),(17, 'SUB004', 4, 'CH001', 1, 3.00),
    (18, 'SUB004', 5, 'CH005', 1, 2.00),
    -- SUB005: Student 1003, EX001 - Score: 19/20
    (19, 'SUB005', 1, 'CH001', 1, 4.00),(20, 'SUB005', 2, 'CH005', 1, 4.00),
    (21, 'SUB005', 3, 'CH009', 1, 6.00),(22, 'SUB005', 4, 'CH001', 1, 3.00),
    (23, 'SUB005', 5, 'CH005', 1, 2.00),
    -- SUB006: Student 1003, EX002 - Score: 28/30
    (24, 'SUB006', 6, 'CH001', 1, 6.00),(25, 'SUB006', 7, 'CH005', 1, 5.00),
    (26, 'SUB006', 8, 'CH009', 1, 8.00),(27, 'SUB006', 9, 'CH001', 1, 6.00),
    (28, 'SUB006', 10, 'CH009', 1, 3.00),
    -- SUB007: Student 1003, EX004 - Score: 13.5/15
    (29, 'SUB007', 14, 'CH018', 1, 8.00),(30, 'SUB007', 15, 'CH021', 1, 5.50),
    -- SUB008: Student 2001, EX005 - Score: 18.5/20
    (31, 'SUB008', 16, 'CH023', 1, 7.00),(32, 'SUB008', 17, 'CH028', 1, 6.00),
    (33, 'SUB008', 18, 'CH023', 1, 5.50),
    -- SUB009: Student 2001, EX006 - Score: 27/30
    (34, 'SUB009', 19, 'CH030', 1, 10.00),(35, 'SUB009', 20, 'CH033', 1, 10.00),
    (36, 'SUB009', 21, 'CH030', 1, 7.00),
    -- SUB010: Student 3001, EX007 - Score: 13.5/15
    (37, 'SUB010', 22, 'CH036', 1, 8.00),(38, 'SUB010', 23, 'CH040', 1, 5.50),
    -- SUB011: Student 4001, EX008 - Score: 19/20
    (39, 'SUB011', 24, 'CH042', 1, 7.00),(40, 'SUB011', 25, 'CH046', 1, 6.00),
    (41, 'SUB011', 26, 'CH042', 1, 6.00),
    -- SUB012: Student 6001, EX010 - Score: 23.5/25
    (42, 'SUB012', 30, 'CH059', 1, 13.00),(43, 'SUB012', 31, 'CH059', 1, 10.50),
    -- SUB013: Student 1001 (2nd attempt), EX001 - Score: 19.5/20
    (44, 'SUB013', 1, 'CH001', 1, 4.00),(45, 'SUB013', 2, 'CH005', 1, 4.00),
    (46, 'SUB013', 3, 'CH009', 1, 6.00),(47, 'SUB013', 4, 'CH001', 1, 3.00),
    (48, 'SUB013', 5, 'CH005', 1, 2.50);

SET IDENTITY_INSERT STUDENT_ANSWER OFF;

PRINT 'Student Answers inserted: 48';
GO
*/
-- ================================================================
-- DATA INSERTION COMPLETED
-- ================================================================
PRINT '';
PRINT '========================================';
PRINT 'ITI EXAMINATION DATA INSERTION COMPLETED';
PRINT '========================================';
PRINT '';
PRINT 'Summary of Inserted Data:';
PRINT '- Instructors: 15';
PRINT '- Intakes: 5';
PRINT '- Departments: 3';
PRINT '- Tracks: 6';
PRINT '- Track-Intake Relationships: 15';
PRINT '- Instructor-Track Assignments: 15';
PRINT '- Students: 60';
PRINT '- Student Information: 20 (expand for all 60)';
PRINT '- Courses: 29';
PRINT '- Student-Course Enrollments: 17';
PRINT '- Instructor-Course Assignments: 17';
PRINT '- Topics: 10';
PRINT '- Questions: 20';
PRINT '- Choices: 62';
PRINT '- Exams: 10';
PRINT '- Exam Questions: 31';
PRINT '- Exam Submissions: 13';
PRINT '- Student Answers: 48';
PRINT '';
PRINT '========================================';
PRINT 'You can now query the database!';
PRINT 'Example: SELECT * FROM STUDENT;';
PRINT '========================================';
GO

SELECT * FROM STUDENT;
SELECT * FROM DEPARTMENT;
SELECT * FROM INSTRUCTOR;
SELECT * FROM INTAKE;
SELECT * FROM TRACK;
SELECT * FROM COURSE;
SELECT * FROM TOPIC;
SELECT * FROM TRACK_INTAKE;
SELECT * FROM STUDENT_INFO;
SELECT * FROM STUDENT_COURSE;
SELECT * FROM STUDENT_ANSWER;
SELECT * FROM EXAM_QUES;
SELECT * FROM QUESTION;
SELECT * FROM Choices;
SELECT * FROM EXAM;
SELECT * FROM EXAM_SUBMIT;
SELECT * FROM INSTRUCTOR_TRACK;
SELECT * FROM TRACK_INTAKE;




