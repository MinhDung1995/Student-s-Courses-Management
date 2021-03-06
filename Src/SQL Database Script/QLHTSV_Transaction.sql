USE StudentCoursesManagement;
Go
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Trasaction: Get All Opened Courses
IF OBJECT_ID('sp_GetAllOpenedCourses', 'P') is not null
	DROP PROC sp_GetAllOpenedCourses
GO
CREATE PROC sp_GetAllOpenedCourses 
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2)
	BEGIN 
		PRINT('ERROR');
		RETURN 0;
	END;
	
	BEGIN TRAN
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
		SELECT * 
		FROM MHMO
		WHERE (NAM = @year AND HOCKY = @semester) 	
	COMMIT TRAN
	
	RETURN 1;
	
END;
---------------------------------------------------------------------------------------------------
-- Trasaction: Register a Course
IF OBJECT_ID('sp_RegisterCourse', 'P') is not null
	DROP PROC sp_RegisterCourse
GO
CREATE PROC sp_RegisterCourse 
	@studentID INT,
	@objectID CHAR(6),
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @objectID IS NULL OR @studentID IS NULL)
	BEGIN 
		RETURN 0;
	END;
	
	-- Kiểm tra mã sinh viên có tồn tại
	IF (NOT EXISTS (SELECT MAMH 
				FROM MHMO 
				WHERE (MAMH = @objectID AND NAM = @year AND HOCKY = @semester)))
	BEGIN 
		RETURN 0;
	END;
	
	-- Kiểm tra mã sinh viên có tồn tại
	IF (NOT EXISTS (SELECT MASV 
				FROM SINHVIEN 
				WHERE (MASV = @studentID)))
	BEGIN 
		RETURN 0;
	END;
	
	BEGIN TRAN
	SET TRANSACTION ISOLATION LEVEL	SERIALIZABLE
		-- Kiểm tra còn chỗ
		IF ((SELECT DISTINCT COUNT(*) 
				FROM DANGKY WITH (ROWLOCK, XLOCK)
				WHERE (MAMH = @objectID AND NAM = @year AND HOCKY = @semester)) <
				(SELECT SOCHOMAX FROM MONHOC WITH (ROWLOCK, XLOCK) WHERE MAMH = @objectID))	
		BEGIN
			INSERT INTO DANGKY	(MASV, MAMH, NAM, HOCKY, DIEM)
			VALUES (@studentID, @objectID, @year, @semester, NULL);
		END;
		ELSE 
		BEGIN	
			PRINT ('FULL SLOT'); 
			RETURN 0;
		END;
		
	COMMIT TRAN
	
	RETURN 1;
	
END;
---------------------------------------------------------------------------------------------------
-- Trasaction: Cancel a Course
IF OBJECT_ID('sp_CancelCourse', 'P') is not null
	DROP PROC sp_CancelCourse
GO
CREATE PROC sp_CancelCourse 
	@studentID INT,
	@objectID CHAR(6),
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @objectID IS NULL OR @studentID IS NULL)
	BEGIN 
		PRINT('ERROR');
		RETURN 0;
	END;
	
	-- Kiểm tra mã sinh viên có tồn tại
	IF (NOT EXISTS (SELECT MAMH 
				FROM MHMO 
				WHERE (MAMH = @objectID AND NAM = @year AND HOCKY = @semester)))
	BEGIN 
		PRINT('ERROR');
		RETURN 0;
	END;
	
	-- Kiểm tra mã sinh viên có tồn tại
	IF (NOT EXISTS (SELECT MASV 
				FROM SINHVIEN 
				WHERE (MASV = @studentID)))
	BEGIN 
		RETURN 0;
	END;
	
	BEGIN TRAN
	SET TRANSACTION ISOLATION LEVEL	READ COMMITTED
		DELETE FROM DANGKY
		WHERE (MASV = @studentID AND MAMH = @objectID AND NAM = @year AND HOCKY = @semester);
	COMMIT TRAN
	
	RETURN 1;
	
END;
---------------------------------------------------------------------------------------------------
-- Trasaction: Open a Course
IF OBJECT_ID('sp_OpenCourse', 'P') is not null
	DROP PROC sp_OpenCourse
GO
CREATE PROC sp_OpenCourse 
	@objectID CHAR(6),
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @objectID IS NULL)
	BEGIN 
		RETURN 0;
	END;
	
	BEGIN TRAN
	SET TRANSACTION ISOLATION LEVEL	READ COMMITTED
		-- Kiểm tra mã khóa học có tồn tại
		IF (NOT EXISTS (SELECT MAMH 
				FROM MHMO 
				WHERE (MAMH = @objectID AND NAM = @year AND HOCKY = @semester)))
		BEGIN
			INSERT INTO MHMO (MAMH, NAM, HOCKY)
			VALUES (@objectID, @year, @semester);
		END;
	COMMIT TRAN
	
	RETURN 1;
	
END;
---------------------------------------------------------------------------------------------------
-- Trasaction: Update Max Number Of  Students Of Course
IF OBJECT_ID('sp_UpdateMaxStudentsOfCourse', 'P') is not null
	DROP PROC sp_UpdateMaxStudentsOfCourse
GO
CREATE PROC sp_UpdateMaxStudentsOfCourse 
	@objectID CHAR(6),
	@number INT
AS 
BEGIN

	-- Kiểm tra điều kiện
	IF (@number <= 0 OR @objectID IS NULL)
	BEGIN 
		RETURN 0;
	END;
	
	BEGIN TRAN
	SET TRANSACTION ISOLATION LEVEL	READ COMMITTED
	
		UPDATE MONHOC 
		SET SOCHOMAX = SOCHOMAX + @number
		WHERE MAMH = @objectID;
		
	COMMIT TRAN
	
	RETURN 1;
	
