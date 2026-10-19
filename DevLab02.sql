USE Devmaster_Lab02;
GO

DROP TABLE IF EXISTS dbo.Attendance;    
DROP TABLE IF EXISTS dbo.ClassStudents; 
DROP TABLE IF EXISTS dbo.Classes;       
DROP SEQUENCE IF EXISTS dbo.seq_ClassNo;
GO

CREATE SEQUENCE dbo.seq_ClassNo
    AS int
    START WITH 1
    INCREMENT BY 1;
GO


CREATE TABLE dbo.Classes (
    ClassId         int             IDENTITY(1,1)       CONSTRAINT PK_Classes PRIMARY KEY,  
    ClassCode       varchar(20)     NOT NULL            CONSTRAINT UQ_Classes_Code UNIQUE,
    CourseId        int             NOT NULL            CONSTRAINT FK_Classes_Course REFERENCES dbo.Courses(CourseId),
    StartDate       date            NOT NULL,
    EndDate         date            NOT NULL,
    MaxStudents     int             NOT NULL            CONSTRAINT DF_Classes_MaxStudents DEFAULT 30
                                                        CONSTRAINT CK_Classes_MaxStudents CHECK (MaxStudents BETWEEN 5 AND 60),
    Room            nvarchar(30)    NULL,
    Status          varchar(20)     NOT NULL            CONSTRAINT DF_Classes_Status DEFAULT 'Open'
                                                        CONSTRAINT CK_Classes_Status CHECK (Status IN ('Open', 'Running', 'Closed')),

    CONSTRAINT CK_Classes_Date CHECK (EndDate > StartDate)
);
GO

-- Bảng ClassStudents
CREATE TABLE dbo.ClassStudents (
    ClassId         int             NOT NULL            CONSTRAINT FK_ClassStudents_Class REFERENCES dbo.Classes(ClassId),
    StudentId       int             NOT NULL            CONSTRAINT FK_ClassStudents_Student REFERENCES dbo.Students(StudentId),
    JoinedAt        datetime2(0)    NOT NULL            CONSTRAINT DF_ClassStudents_JoinedAt DEFAULT SYSDATETIME(),
    Grade           decimal(4,2)    NULL                CONSTRAINT DF_ClassStudents_Grade DEFAULT NULL,
    
    CONSTRAINT PK_ClassStudents PRIMARY KEY (ClassId, StudentId),
    CONSTRAINT CK_ClassStudents_Grade CHECK (Grade >= 0 AND Grade <= 10)
);
GO

-- Bảng Attendance
CREATE TABLE dbo.Attendance (
    AttendanceId    int             IDENTITY(1,1)       CONSTRAINT PK_Attendance PRIMARY KEY,
    ClassId         int             NOT NULL,
    StudentId       int             NOT NULL,
    SessionDate     date            NOT NULL,
    IsPresent       bit             NOT NULL            CONSTRAINT DF_Attendance_IsPresent DEFAULT 1,
    Note            nvarchar(200)   NULL,

    CONSTRAINT FK_Attendance_ClassStudents 
        FOREIGN KEY (ClassId, StudentId) 
        REFERENCES dbo.ClassStudents (ClassId, StudentId)
        ON DELETE CASCADE,

    CONSTRAINT UQ_Attendance_StudentClassDate UNIQUE (ClassId, StudentId, SessionDate)
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE CategoryId = 1)
BEGIN
    SET IDENTITY_INSERT dbo.Categories ON;
    INSERT INTO dbo.Categories (CategoryId, CategoryName, ParentId) 
    VALUES (1, N'Công nghệ thông tin', NULL);
    SET IDENTITY_INSERT dbo.Categories OFF;
END
GO


IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseId IN (2, 3, 8))
BEGIN
    SET IDENTITY_INSERT dbo.Courses ON;

    INSERT INTO dbo.Courses (CourseId, CourseCode, CourseName, CategoryId, Fee, Hours, Tags, IsActive)
    VALUES  
        (2, 'SQL-DEV',   N'Lập trình SQL Server', 1, 3000000, 40, N'SQL,Database', 1),
        (3, 'REACT-DEV', N'Lập trình ReactJS',    1, 4000000, 48, N'React,Frontend', 1),
        (8, 'GIT-DEV',   N'Quản lý Git/GitHub',   1, 1500000, 16, N'Git,DevOps', 1);

    SET IDENTITY_INSERT dbo.Courses OFF;
END
GO



INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, MaxStudents, Room) 
VALUES 
    ('SQL-K01',   2, '2026-10-05', '2026-12-14', 25, N'P301'),
    ('REACT-K02', 3, '2026-10-12', '2027-01-18', 30, N'P302'),
    ('GIT-K01',   8, '2026-11-02', '2026-11-27', 20, NULL);
GO

SELECT * FROM dbo.Courses;
SELECT * FROM dbo.Classes;
GO


--- Bài 5
DECLARE @ClassId_SQL int = (SELECT ClassId FROM dbo.Classes WHERE ClassCode = 'SQL-K01');

INSERT INTO dbo.ClassStudents (ClassId, StudentId)
SELECT @ClassId_SQL, s.StudentId
FROM dbo.Students s
WHERE s.City = N'Hà Nội'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ClassStudents cs 
      WHERE cs.ClassId = @ClassId_SQL AND cs.StudentId = s.StudentId
  );

PRINT N'Số học viên Hà Nội ghi danh vào SQL-K01: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

DECLARE @ClassId_REACT int = (SELECT ClassId FROM dbo.Classes WHERE ClassCode = 'REACT-K02');

INSERT INTO dbo.ClassStudents (ClassId, StudentId)
SELECT @ClassId_REACT, s.StudentId
FROM dbo.Students s
WHERE (s.Flags & 2) = 2 
  AND NOT EXISTS (
      SELECT 1 FROM dbo.ClassStudents cs 
      WHERE cs.ClassId = @ClassId_REACT AND cs.StudentId = s.StudentId
  );

PRINT N'Số học viên có học bổng ghi danh vào REACT-K02: ' + CAST(@@ROWCOUNT AS varchar(10));
GO

--- Bài 6

DECLARE @ClassId_SQL int = (SELECT ClassId FROM dbo.Classes WHERE ClassCode = 'SQL-K01');

INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate, IsPresent)
SELECT ClassId, StudentId, '2026-10-05', 1
FROM dbo.ClassStudents
WHERE ClassId = @ClassId_SQL;

INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate, IsPresent)
SELECT ClassId, StudentId, '2026-10-07', 1
FROM dbo.ClassStudents
WHERE ClassId = @ClassId_SQL;

UPDATE dbo.Attendance
SET IsPresent = 0, Note = N'Ốm'
WHERE ClassId = @ClassId_SQL AND StudentId = 10 AND SessionDate = '2026-10-05';

UPDATE dbo.Attendance
SET IsPresent = 0, Note = N'Vắng mặt'
WHERE ClassId = @ClassId_SQL AND StudentId IN (3, 10) AND SessionDate = '2026-10-07';

SELECT COUNT(*) AS SoLuongVang
FROM dbo.Attendance
WHERE ClassId = @ClassId_SQL AND IsPresent = 0;
GO

--- Bài 7

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate)
VALUES ('TEST-ERR-A', 2, '2026-10-10', '2026-10-01');

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, MaxStudents)
VALUES ('TEST-ERR-B', 2, '2026-10-01', '2026-11-01', 3);

INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
VALUES (1, 999999, '2026-10-05');

INSERT INTO dbo.Attendance (ClassId, StudentId, SessionDate)
VALUES (
    (SELECT TOP 1 ClassId FROM dbo.Attendance),
    (SELECT TOP 1 StudentId FROM dbo.Attendance),
    '2026-10-05'
);

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, Status)
VALUES ('TEST-ERR-E', 2, '2026-10-01', '2026-11-01', 'Paused');
GO

