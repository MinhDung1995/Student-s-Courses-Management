





EXEC sp_GetAllOpenedCourses 2013, 2;
delete from MHMO 
where NAM = 2016 and MAMH = N'C    '
EXEC sp_UpdateMaxStudentsOfCourse N'G    ', 5;
EXEC sp_OpenCourse N'C    ', 2016, 2;

EXEC SP_CancelCourse 997, N'HQTDL ', 2016, 2;
EXEC SP_CancelCourse 998, N'HQTDL ', 2016, 2;
EXEC sp_OpenCourse N'HQTDL ', 2016, 2;

-- Xem dữ liệu bắt đầu
SELECT COUNT(*)
FROM DANGKY
WHERE  NAM = 2016 AND MAMH = N'HQTDL '

-- Mô tả tình huống
-- Môn học chỉ còn duy nhất 1 chỗ, nhiều người cùng đăng ký

-- Thực hiện thao tác này sau
EXEC sp_RegisterCourse 997, N'HQTDL ', 2016, 2;

