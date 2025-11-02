create table student_records(
					student_id int,
					student_name varchar(50),
					course_1 varchar(50),
					grade_1 char(2),
					course_2 varchar(50),
					grade_2 char(2),
					course_3 varchar(50),
					grade_3 char(2),
					instruction_1 varchar(50),
					instruction_2 varchar(50),
					instruction_3 varchar(50)
);

insert into student_records (student_id,student_name,course_1,grade_1,course_2,grade_2,course_3,grade_3) values(1,'Alice','Math','A','Physics','B','English','A');
insert into student_records (student_id,student_name,course_1,grade_1) values (2,'Bod','Math','C');

select * from student_records;

/* Problem

1. Repeated column patterns.
2. Can’t add a 4th course without altering the schema.
3. Wasted space for NULLs.
4. Hard to query or aggregate (e.g., “average grade per course”).
*/

-- 1NF
-- Split repeating groups into multiple rows.

create table student_courses_1nf (
							student_id int,
							student_name varchar(50),
							course_name varchar(50),
							instructor varchar(50),
							grade char(2)
);

insert into student_courses_1nf (student_id,student_name,course_name,grade)
select student_id,student_name,course_1,grade_1 from student_records where course_1 is not null
union all
SELECT student_id, student_name, course_2, grade_2 FROM student_records WHERE course_2 IS NOT NULL
UNION ALL
SELECT student_id, student_name, course_3, grade_3 FROM student_records WHERE course_3 IS NOT NULL;

select * from student_courses_1nf order by student_name,grade;

/* 2NF
we need to solve partial dependency, which causes data redundancy, inconsistency, and update anomalies.
*/

-- student table

create table students(
				student_id int primary key,
				student_name varchar(50)
);

insert into students (student_id,student_name)
select distinct student_id,student_name from student_courses_1nf;

select * from students;

-- course table

create table courses(
				course_id serial primary key,
				course_name varchar(50) unique,
				instuctor varchar(50)
);

select * from courses;

insert into courses (course_name,instuctor)
select distinct course_name,instructor from student_courses_1nf;

select * from courses;

-- link student to courses table

CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

select * from enrollments;

insert into enrollments (student_id,course_id,grade)
select s.student_id, c.course_id, sc.grade
from student_courses_1nf sc
join students s on s.student_id = sc.student_id
join courses c on c.course_name = sc.course_name;

select * from enrollments;

/* 3nf
Every non-key attribute depends only on the primary key, not on other non-key attributes.
*/

CREATE TABLE instructors (
    instructor_id SERIAL PRIMARY KEY,
    instructor_name VARCHAR(50),
    department VARCHAR(50)
);

INSERT INTO instructors (instructor_name, department) VALUES
('Dr. Smith', 'Mathematics'),
('Prof. Johnson', 'Physics'),
('Dr. Davis', 'English'),
('Ms. Clark', 'Computer Science'),
('Dr. Brown', 'Statistics');

select * from instructors;

ALTER TABLE courses
    ADD COLUMN instructor_id INT REFERENCES instructors(instructor_id);

ALTER TABLE courses
    DROP COLUMN instuctor;

select * from courses;

UPDATE courses SET instructor_id = 1 WHERE course_name = 'Math';
UPDATE courses SET instructor_id = 2 WHERE course_name = 'Physics';
UPDATE courses SET instructor_id = 3 WHERE course_name = 'English';
UPDATE courses SET instructor_id = 4 WHERE course_name = 'Computer Science';
UPDATE courses SET instructor_id = 5 WHERE course_name = 'Statistics';

select * from courses;

SELECT c.course_id, c.course_name, i.instructor_name, i.department
FROM courses c JOIN instructors i ON c.instructor_id = i.instructor_id;

/* BCNF
Every determinant (any column or combination of columns that functionally determines another) must be a candidate key.
*/

ALTER TABLE courses ADD COLUMN classroom VARCHAR(20);

CREATE TABLE instructor_classrooms (
    instructor_id INT REFERENCES instructors(instructor_id),
    classroom VARCHAR(20),
    PRIMARY KEY (instructor_id)
);

INSERT INTO instructor_classrooms VALUES
(1, 'Room 101'),
(2, 'Room 202'),
(3, 'Room 303'),
(4, 'Room 404'),
(5, 'Room 505');

SELECT 
    s.student_name,
    c.course_name,
    i.instructor_name,
    i.department,
    ic.classroom,
    e.grade
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
JOIN instructors i ON i.instructor_id = c.instructor_id
JOIN instructor_classrooms ic ON ic.instructor_id = i.instructor_id
ORDER BY s.student_name;

-- 4nf

SELECT * FROM students;

CREATE TABLE students_details (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100),
    hobbies TEXT[],
    languages TEXT[]
);

INSERT INTO students_details (student_name, hobbies, languages)
VALUES ('Alice', '{"Reading","Painting"}', '{"English","Bangla"}');

select * from students_details;

CREATE TABLE student_hobbies (
    student_id INT REFERENCES students(student_id),
    hobby VARCHAR(100),
    PRIMARY KEY (student_id, hobby)
);

CREATE TABLE student_languages (
    student_id INT REFERENCES students(student_id),
    language VARCHAR(100),
    PRIMARY KEY (student_id, language)
);

insert into student_hobbies (student_id,hobby)
select student_id,unnest(hobbies)
from students_details;

select * from student_hobbies;

INSERT INTO student_languages (student_id, language)
SELECT student_id, UNNEST(languages)
FROM students_details;

select * from student_languages;

CREATE TABLE student_course (
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    PRIMARY KEY (student_id, course_id)
);

CREATE TABLE course_instructor (
    course_id INT REFERENCES courses(course_id),
    instructor_id INT REFERENCES instructors(instructor_id),
    PRIMARY KEY (course_id, instructor_id)
);

CREATE TABLE student_instructor (
    student_id INT REFERENCES students(student_id),
    instructor_id INT REFERENCES instructors(instructor_id),
    PRIMARY KEY (student_id, instructor_id)
);

INSERT INTO student_course (student_id, course_id) VALUES
(1, 1),  -- Alice → Math
(1, 2),  -- Alice → Physics
(2, 3),  -- Bob → English
(2, 4),  -- Bob → Computer Science
(3, 1),  -- Charlie → Math
(3, 5);  -- Charlie → Statistics

INSERT INTO course_instructor (course_id, instructor_id) VALUES
(1, 1),  -- Math → Dr. Smith
(2, 2),  -- Physics → Prof. Johnson
(3, 3),  -- English → Dr. Davis
(4, 4),  -- CS → Ms. Clark
(5, 5);  -- Statistics → Dr. Brown

INSERT INTO student_instructor (student_id, instructor_id) VALUES
(1, 1), (1, 2),      -- Alice → Dr. Smith, Prof. Johnson
(2, 3), (2, 4),      -- Bob → Dr. Davis, Ms. Clark
(3, 1), (3, 5);      -- Charlie → Dr. Smith, Dr. Brown

SELECT 
    s.student_name,
    c.course_name,
    i.instructor_name,
    i.department
FROM student_course sc
JOIN course_instructor ci ON sc.course_id = ci.course_id
JOIN student_instructor si ON sc.student_id = si.student_id AND ci.instructor_id = si.instructor_id
JOIN students s ON s.student_id = sc.student_id
JOIN courses c ON c.course_id = sc.course_id
JOIN instructors i ON i.instructor_id = ci.instructor_id
ORDER BY s.student_name, c.course_name;