--- Bài 8 

WITH CategoryHierarchy AS (
    SELECT CategoryId
    FROM dbo.Categories
    WHERE CategoryName LIKE N'%Lập trình%'
    
    UNION ALL
    
    SELECT c.CategoryId
    FROM dbo.Categories c
    INNER JOIN CategoryHierarchy ch ON c.ParentId = ch.CategoryId
)
UPDATE c
SET c.EndDate = DATEADD(DAY, 7, c.EndDate)
OUTPUT 
    inserted.ClassCode,
    deleted.EndDate  AS OldEndDate,
    inserted.EndDate AS NewEndDate
FROM dbo.Classes c
INNER JOIN dbo.Courses cr ON c.CourseId = cr.CourseId
INNER JOIN CategoryHierarchy ch ON cr.CategoryId = ch.CategoryId;
GO

--- Bài 9

BEGIN TRANSACTION;

DECLARE @ClassId_SQL int = (SELECT ClassId FROM dbo.Classes WHERE ClassCode = 'SQL-K01');

SELECT 
    (SELECT COUNT(*) FROM dbo.ClassStudents WHERE ClassId = @ClassId_SQL) AS ClassStudents_Truoc,
    (SELECT COUNT(*) FROM dbo.Attendance WHERE ClassId = @ClassId_SQL)    AS Attendance_Truoc;

DELETE FROM dbo.ClassStudents
OUTPUT deleted.*
WHERE ClassId = @ClassId_SQL AND StudentId = 10;

SELECT 
    (SELECT COUNT(*) FROM dbo.ClassStudents WHERE ClassId = @ClassId_SQL) AS ClassStudents_Sau,
    (SELECT COUNT(*) FROM dbo.Attendance WHERE ClassId = @ClassId_SQL)    AS Attendance_Sau;


ROLLBACK TRANSACTION;
PRINT N'Đã hoàn tất kiểm tra và ROLLBACK thành công!';
GO


--- bài 10

ALTER TABLE dbo.Classes
    ADD DurationDays AS (DATEDIFF(DAY, StartDate, EndDate) + 1) PERSISTED;
GO

CREATE UNIQUE NONCLUSTERED INDEX UQ_Classes_Room_StartDate
ON dbo.Classes (Room, StartDate)
WHERE Room IS NOT NULL;
GO

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, Room)
VALUES 
    ('NULL-R01', 2, '2026-12-01', '2026-12-30', NULL),
    ('NULL-R02', 2, '2026-12-01', '2026-12-30', NULL);

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, Room)
VALUES ('P1-CLASS-1', 2, '2026-12-01', '2026-12-30', N'P101');

DELETE FROM dbo.Classes WHERE ClassCode IN ('NULL-R01', 'NULL-R02', 'P1-CLASS-1');
GO

--- bài 11
DROP SEQUENCE IF EXISTS dbo.seq_ClassNo;
GO

CREATE SEQUENCE dbo.seq_ClassNo
    AS int
    START WITH 4
    INCREMENT BY 1;
GO


DECLARE @CourseId_SQLDEV int = (SELECT CourseId FROM dbo.Courses WHERE CourseCode = 'SQL-DEV');
DECLARE @NextVal int = (NEXT VALUE FOR dbo.seq_ClassNo);
DECLARE @GeneratedCode varchar(20) = 'DM-2026-' + FORMAT(@NextVal, '000');

INSERT INTO dbo.Classes (ClassCode, CourseId, StartDate, EndDate, MaxStudents, Room)
VALUES (@GeneratedCode, @CourseId_SQLDEV, '2026-11-02', '2027-01-11', 30, N'P201');


SELECT ClassId, ClassCode, CourseId, StartDate, EndDate, DurationDays 
FROM dbo.Classes 
WHERE ClassCode = @GeneratedCode;
GO

