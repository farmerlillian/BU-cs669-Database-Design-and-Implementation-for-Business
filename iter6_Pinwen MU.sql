DROP VIEW GoalAchievement;
DROP TABLE Value_change;
DROP TABLE Match;
DROP TABLE Competition;
DROP TABLE Prize;
DROP TABLE Review;
DROP TABLE Workout;
DROP TABLE Stretch;
DROP TABLE Fitness_video;
DROP TABLE Rest;
DROP TABLE Focus;
DROP TABLE Period;
DROP TABLE Goal;
DROP TABLE Account;
DROP TABLE AccountGroup;

DROP  SEQUENCE value_change_seq;
DROP  SEQUENCE match_seq;
DROP  SEQUENCE competition_seq;
DROP  SEQUENCE prize_seq;
DROP  SEQUENCE review_seq;
DROP  SEQUENCE fitness_video_seq;
DROP  SEQUENCE period_seq;
DROP  SEQUENCE goal_seq;
DROP  SEQUENCE account_seq;
DROP  SEQUENCE accountgroup_seq;

--TABLES
--Replace this with your table creations.
CREATE TABLE AccountGroup(
group_id DECIMAL(12) NOT NULL PRIMARY KEY,
group_name VARCHAR(16) NOT NULL,
creation_date DATE NOT NULL,
total_pomos INTEGER NOT NULL DEFAULT 0,
group_description VARCHAR(512)
);

CREATE TABLE Account(
account_id DECIMAL(12) NOT NULL PRIMARY KEY,
group_id DECIMAL(12) REFERENCES AccountGroup(group_id),
account_name VARCHAR(16) NOT NULL,
email VARCHAR(64) NOT NULL,
gender VARCHAR(6),
birthday DATE,
member_since DATE NOT NULL,
description VARCHAR(512)
);

CREATE TABLE Goal(
goal_id DECIMAL(12) NOT NULL PRIMARY KEY,
account_id DECIMAL(12) NOT NULL REFERENCES Account(account_id),
date DATE NOT NULL,
goal INTEGER NOT NULL
);

CREATE TABLE Period(
period_id DECIMAL(12) NOT NULL PRIMARY KEY,
account_id DECIMAL(12) NOT NULL REFERENCES Account(account_id),
start_time TIMESTAMP NOT NULL ,
end_time TIMESTAMP NOT NULL,
period_type VARCHAR(16) NOT NULL
);

CREATE TABLE Focus(
period_id DECIMAL(12) NOT NULL PRIMARY KEY REFERENCES Period(period_id),
is_one_pomo BOOLEAN NOT NULL,
focus_label VARCHAR(64) NOT NULL DEFAUlT 'study'
);

CREATE TABLE Rest(
period_id DECIMAL(12) NOT NULL PRIMARY KEY REFERENCES Period(period_id),
is_workout BOOLEAN NOT NULL
);

CREATE TABLE Fitness_video(
vedio_id DECIMAL(12) NOT NULL PRIMARY KEY,
vedio_address VARCHAR(128) NOT NULL,
vedio_type VARCHAR(16) NOT NULL
);

CREATE TABLE Stretch(
vedio_id DECIMAL(12) NOT NULL PRIMARY KEY REFERENCES Fitness_video(vedio_id),
body_part VARCHAR(64) NOT NULL
);

CREATE TABLE Workout(
vedio_id DECIMAL(12) NOT NULL PRIMARY KEY REFERENCES Fitness_video(vedio_id),
intensity INTEGER NOT NULL
);

CREATE TABLE Review(
review_id DECIMAL(12) NOT NULL PRIMARY KEY,
account_id DECIMAL(12) NOT NULL REFERENCES Account(account_id),
vedio_id DECIMAL(12) NOT NULL REFERENCES Fitness_video(vedio_id),
like_dislike BOOLEAN NOT NULL,
comment VARCHAR(512),
review_date DATE NOT NULL
);

CREATE TABLE Prize(
prize_id DECIMAL(12) NOT NULL PRIMARY KEY,
prize_name VARCHAR(128) NOT NULL,
prize_description VARCHAR(512) NOT NULL,
prize_value DECIMAL(5,2) NOT NULL
);

CREATE TABLE Competition(
competition_id  DECIMAL(12) NOT NULL PRIMARY KEY,
prize_id DECIMAL(12) NOT NULL REFERENCES Prize(prize_id),
competition_name VARCHAR(128) NOT NULL,
competition_description VARCHAR(512) NOT NULL,
start_date DATE NOT NULL,
end_date DATE NOT NULL
);

