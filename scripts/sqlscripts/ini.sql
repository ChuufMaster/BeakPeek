CREATE DATABASE MyDatabase;
USE MyDatabase;

CREATE TABLE MyTable (
    Id INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(100) NOT NULL
);

INSERT INTO MyTable (Name) VALUES ('Sample Data');