IF OBJECT_ID('sp_GetAllOpenedCourses1', 'P') is not null
	DROP PROC sp_GetAllOpenedCourses1
GO
CREATE PROC sp_GetAllOpenedCourses1
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiẻm tra điều kiện
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
		
		WAITFOR DELAY '00:00:05';
	COMMIT TRAN
	
	RETURN 1;
	
END;

IF OBJECT_ID('sp_RegisterCourse1', 'P') is not null
	DROP PROC sp_RegisterCourse1
GO
CREATE PROC sp_RegisterCourse1
	@studentID INT,
	@objectID CHAR(6),
	@year INT, 
	@semester INT
AS 
BEGIN

	-- Kiẻm tra điều kiện
	DECLARE @currentYear INT;
	SELECT @currentYear = YEAR(GETDATE());
	
	IF (@year < 1990 OR @currentYear < @year OR @semester < 1 OR @semester > 2
			OR @objectID IS NULL OR @studentID IS NULL)
	BEGIN 
		PRINT('ERROR');
		RETURN 0;
	END;
	
	-- Kiểm mã môn học có tồn tại
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
		PRINT('ERROR'); 
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
		
		WAITFOR DELAY '00:00:05';
		
	COMMIT TRAN
	
	RETURN 1;
	
END;