CREATE TABLE Match(
match_id DECIMAL(12) NOT NULL,
group_id DECIMAL(12) NOT NULL REFERENCES AccountGroup(group_id),
competition_id  DECIMAL(12) NOT NULL REFERENCES Competition(competition_id),
group_pomos INTEGER NOT NULL DEFAULT 0,
winner BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE Match ADD CONSTRAINT PK_match PRIMARY KEY (match_id,group_id);

CREATE TABLE Value_change(
change_id DECIMAL(12) NOT NULL PRIMARY KEY,
prize_id DECIMAL(12) NOT NULL REFERENCES Prize(prize_id),
old_value DECIMAL(5,2) NOT NULL,
new_value DECIMAL(5,2) NOT NULL,
date DATE NOT NULL
);

--SEQUENCES
--Replace this with your sequence creations.
--All tables that need them should have an associated sequence.
CREATE SEQUENCE accountgroup_seq;
CREATE SEQUENCE account_seq;
CREATE SEQUENCE goal_seq;
CREATE SEQUENCE period_seq;
CREATE SEQUENCE fitness_video_seq;
CREATE SEQUENCE review_seq;
CREATE SEQUENCE prize_seq;
CREATE SEQUENCE competition_seq;
CREATE SEQUENCE match_seq;
CREATE SEQUENCE value_change_seq;


--INDEXES
--Replace this with your index creations.

CREATE INDEX period_account_id_index ON Period(account_id);
CREATE INDEX goal_account_id_index ON Goal(account_id);
CREATE INDEX account_group_id_index ON Account(group_id);
CREATE INDEX review_account_id_index ON Review(account_id);
CREATE INDEX review_vedio_id_index ON Review(vedio_id);
CREATE INDEX match_competition_id_index ON Match(competition_id);
CREATE INDEX competition_prize_id_index ON Competition(prize_id);
CREATE INDEX goal_date_index ON Goal(date);
CREATE INDEX match_winner_index ON Match(winner);
CREATE INDEX focus_is_one_pomo_index ON Focus(is_one_pomo);
CREATE UNIQUE INDEX account_account_name_index ON Account(account_name);
CREATE UNIQUE INDEX accountgroup_group_name_index ON AccountGroup(group_name);
CREATE UNIQUE INDEX prize_prize_name_index ON Prize(prize_name);
CREATE UNIQUE INDEX competition_competition_name_index ON Competition(competition_name);

--STORED PROCEDURES
-- Insert new Focus period
CREATE OR REPLACE PROCEDURE insert_focus_period(v_account_name VARCHAR(16),v_start_time TIMESTAMP,
v_end_time TIMESTAMP,v_focus_label VARCHAR(64))
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_one_pomo BOOLEAN;
    v_duration_seconds INTEGER;
    v_account_id DECIMAL(12);
BEGIN
    -- Parameter Validation
    IF v_account_name IS NULL OR v_start_time IS NULL OR v_end_time IS NULL OR v_focus_label IS NULL THEN
        RAISE EXCEPTION 'All parameters must be provided';
    END IF;
    -- Calculate the duration in seconds
    v_duration_seconds := EXTRACT(EPOCH FROM (v_end_time - v_start_time));    
    -- Check if the duration is exactly 25 minutes (1500 seconds)
    IF v_duration_seconds = 1500 THEN
        v_is_one_pomo := TRUE;
    ELSE
        v_is_one_pomo := FALSE;
    END IF;
    -- Get the account_id using account_name
    SELECT INTO v_account_id account_id FROM Account WHERE account_name = v_account_name;
    IF v_account_id IS NULL THEN
        RAISE EXCEPTION 'Account with the given name does not exist';
    END IF;
    -- Insert the focus period record
    INSERT INTO Period(period_id, account_id, start_time, end_time, period_type)
    VALUES (NEXTVAL('period_seq'), v_account_id, v_start_time, v_end_time, 'focus');
    -- Insert the focus record
    INSERT INTO Focus(period_id, is_one_pomo, focus_label)
    VALUES (CURRVAL('period_seq'), v_is_one_pomo, v_focus_label);
END;
$$;

-- Insert new Rest period
CREATE OR REPLACE PROCEDURE insert_rest_period(
    v_account_name VARCHAR(16),
    v_start_time TIMESTAMP,
    v_end_time TIMESTAMP,
    v_is_workout BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id DECIMAL(12);
BEGIN
    -- Parameter Validation
    IF v_account_name IS NULL OR v_start_time IS NULL OR v_end_time IS NULL THEN
        RAISE EXCEPTION 'All parameters (account_name, start_time, and end_time) must be provided';
    END IF;    
    -- Get the account_id using account_name
    SELECT INTO v_account_id account_id FROM Account WHERE account_name = v_account_name;
    IF v_account_id IS NULL THEN
        RAISE EXCEPTION 'Account with the given name does not exist';
    END IF;
    -- Insert the rest period record
    INSERT INTO Period(period_id, account_id, start_time, end_time, period_type)
    VALUES (NEXTVAL('period_seq'), v_account_id, v_start_time, v_end_time, 'rest');
    -- Insert the rest record
    INSERT INTO Rest(period_id, is_workout)
    VALUES (CURRVAL('period_seq'), v_is_workout);
    
END
$$;


-- Insert new Stretch video
CREATE OR REPLACE PROCEDURE insert_stretch_video(
    v_video_address VARCHAR,
    v_body_part VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE 
    new_video_id DECIMAL;
BEGIN
    -- Get new vedio_id from the sequence
    new_video_id := NEXTVAL('fitness_video_seq');

    INSERT INTO Fitness_video(vedio_id, vedio_address, vedio_type)
    VALUES (new_video_id, v_video_address, 'Stretch');

    INSERT INTO Stretch(vedio_id, body_part)
    VALUES (new_video_id, v_body_part);
END;
$$;

-- Insert new Workout video
CREATE OR REPLACE PROCEDURE insert_workout_video(
    v_video_address VARCHAR,
    v_intensity INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE 
    new_video_id DECIMAL;
BEGIN
    -- Get new vedio_id from the sequence
    new_video_id := NEXTVAL('fitness_video_seq');

    INSERT INTO Fitness_video(vedio_id, vedio_address, vedio_type)
    VALUES (new_video_id, v_video_address, 'Workout');

    INSERT INTO Workout(vedio_id, intensity)
    VALUES (new_video_id, v_intensity);
END;
$$;

-- Create a trigger on table focus to update the total_pomos in table AccountGroup  
CREATE OR REPLACE FUNCTION update_total_pomos()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id DECIMAL(12);
    v_total_pomos INTEGER;
BEGIN
    -- Get the group_id associated with the inserted Focus row
    SELECT group_id INTO v_group_id FROM Account 
	WHERE account_id = (SELECT account_id from Period WHERE period_id=New.period_id);
    -- Calculate the total count of Focus rows with is_one_pomo equal to 1
    SELECT COUNT(*) INTO v_total_pomos 
	FROM Focus 
	JOIN Period on Period.period_id=Focus.period_id
	JOIN Account on Period.account_id=Account.account_id
	GROUP BY Account.group_id,Focus.is_one_pomo
    HAVING group_id = v_group_id AND is_one_pomo = TRUE;
    -- Update the total_pomos field in the relevant group of the AccountGroup table
    UPDATE AccountGroup SET total_pomos = v_total_pomos WHERE group_id = v_group_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Create a trigger to fire when inserting new rows into the Focus table
CREATE TRIGGER focus_insert_trigger
AFTER INSERT ON Focus
FOR EACH ROW
EXECUTE FUNCTION update_total_pomos();

--INSERTS
--Replace this with the inserts necessary to populate your tables.
--Some of these inserts will come from executing the stored procedures.

-- Insert five records into AccountGroup
INSERT INTO AccountGroup(group_id, group_name, creation_date, group_description)
VALUES (NEXTVAL('accountgroup_seq'), 'Study Group 1', '2023-09-30', 'Together, we achieve more. Let''s conquer our academic challenges!');

INSERT INTO AccountGroup(group_id, group_name, creation_date, group_description)
VALUES (NEXTVAL('accountgroup_seq'), 'Study Group 2', '2023-09-29', 'Persistence guarantees that results are inevitable. Keep going!');

INSERT INTO AccountGroup(group_id, group_name, creation_date, group_description)
VALUES (NEXTVAL('accountgroup_seq'), 'Study Group 3', '2023-09-28', 'Every study session is a step closer to success. Stay focused!');

INSERT INTO AccountGroup(group_id, group_name, creation_date, group_description)
VALUES (NEXTVAL('accountgroup_seq'), 'Study Group 4', '2023-09-27', 'Knowledge is power, and we are its seekers. Let''s empower ourselves!');

INSERT INTO AccountGroup(group_id, group_name, creation_date, group_description)
VALUES (NEXTVAL('accountgroup_seq'), 'Study Group 5', '2023-09-26', 'Dedication and hard work are the keys to success. Let''s unlock our potential together!');


-- Insert 16 records into Account with each group having 3 members
-- For Study Group 1
INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 1'), 'Alice', 'alice@email.com', '2023-09-25');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 1'), 'Bob', 'bob@email.com', '2023-09-24');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 1'), 'Charlie', 'charlie@email.com', '2023-09-23');

-- For Study Group 2
INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 2'), 'David', 'david@email.com', '2023-09-22');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 2'), 'Eva', 'eva@email.com', '2023-09-21');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 2'), 'Frank', 'frank@email.com', '2023-09-20');