END;
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--Transaction: Get Result of Student
IF OBJECT_ID('sp_GetResultofStudent', 'P') IS NOT NULL
	DROP PROC sp_GetResultofStudent
GO
CREATE PROC sp_GetResultofStudent 
	@studentID INT,
	@year INT, 
	@semester INT
AS BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @studentID IS NULL)
	BEGIN 
		RETURN 0;
	END;
	
	--Kiểm tra điều kiện
	IF (@studentID NOT IN (SELECT	MASV
					  FROM		SINHVIEN))
	BEGIN 
		RETURN 0;
	END;
		
	BEGIN TRAN
	SET TRAN ISOLATION LEVEL READ COMMITTED
	
		SELECT	*
		FROM	DANGKY WITH (ROWLOCK)
		WHERE	(MASV = @studentID AND NAM = @year AND HOCKY = @semester);
		
	COMMIT TRAN
	
	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
--Transaction: Update Result of Student
IF OBJECT_ID('sp_UpdateResultofStudent', 'P') IS NOT NULL
	DROP PROC sp_UpdateResultofStudent
GO
CREATE PROC sp_UpdateResultofStudent 
	@studentID INT,
	@objectID CHAR(6),
	@year INT, 
	@semester INT,
	@score REAL
AS BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @objectID IS NULL OR 0 > @score OR @score > 10)
	BEGIN 
		RETURN 0;
	END;
	
	--Kiểm tra điều kiện
	IF (@studentID NOT IN (SELECT	MASV
					  FROM		SINHVIEN))
	BEGIN 
		RETURN 0;
	END;
		
		
	BEGIN TRAN
	SET TRAN ISOLATION LEVEL READ COMMITTED
	
		UPDATE	DANGKY
		SET		DIEM = @score
		WHERE	(MASV = @studentID AND NAM = @year AND HOCKY = @semester AND MAMH = @objectID);
		
	COMMIT TRAN
	
	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
--Transaction: Get Result of Student in a Year
IF OBJECT_ID('sp_GetResultofStudentInYear', 'P') IS NOT NULL
	DROP PROC sp_GetResultofStudentInYear
GO
CREATE PROC sp_GetResultofStudentInYear 
	@studentID INT,
	@year INT 
AS BEGIN

	-- Kiểm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year)
	BEGIN 
		RETURN 0;
	END;

	--Kiểm tra điều kiện
	IF (@studentID NOT IN (SELECT	MASV
					  FROM		SINHVIEN))
	BEGIN 
		RETURN 0;
	END;
		
	BEGIN TRAN
	SET TRAN ISOLATION LEVEL READ COMMITTED
	
		SELECT	*
		FROM	KETQUA WITH (ROWLOCK)
		WHERE	(MASV = @studentID AND NAM = @year);
		
	COMMIT TRAN
	
	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--Transaction: Get All Students
IF OBJECT_ID('sp_GetAllStudents', 'P') is not null
	DROP PROC sp_GetAllStudents
GO
CREATE PROC sp_GetAllStudents
AS BEGIN
	BEGIN TRAN
	SET TRAN ISOLATION LEVEL SERIALIZABLE
	
		SELECT	*
		FROM	SINHVIEN;
		
	COMMIT TRAN
	
	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
--Transaction: Add New Student
IF OBJECT_ID('sp_AddNewStudent', 'P') IS NOT NULL
	DROP PROC sp_AddNewStudent
GO
CREATE PROC sp_AddNewStudent 
	@studentID INT, 
	@fullname NVARCHAR(50), 
	@birthday DATETIME, 
	@classID CHAR(6)
AS BEGIN

	--Kiểm tra điều kiện
	IF (@studentID IN (SELECT MASV FROM SINHVIEN))
	BEGIN 
		RETURN 0;
	END;

	--Kiểm tra điều kiện
	IF (@classID NOT IN (SELECT MALOP FROM LOP))
	BEGIN 
		RETURN 0;
	END;
		
	BEGIN TRAN
	SET TRAN ISOLATION LEVEL READ COMMITTED
	
		INSERT SINHVIEN (MASV, HOTEN, NGAYSINH, MALOP)
		VALUES(@studentID, @fullname, @birthday, @classID);
		
		UPDATE	LOP
		SET		SISO = SISO + 1
		WHERE	MALOP = @classID;
		
	COMMIT TRAN

	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
--Transaction: Move class for Student
IF OBJECT_ID('sp_ChangeClass', 'P') IS NOT NULL
	DROP PROC sp_ChangeClass
GO
CREATE PROC sp_ChangeClass 
	@studentID INT, 
	@newClassID CHAR(6)
AS BEGIN
	--Kiểm tra điều kiện
	IF ((@studentID NOT IN (SELECT	MASV FROM SINHVIEN)) OR 
			(@newClassID NOT IN (SELECT	MALOP FROM LOP)))
	BEGIN 
		RETURN 0;
	END;

	BEGIN TRAN
	SET TRAN ISOLATION LEVEL READ COMMITTED
		DECLARE @oldClassID CHAR(6)

		SET @oldClassID = (SELECT MALOP FROM SINHVIEN WHERE MASV = @studentID);
		
		UPDATE	SINHVIEN
		SET		MALOP = @newClassID
		WHERE	MASV = @studentID;

		UPDATE	LOP
		SET		SISO = SISO + 1
		WHERE	MALOP = @newClassID;

		UPDATE	LOP
		SET		SISO = SISO - 1
		WHERE	MALOP = @oldClassID;
		
	COMMIT TRAN
	
	RETURN 1;
END;
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------