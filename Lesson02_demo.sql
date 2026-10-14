---Tạo CSDL cơ bản

	CREATE DATABASE Dev2601_Lesson02_Db
	GO

---2. Tạo CSDL tùy với file và collaction

CREATE DATABASE Dev2601_Lesson02_Db1
ON PRIMARY (
	NAME = Dev2601_Lesson02_Db1_Data,
	FILENAME = 'D:\SQL\Data\Dev2601_Lesson02_Db1_Data.mdf',
	SIZE = 64MB	, MAXSIZE = 2GB, FILEGROWTH = 64MB )

LOG ON (
NAME = Dev2601_Lesson02_Db1_Log,
FILENAME = 'D:\SQL\Data\Dev2601_Lesson02_Db1_Log.ldf',
SIZE = 10MB	, MAXSIZE = 10MB, FILEGROWTH = 2MB
)

COLLATE Vietnamese_100_CI_AS_SC_UTF8;
GO

--- 3.
-- CI/CS: phân biệt hoa thường · AI/AS: phân biệt dấu
SELECT 
    CASE WHEN N'Hà Nội' = N'ha noi' COLLATE Vietnamese_100_CI_AI 
         THEN 1 ELSE 0 END AS CI_AI,        -- 1: bỏ qua hoa thường + dấu

    CASE WHEN N'Hà Nội' = N'ha noi' COLLATE Vietnamese_100_CI_AS 
         THEN 1 ELSE 0 END AS CI_AS,        -- 0: phân biệt dấu

    CASE WHEN N'Hà Nội' = N'HÀ NỘI' COLLATE Vietnamese_100_CI_AS 
         THEN 1 ELSE 0 END AS CI_AS_Upper;  -- 1: không phân biệt hoa/thường

SELECT name FROM sys.fn_helpcollations()
WHERE name LIKE 'Vietnamese_100%UTF8';

--4. Đổi tùy chọn CSDL
ALTER DATABASE Dev2601_Lesson02_Db1 SET RECOVERY SIMPLE
GO
IF DB_ID (N'Dev2601_Lesson02_Db') IS NOT NULL
BEGIN
    ALTER DATABASE Dev2601_Lesson02_Db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Dev2601_Lesson02_Db;
END

--5.NULL , NOT NULL , DEFAULT 

USE Dev2601_Lesson02_Db1 ;
GO
CREATE TABLE dbo.DemoDefault (
    Id        int IDENTITY(1,1) PRIMARY KEY,
    Title     nvarchar(100) NOT NULL,          -- bắt buộc
    Note      nvarchar(200) NULL,              -- được phép NULL
    IsActive  bit           NOT NULL
              CONSTRAINT DF_DemoDefaults_IsActive DEFAULT 1,
    CreatedAt datetime2(0)  NOT NULL
              CONSTRAINT DF_DemoDefaults_Created DEFAULT SYSDATETIME()
)
GO
SELECT * FROM dbo.DemoDefault
GO

INSERT dbo.DemoDefault (Title, Note, IsActive) VALUES (N'BỎ QUA CỘT DEFAULT');
INSERT dbo.DemoDefault (Title, Note, IsActive) VALUES (N'NGUYỄN VĂN B',NULL,1);

INSERT INTO dbo_DemoDefault (Title,Note)
VALUES (N'Nguyen van E', Null)

UPDATE dbo_DemoDefault
SET Title = N'Đã cập nhật ghi chú mới', Note = 1
WHERE Id = 1


---7.RÀNG BUỘC KHÓA CHÍNH
CREATE TABLE dbo.Students(
    StudentId int IDENTITY(1,1) CONSTRAINT PK_Students PRIMARY KEY,
    FullName  nvarchar(100) NOT NULL,
    Email     varchar(150)  NOT NULL CONSTRAINT UQ_Students_Email UNIQUE,
    Phone     varchar(15)   NULL,
    City      nvarchar(50)  NULL,
    BirthDate date          NULL,
    Flags     int           NOT NULL CONSTRAINT DF_Students_Flags DEFAULT 0,
    CreatedAt datetime2(0)  NOT NULL CONSTRAINT DF_Students_CreatedAt DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Students_Email CHECK (Email LIKE '%_@_%')
)
GO

---8.FOREIGN KEY và  hành dộng tham chiếu

CREATE TABLE dbo.Categories (
    CategoryId   int IDENTITY(1,1)
                 CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName nvarchar(100) NOT NULL
                 CONSTRAINT UQ_Categories_Name UNIQUE,
    ParentId     int NULL                  -- danh mục cha (tự tham chiếu)
                 CONSTRAINT FK_Categories_Parent
                 REFERENCES dbo.Categories(CategoryId)
);
GO 
SELECT * FROM dbo.Categories
GO

CREATE TABLE dbo.Courses (
    CourseId   int IDENTITY(1,1) CONSTRAINT PK_Courses PRIMARY KEY,
    CourseCode varchar(20)   NOT NULL CONSTRAINT UQ_Courses_Code UNIQUE,
    CourseName nvarchar(200) NOT NULL,
    CategoryId int           NOT NULL
               CONSTRAINT FK_Courses_Categories
               REFERENCES dbo.Categories(CategoryId),
    Fee        decimal(12,0) NOT NULL
               CONSTRAINT CK_Courses_Fee CHECK (Fee >= 0),
    Hours      int           NOT NULL
               CONSTRAINT CK_Courses_Hours CHECK (Hours > 0),
    Tags       nvarchar(400) NULL,
    IsActive   bit           NOT NULL
               CONSTRAINT DF_Courses_IsActive DEFAULT 1
)
GO 
SELECT * FROM dbo.Courses
GO


---9. thêm sửa xóa
ALTER TABLE dbo_Students
    ADD Gender char(1) NULL
        CONSTRAINT CK_Students_Gender CHECK (Gender IN ('M', 'F'));
GO
SELECT * FROM dbo_Students
GO

ALTER TABLE dbo_Students ALTER COLUMN Phone varchar(20) NULL;

ALTER TABLE dbo_Students DROP CONSTRAINT CK_Students_Gender;
ALTER TABLE dbo_Students DROP COLUMN Gender;
GO
---10. Tra cứu  cấu trúc bằng metadata 
SELECT *
FROM sys.objects
where parent_object_id = OBJECT_ID('dbo_Courses')


---11. INSERT nhiều dòng 
INSERT INTO dbo.Categories (CategoryName , ParentId)
VALUES (N'Lập Trình ' , NULL), (N'Toán',NUll)
GO
SELECT * FROM dbo.Categories

DELETE FROM dbo.Categories
WHERE CategoryName = N'Lập Trình'
GO