-- For Study Group 3
INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 3'), 'Grace', 'grace@email.com', '2023-09-19');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 3'), 'Hugo', 'hugo@email.com', '2023-09-18');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 3'), 'Ivy', 'ivy@email.com', '2023-09-17');

-- For Study Group 4
INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 4'), 'Jack', 'jack@email.com', '2023-09-16');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 4'), 'Kara', 'kara@email.com', '2023-09-15');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 4'), 'Leo', 'leo@email.com', '2023-09-14');

-- For Study Group 5
INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 5'), 'Mia', 'mia@email.com', '2023-09-13');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 5'), 'Nate', 'nate@email.com', '2023-09-12');

INSERT INTO Account(account_id, group_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 5'), 'Olivia', 'olivia@email.com', '2023-09-11');
--For not join the Group
INSERT INTO Account(account_id, account_name, email, member_since)
VALUES (NEXTVAL('account_seq'), 'Paul', 'paul@email.com', '2023-09-10');


-- Insert a goal for each group member for one day use
-- Insert goals for Alice
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Alice'), '2023-10-02', 2);

-- Insert goals for Bob
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Bob'), '2023-10-03', 3);

-- Insert goals for Charlie
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Charlie'), '2023-10-04', 1);

-- Insert goals for David
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'David'), '2023-10-05', 2);

