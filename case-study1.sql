CREATE TABLE courses (
course_id NUMBER(10) PRIMARY KEY,
course_name VARCHAR2(50) NOT NULL,
instructor VARCHAR2(50) NOT NULL,
start_date DATE NOT NULL,
end_date DATE NOT NULL,
status VARCHAR2(20) NOT NULL
);

CREATE TABLE students (
student_id NUMBER(10) PRIMARY KEY,
name VARCHAR2(50) NOT NULL,
email VARCHAR2(50) NOT NULL,
phone_number VARCHAR2(20) NOT NULL,
address VARCHAR2(200) NOT NULL
);

CREATE TABLE course_enrollment (
course_id NUMBER(10) NOT NULL,
student_id NUMBER(10) NOT NULL,
enrollment_date DATE NOT NULL,
completion_date DATE,
CONSTRAINT fk_courses FOREIGN KEY (course_id) REFERENCES courses(course_id),
CONSTRAINT fk_students FOREIGN KEY (student_id) REFERENCES students(student_id)
);


-- Insert values into the courses table
INSERT INTO courses (course_id, course_name, instructor, start_date, end_date, status)
VALUES (2, 'Introduction to Programming', 'John Smith', TO_DATE('2023-09-01', 'YYYY-MM-DD'), TO_DATE('2023-12-15', 'YYYY-MM-DD'), 'In Progress');

INSERT INTO courses (course_id, course_name, instructor, start_date, end_date, status)
VALUES (3, 'Database Management', 'Jane Doe', TO_DATE('2023-10-01', 'YYYY-MM-DD'), TO_DATE('2024-01-15', 'YYYY-MM-DD'), 'In Progress');

INSERT INTO courses (course_id, course_name, instructor, start_date, end_date, status)
VALUES (1, 'Mathematics', 'John Smith', TO_DATE('2023-07-01', 'YYYY-MM-DD'), TO_DATE('2023-12-31', 'YYYY-MM-DD'), 'Available');

-- Insert values into the students table
INSERT INTO students (student_id, name, email, phone_number, address)
VALUES (1, 'Alice Smith', 'alice@example.com', '123-456-7890', '123 Main St');

UPDATE students
SET name = 'Vaishali Pandey', email = 'vishu@example.com', address = '123 Main Road'
where student_id = 1;

INSERT INTO students (student_id, name, email, phone_number, address)
VALUES (2, 'Bob Smith', 'bob@example.com', '987-654-3210', '456 Elm St');

-- Insert values into the course_enrollment table
INSERT INTO course_enrollment (course_id, student_id, enrollment_date)
VALUES (1, 1, SYSDATE);

INSERT INTO course_enrollment (course_id, student_id, enrollment_date, completion_date)
VALUES (2, 1, SYSDATE, NULL);

INSERT INTO course_enrollment (course_id, student_id, enrollment_date, completion_date)
VALUES (2, 2, SYSDATE, NULL);



select * from courses;
select * from students;
select * from course_enrollment;



SET SERVEROUTPUT ON;
CREATE OR REPLACE TRIGGER student_enrollment_limit_trigger
BEFORE INSERT OR UPDATE ON course_enrollment
FOR EACH ROW
DECLARE
  max_enrollments NUMBER := 2; -- Change the value as per your requirement
  current_enrollments NUMBER;
BEGIN
  SELECT COUNT(*) INTO current_enrollments
  FROM course_enrollment
  WHERE student_id = :NEW.student_id;

  IF current_enrollments >= max_enrollments THEN
    DBMS_OUTPUT.PUT_LINE('Enrollment limit reached for student: ' || :NEW.student_id);
    DBMS_OUTPUT.PUT_LINE('Current enrollment count: ' || current_enrollments);
    RAISE_APPLICATION_ERROR(-20001, 'Enrollment limit reached. Cannot enroll in more courses.');
  END IF;
END;
/

SELECT COUNT(*) FROM course_enrollment;

INSERT INTO course_enrollment (course_id, student_id, enrollment_date, completion_date)
VALUES (3, 1, SYSDATE, NULL);


CREATE OR REPLACE PROCEDURE get_ongoing_courses_cur(out_cur OUT SYS_REFCURSOR)
IS
BEGIN
  OPEN out_cur FOR
    SELECT course_id, course_name, instructor, start_date
    FROM courses
    WHERE status = 'In Progress';
END;


CREATE OR REPLACE PROCEDURE delete_student(p_student_id IN NUMBER)
IS
BEGIN
  DELETE FROM course_enrollment
  WHERE student_id = p_student_id;
  
  DELETE FROM students
  WHERE student_id = p_student_id;
  
  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Student not found.');
END;
/

CREATE OR REPLACE FUNCTION count_available_courses_in_subject(p_subject IN VARCHAR2) 
RETURN NUMBER
AS
  available_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO available_count
  FROM courses
  WHERE course_name LIKE '%' || p_subject || '%'
  AND status = 'Available';
  
  RETURN available_count;
END;

SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE enroll_student(p_student_id IN NUMBER, p_course_id IN NUMBER)
IS
  enroll_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO enroll_count
  FROM course_enrollment
  WHERE student_id = p_student_id AND course_id = p_course_id;

  IF enroll_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Student is already enrolled in the course.');
  ELSE
    -- Perform the enrollment
    INSERT INTO course_enrollment (course_id, student_id, enrollment_date)
    VALUES (p_course_id, p_student_id, SYSDATE);
  END IF;
END;



--updating completion date in course_enrollment for triggering the course_completed_trigger trigger
UPDATE course_enrollment
SET completion_date = SYSDATE
WHERE course_enrollment.course_id = 2 and course_enrollment.student_id = 2;

--executing the cursor
VAR cur REFCURSOR;
EXEC get_ongoing_courses_cur(:cur);
PRINT cur;

--executing the delete_student procedure
EXEC delete_student(1);

--EXECUTING THE count_available_courses_in_subject FUNCTION
SET SERVEROUTPUT ON;
DECLARE
  available_count NUMBER;
BEGIN
  available_count := count_available_courses_in_subject('Programming');
  DBMS_OUTPUT.PUT_LINE('Available Courses in Programming: ' || available_count);
END;
/

--CALLING enroll_student PROCEDURE
DECLARE
  student_id NUMBER := 2; 
  course_id NUMBER := 3;
BEGIN
  enroll_student(student_id, course_id);
  DBMS_OUTPUT.PUT_LINE('Student enrolled successfully.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

--or by executing the procedure with arguments
EXEC enroll_student(2,3);











