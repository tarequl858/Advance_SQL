-- one to one relation

create table students(
				student_id serial primary key,
				student_name varchar(50)
);

create table student_profiles(
				profile_id serial primary key,
				student_id int unique references students(student_id),
				data_of_birth date,
				email varchar(100)
);

INSERT INTO students (student_name) VALUES
('Alice'), ('Bob');

INSERT INTO student_profiles (student_id, data_of_birth, email)
VALUES
(1, '12/5/2000', 'alice@example.com'),
(2, '9/7/2001', 'bob@example.com');

select s.student_name , p.data_of_birth, p.email
from students s
join student_profiles p on s.student_id = p.student_id;

-- one to many

create table instructions(
					instructor_id serial primary key,
					instructor_name varchar(50)
);

create table courses(
				course_id serial primary key,
				course_name varchar(50),
				instructor_id int references instructions(instructor_id)
);

INSERT INTO instructions (instructor_name) VALUES
('Dr. Smith'), ('Prof. Johnson');

INSERT INTO courses (course_name, instructor_id)
VALUES
('Math', 1),
('Algebra', 1),
('Physics', 2);

select i.instructor_name, c.course_name
from instructions i
join courses c on i.instructor_id = c.instructor_id
order by i.instructor_name;

-- many to one

select c.course_name, i.instructor_name
from courses c
join instructions i on c.instructor_id = i.instructor_id;

-- many to many

CREATE TABLE students_info (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(50)
);

CREATE TABLE courses_info (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(50)
);

CREATE TABLE enrollments (
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO students_info (student_name) VALUES
('Alice'), ('Bob');

INSERT INTO courses_info (course_name) VALUES
('Math'), ('Physics');

INSERT INTO enrollments (student_id, course_id) VALUES
(1, 1), (1, 2), (2, 2);

SELECT s.student_name, c.course_name
FROM enrollments e
JOIN students_info s ON e.student_id = s.student_id
JOIN courses_info c ON e.course_id = c.course_id
ORDER BY s.student_name;