-- Insert goals for Eva
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Eva'), '2023-10-06', 3);

-- Insert goals for Frank
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Frank'), '2023-10-07', 4);

-- Insert goals for Grace
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Grace'), '2023-10-08', 2);

-- Insert goals for Hugo
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Hugo'), '2023-10-02', 3);

-- Insert goals for Ivy
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Ivy'), '2023-10-03', 1);

-- Insert goals for Jack
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Jack'), '2023-10-04', 2);

-- Insert goals for Kara
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Kara'), '2023-10-05', 3);

-- Insert goals for Leo
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Leo'), '2023-10-06', 4);

-- Insert goals for Mia
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Mia'), '2023-10-07', 2);

-- Insert goals for Nate
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Nate'), '2023-10-08', 3);

-- Insert goals for Olivia
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Olivia'), '2023-10-02', 1);

-- Insert goals for Paul
INSERT INTO Goal(goal_id, account_id, date, goal)
VALUES (NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-02', 1),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-03', 2),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-04', 3),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-05', 1),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-06', 2),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-07', 3),
(NEXTVAL('goal_seq'), (SELECT account_id FROM Account WHERE account_name = 'Paul'), '2023-10-08', 1);

--Insert focus period and rest period for each group member
--Insert Focus and Rest records for Alice
START TRANSACTION;
-- Focus record 1
DO 
$$BEGIN
   CALL insert_focus_period('Alice', '2023-10-02 08:00:00', '2023-10-02 08:25:00', 'Study');
END$$;
-- Rest record 1
DO 
$$BEGIN
   CALL insert_rest_period('Alice', '2023-10-02 08:25:00', '2023-10-02 08:30:00', false);
END$$;
-- Focus record 2
DO 
$$BEGIN
   CALL insert_focus_period('Alice', '2023-10-02 08:30:00', '2023-10-02 08:55:00', 'Work');
END$$;
-- Rest record 2
DO 
$$BEGIN
   CALL insert_rest_period('Alice', '2023-10-02 08:55:00', '2023-10-02 09:00:00', true);
