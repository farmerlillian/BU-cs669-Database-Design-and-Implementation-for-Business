# BU-CS669-Database-Design-and-Implementation-for-Business Final Project

## Overview

This project repository contains the database design and implementation for the "Pomodoro-Workout Clock," initially developed during my CS521 course. The Pomodoro Technique, combined with workout sessions, forms the core of this application, designed to enhance productivity and physical well-being during work breaks. 

## Database Features

- **Multiple Accounts Support**: Allows individual tracking and progress monitoring for numerous users.
- **Group Creation**: Users can form groups for mutual motivation and support.
- **Lucky Draw Participation**: Engages users with rewards after every 10 Pomodoros to encourage consistent usage.
- **Competition Among Groups**: Facilitates friendly competitions with rewards to boost group engagement.
- **Comprehensive Statistics**: Displays detailed records such as daily, weekly, and monthly study or workout times, goal achievements, and consistency in focus.
- **Content Management**: Simplifies the process of updating workout videos and motivational quotes.

## Application Usage

- Upon installation, users register or log in, set daily Pomodoro goals, and start their focused work sessions.
- Breaks allow users to choose between resting or following a workout/stretching video.
- Post-session, the app displays an encouraging quote, and users can review their focus and exercise records.
- Group functionalities include motivation through shared goals and participation in competitions for rewards.

## Database Design

- The database stores user information, usage records (focus, workout, rest times), and goals.
- It categorizes time usage into focus and rest periods and includes a hierarchy for fitness videos (stretch and workout types).
- The design employs synthetic keys for best practices and supports the application with necessary attributes.

## Implementation

- SQL scripts for table creation align with the DBMS physical ERD specifications.
- Indexes enhance database access speed, with stored procedures populating the database transactionally.
- Queries for useful insights and visualizations are implemented, showcasing the database's capability to support the Pomodoro-Workout Clock app.