END$$;
-- Focus record 3
DO 
$$BEGIN
   CALL insert_focus_period('Alice', '2023-10-02 09:00:00', '2023-10-02 09:25:00', 'Reading');
END$$;
-- Commit the transaction
COMMIT;

-- Insert Focus and Rest period records for Bob
START TRANSACTION;
-- Focus record 1
DO 
$$BEGIN
   CALL insert_focus_period('Bob', '2023-10-03 08:00:00', '2023-10-03 08:25:00', 'Study');
END$$;
-- Rest record 1
DO 
$$BEGIN
   CALL insert_rest_period('Bob', '2023-10-03 08:25:00', '2023-10-03 08:30:00', false);
END$$;
-- Focus record 2
DO 
$$BEGIN
   CALL insert_focus_period('Bob', '2023-10-03 08:30:00', '2023-10-03 08:55:00', 'Study');
END$$;
-- Rest record 2
DO 
$$BEGIN
   CALL insert_rest_period('Bob', '2023-10-03 08:55:00', '2023-10-03 09:00:00', true);
END$$;
-- Focus record 3
DO 
$$BEGIN
   CALL insert_focus_period('Bob', '2023-10-03 09:00:00', '2023-10-03 09:25:00', 'Study');
END$$;
-- Rest record 3
DO 
$$BEGIN
   CALL insert_rest_period('Bob', '2023-10-03 09:25:00', '2023-10-03 09:30:00', false);
END$$;
-- Focus record 4
DO 
$$BEGIN
   CALL insert_focus_period('Bob', '2023-10-03 09:30:00', '2023-10-03 09:50:00', 'Study');
END$$;
-- Rest record 4
DO 
$$BEGIN
   CALL insert_rest_period('Bob', '2023-10-03 09:50:00', '2023-10-03 10:10:00', true);
END$$;
-- Focus record 5
DO 
$$BEGIN
   CALL insert_focus_period('Bob', '2023-10-03 10:10:00', '2023-10-03 10:35:00', 'Study');
END$$;
-- Rest record 5
DO 
$$BEGIN
   CALL insert_rest_period('Bob', '2023-10-03 10:35:00', '2023-10-03 10:40:00', true);
END$$;
-- Commit the transaction
COMMIT;

-- Insert Focus and Rest period records for Charlie
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Charlie', '2023-10-04 08:00:00', '2023-10-04 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Charlie', '2023-10-04 08:25:00', '2023-10-04 08:30:00', true);
END$$;
-- Commit the transaction
COMMIT;

-- Insert Focus and Rest period records for David
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('David', '2023-10-05 09:00:00', '2023-10-05 09:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('David', '2023-10-05 09:25:00', '2023-10-05 09:30:00', false);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('David', '2023-10-05 09:30:00', '2023-10-05 09:55:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('David', '2023-10-05 09:55:00', '2023-10-05 10:00:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('David', '2023-10-05 10:00:00', '2023-10-05 10:25:00', 'Study');
END$$;
COMMIT;

-- Insert Focus and Rest period records for Eva
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Eva', '2023-10-06 09:00:00', '2023-10-06 09:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Eva', '2023-10-06 09:25:00', '2023-10-06 09:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Frank
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Frank', '2023-10-07 10:00:00', '2023-10-07 10:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Frank', '2023-10-07 10:25:00', '2023-10-07 10:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Grace
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Grace', '2023-10-08 14:00:00', '2023-10-08 14:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Grace', '2023-10-08 14:25:00', '2023-10-08 14:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Hugo
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Hugo', '2023-10-02 08:00:00', '2023-10-02 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Hugo', '2023-10-02 08:25:00', '2023-10-02 08:30:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Hugo', '2023-10-02 10:00:00', '2023-10-02 10:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Hugo', '2023-10-02 10:25:00', '2023-10-02 10:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Ivy
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Ivy', '2023-10-03 08:00:00', '2023-10-03 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Ivy', '2023-10-03 08:25:00', '2023-10-03 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Jack
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Jack', '2023-10-04 08:00:00', '2023-10-04 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Jack', '2023-10-04 08:25:00', '2023-10-04 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Kara
START TRANSACTION;
DO
$$BEGIN
   CALL insert_focus_period('Kara', '2023-10-05 08:00:00', '2023-10-05 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Kara', '2023-10-05 08:25:00', '2023-10-05 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Leo
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Leo', '2023-10-06 08:00:00', '2023-10-06 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Leo', '2023-10-06 08:25:00', '2023-10-06 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Mia
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Mia', '2023-10-07 08:00:00', '2023-10-07 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Mia', '2023-10-07 08:25:00', '2023-10-07 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Nate
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_focus_period('Nate', '2023-10-08 08:00:00', '2023-10-08 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Nate', '2023-10-08 08:25:00', '2023-10-08 08:30:00', true);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Olivia
START TRANSACTION;
DO
$$BEGIN
   CALL insert_focus_period('Olivia', '2023-10-02 08:00:00', '2023-10-02 08:25:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Olivia', '2023-10-02 08:25:00', '2023-10-02 08:30:00', false);
END$$;
DO
$$BEGIN
   CALL insert_focus_period('Olivia', '2023-10-02 08:30:00', '2023-10-02 08:55:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Olivia', '2023-10-02 08:55:00', '2023-10-02 09:00:00', true);
END$$;
DO
$$BEGIN
   CALL insert_focus_period('Olivia', '2023-10-02 09:00:00', '2023-10-02 09:25:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Olivia', '2023-10-02 09:25:00', '2023-10-02 09:30:00', false);
END$$;
COMMIT;

-- Insert Focus and Rest period records for Paul
START TRANSACTION;
DO
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-02 08:00:00', '2023-10-02 08:25:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-02 08:25:00', '2023-10-02 08:30:00', false);
END$$;
DO
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-02 08:30:00', '2023-10-02 08:55:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-02 08:55:00', '2023-10-02 09:00:00', true);
END$$;
DO
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-02 09:00:00', '2023-10-02 09:25:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-02 09:25:00', '2023-10-02 09:30:00', false);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-03 08:00:00', '2023-10-03 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-03 08:25:00', '2023-10-03 08:30:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-04 08:00:00', '2023-10-04 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-04 08:25:00', '2023-10-04 08:30:00', true);
END$$;
START TRANSACTION;
DO
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-05 08:00:00', '2023-10-05 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-05 08:25:00', '2023-10-05 08:30:00', true);
END$$;
DO
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-05 08:30:00', '2023-10-05 08:55:00', 'Study');
END$$;
DO
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-05 08:55:00', '2023-10-05 09:00:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-06 08:00:00', '2023-10-06 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-06 08:25:00', '2023-10-06 08:30:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-07 08:00:00', '2023-10-07 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-07 08:25:00', '2023-10-07 08:30:00', true);
END$$;
DO 
$$BEGIN
   CALL insert_focus_period('Paul', '2023-10-08 08:00:00', '2023-10-08 08:25:00', 'Study');
END$$;
DO 
$$BEGIN
   CALL insert_rest_period('Paul', '2023-10-08 08:25:00', '2023-10-08 08:30:00', true);
END$$;
COMMIT;

-- Insert five Stretch videos and their reivews
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_stretch_video('https://www.youtube.com/watch?v=UYfHWsuxe50', 'upper body');
END$$;
COMMIT TRANSACTION;
--Review of this video
INSERT INTO Review(review_id, account_id, vedio_id, like_dislike, comment, review_date)
VALUES (NEXTVAL('review_seq'), (SELECT account_id FROM Account WHERE account_name = 'Alice'), 
		CURRVAL('fitness_video_seq'), true, 'This video is great!', '2023-10-02');

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_stretch_video('https://www.youtube.com/watch?v=D_x1fPDZm_A', 'lower body');
END$$;
COMMIT TRANSACTION;
--Review of this video
INSERT INTO Review(review_id, account_id, vedio_id, like_dislike, comment, review_date)
VALUES (NEXTVAL('review_seq'), (SELECT account_id FROM Account WHERE account_name = 'Charlie'), 
		CURRVAL('fitness_video_seq'), true, 'I liked this video', '2023-10-04');
		
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_stretch_video('https://www.youtube.com/watch?v=Ef6LwAaB3_E', 'full body');
END$$;
COMMIT TRANSACTION;
--Review of this video
INSERT INTO Review(review_id, account_id, vedio_id, like_dislike, comment, review_date)
VALUES (NEXTVAL('review_seq'), (SELECT account_id FROM Account WHERE account_name = 'Eva'), 
		CURRVAL('fitness_video_seq'), false, 'I disliked this video', '2023-10-06');

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_stretch_video('https://www.youtube.com/watch?v=sAf67xFS-qE', 'full body');
END$$;
COMMIT TRANSACTION;
----Review of this video
INSERT INTO Review(review_id, account_id, vedio_id, like_dislike, comment, review_date)
VALUES (NEXTVAL('review_seq'), (SELECT account_id FROM Account WHERE account_name = 'Frank'), 
		CURRVAL('fitness_video_seq'), true, 'I liked this video', '2023-10-07');

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_stretch_video('https://www.youtube.com/watch?v=gfzC9XMEypg', 'full body');
END$$;
COMMIT TRANSACTION;

-- Insert five Workout videos and their reviews
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_workout_video('https://www.youtube.com/watch?v=x3aogIZfVUI', 1);
END$$;
COMMIT TRANSACTION;

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_workout_video('https://www.youtube.com/watch?v=UBMk30rjy0o', 2);
END$$;
COMMIT TRANSACTION;

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_workout_video('https://www.youtube.com/watch?v=hLVh5IBsCxk', 3);
END$$;
COMMIT TRANSACTION;
--Review of this video
INSERT INTO Review(review_id, account_id, vedio_id, like_dislike, comment, review_date)
VALUES (NEXTVAL('review_seq'), (SELECT account_id FROM Account WHERE account_name = 'Bob'), 
		CURRVAL('fitness_video_seq'), false, 'I didn''t like this video', '2023-10-07');
		
START TRANSACTION;
DO 
$$BEGIN
   CALL insert_workout_video('https://www.youtube.com/watch?v=6Bjtq2A_jwg', 3);
END$$;
COMMIT TRANSACTION;

START TRANSACTION;
DO 
$$BEGIN
   CALL insert_workout_video('https://www.youtube.com/watch?v=J4wm6qiv5pI', 3);
END$$;
COMMIT TRANSACTION;

--Insert five prizes
INSERT INTO Prize(prize_id, prize_name, prize_description, prize_value)
VALUES (NEXTVAL('prize_seq'), 'Coffee Gift Card', 'A gift card for a popular coffee shop', 25.00);

INSERT INTO Prize(prize_id, prize_name, prize_description, prize_value)
VALUES (NEXTVAL('prize_seq'), 'Bookstore Voucher', 'A voucher for a local bookstore', 40.00);

INSERT INTO Prize(prize_id, prize_name, prize_description, prize_value)
VALUES (NEXTVAL('prize_seq'), 'Movie Tickets', 'Tickets for a night out at the movies', 30.00);

INSERT INTO Prize(prize_id, prize_name, prize_description, prize_value)
VALUES (NEXTVAL('prize_seq'), 'Gift Card', 'A $25 gift card', 25.00);

INSERT INTO Prize(prize_id, prize_name, prize_description, prize_value)
VALUES (NEXTVAL('prize_seq'), 'T-Shirt', 'Official event T-shirt', 15.00);

--Insert five competetion information
INSERT INTO Competition(competition_id, prize_id, competition_name, competition_description, start_date, end_date)
VALUES (NEXTVAL('competition_seq'), (SELECT prize_id FROM Prize WHERE prize_name = 'Coffee Gift Card'),
		'Competition 1', 'Description 1', '2023-10-2', '2023-10-5');

INSERT INTO Competition(competition_id, prize_id, competition_name, competition_description, start_date, end_date)
VALUES (NEXTVAL('competition_seq'), (SELECT prize_id FROM Prize WHERE prize_name = 'Bookstore Voucher'), 
		'Competition 2', 'Description 2', '2023-10-6', '2023-10-8');

INSERT INTO Competition(competition_id, prize_id, competition_name, competition_description, start_date, end_date)
VALUES (NEXTVAL('competition_seq'), (SELECT prize_id FROM Prize WHERE prize_name = 'Movie Tickets'), 
		'Competition 3', 'Description 3', '2023-10-9', '2023-10-11');

INSERT INTO Competition(competition_id, prize_id, competition_name, competition_description, start_date, end_date)
VALUES (NEXTVAL('competition_seq'), (SELECT prize_id FROM Prize WHERE prize_name = 'Gift Card'), 
		'Competition 4', 'Description 4', '2023-10-12', '2023-10-14');

INSERT INTO Competition(competition_id, prize_id, competition_name, competition_description, start_date, end_date)
VALUES (NEXTVAL('competition_seq'), (SELECT prize_id FROM Prize WHERE prize_name = 'T-Shirt'), 
		'Competition 5', 'Description 5', '2023-10-15', '2023-10-18');

--Insert six match records of three competition
--Match between group1 and group2 in competetion1
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (NEXTVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 1'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 1'),8,true);
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (CURRVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 2'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 1'),3,false);
--Match between group3 and group4 in competetion1
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (NEXTVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 3'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 1'),3,true);
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (CURRVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 4'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 1'),2,false);
--Match between group1 and group5 in competetion2
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (NEXTVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 5'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 2'),2,true);
INSERT INTO Match (match_id, group_id,competition_id, group_pomos, winner)
VALUES (CURRVAL('match_seq'), (SELECT group_id FROM AccountGroup WHERE group_name = 'Study Group 1'), 
		(SELECT competition_id FROM Competition WHERE competition_name = 'Competition 2'),0,false);

--TRIGGERS
--Replace this with your history table trigger.
CREATE OR REPLACE FUNCTION value_change_history()
RETURNS TRIGGER AS $$
BEGIN
INSERT INTO Value_change
VALUES (nextval('value_change_seq'),NEW.prize_id,OLD.prize_value,NEW.prize_value,current_date);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER value_change_trigger
BEFORE UPDATE OF prize_value ON Prize
FOR EACH ROW
EXECUTE FUNCTION value_change_history();

SELECT * FROM Prize;

UPDATE Prize
SET prize_value=20
WHERE prize_name='Coffee Gift Card';

SELECT * FROM Value_change;

--QUERIES
--Replace this with your queries.

--Q:What is the winner information for each match
SELECT g.group_name AS match_winner, c.competition_name,
c.start_date, c.end_date, m.group_pomos AS scores, p.prize_name
From AccountGroup AS g
JOIN Match AS m ON g.group_id=m.group_id
JOIN Competition AS c ON m.competition_id=c.competition_id
JOIN Prize AS p ON c.prize_id=p.prize_id
WHERE m.winner=true;

--Q:How are the reviews for different types of fitness videos?
SELECT a.account_name,r.like_dislike,r.comment,
f.vedio_address,s.body_part AS stretch_type,w.intensity AS workout_intensity
FROM Account AS a
JOIN Review AS r ON a.account_id=r.account_id
JOIN Fitness_video AS f ON f.vedio_id=r.vedio_id
LEFT JOIN Stretch AS s ON f.vedio_id=s.vedio_id
left JOIN Workout AS w ON f.vedio_id=w.vedio_id;


--Q:Has the user achieved their goals set for each time?
CREATE OR REPLACE VIEW GoalAchievement AS
WITH PomosCount AS (
    SELECT
        a.account_name,
        g.goal,
        g.date,
        COUNT(*) AS today_pomos
    FROM Focus AS f
    LEFT JOIN Period AS p ON f.period_id = p.period_id
    JOIN Account AS a ON p.account_id = a.account_id
    JOIN Goal AS g ON g.account_id = a.account_id
    WHERE f.is_one_pomo = true AND DATE(p.end_time) = g.date
    GROUP BY a.account_name, g.goal, g.date)

SELECT
    pc.account_name,
    pc.goal,
    pc.date,
    pc.today_pomos,
    CASE
        WHEN pc.today_pomos >= pc.goal THEN 'Yes'
        ELSE 'No'
    END AS goal_achieved
FROM PomosCount AS pc;
--show all information in GoalAchievement
SELECT * FROM GoalAchievement
ORDER BY account_name,date;
--show all information of Bob in GoalAchievement
SELECT * FROM GoalAchievement
WHERE account_name='Bob';
--show all information of who completed the goal
SELECT * FROM GoalAchievement
WHERE goal_achieved='Yes';

--Paul's weekly performance
SELECT * FROM GoalAchievement
WHERE account_name='Paul' AND date<='2023-10-08' AND date>='2023-10-02'
ORDER BY date;

--Group1's weekly performance
SELECT a.account_name,a.group_id,COUNT(*) AS weekly_pomos
FROM Focus AS f
LEFT JOIN Period AS p ON f.period_id = p.period_id
JOIN Account AS a ON p.account_id = a.account_id
WHERE f.is_one_pomo = true AND 
	  DATE(p.end_time)<='2023-10-08' AND DATE(p.end_time)>='2023-10-02' AND
	  a.group_id=1
GROUP BY a.account_name, a.group_id;