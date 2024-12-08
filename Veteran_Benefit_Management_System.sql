set search_path to veteran_db;

/* ---DDL--- */
-- Drop Views
DROP VIEW v_veteran_contact_info CASCADE;
DROP VIEW v_veteran_benefit_application_status CASCADE;
DROP VIEW v_veteran_claims CASCADE;
DROP VIEW v_veteran_medical_records CASCADE;
DROP VIEW v_veteran_benefit_summary CASCADE;

-- Drop Triggers
DROP TRIGGER trg_contact_info ON Contact_Info;
DROP TRIGGER TRG_Veteran ON Veteran;
DROP TRIGGER TRG_Benefit_Type ON Benefit_Type;
DROP TRIGGER TRG_Benefit_Application ON Benefit_Application;
DROP TRIGGER TRG_Claim ON Claim;
DROP TRIGGER TRG_Medical_Record ON Medical_Record;

-- Drop Indices
DROP INDEX IDX_Veteran_Name;
DROP INDEX IDX_Contact_Info_Email;
DROP INDEX IDX_Benefit_Application_Status;
DROP INDEX IDX_Claim_Status;

-- Drop Tables
DROP TABLE Contact_Info CASCADE;
DROP TABLE Veteran CASCADE;
DROP TABLE Benefit_Type CASCADE;
DROP TABLE Benefit_Application CASCADE;
DROP TABLE Claim CASCADE;
DROP TABLE Medical_Record CASCADE;

-- Drop Sequences
DROP SEQUENCE seq_contact_info_id CASCADE;
DROP SEQUENCE seq_veteran_id CASCADE;
DROP SEQUENCE seq_benefit_type_id CASCADE;
DROP SEQUENCE seq_application_id CASCADE;
DROP SEQUENCE seq_claim_id CASCADE;
DROP SEQUENCE seq_medical_record_id CASCADE;

/* CONTACT_INFO Table */
CREATE TABLE Contact_Info (
    Contact_Info_ID          INTEGER       PRIMARY KEY,
    Veteran_ID               INTEGER       NOT NULL,
    Address                  VARCHAR(255) NOT NULL,
    City                     VARCHAR(100) NOT NULL,
    State                    CHAR(2)       NOT NULL,
    Postal_Code              VARCHAR(10)  NOT NULL,
    Phone_Number             VARCHAR(15),
    Email                    VARCHAR(100) NOT NULL
);

/* VETERAN Table */
CREATE TABLE Veteran (
    Veteran_ID               INTEGER       PRIMARY KEY,
    First_Name               VARCHAR(50) NOT NULL,
    Last_Name                VARCHAR(50) NOT NULL,
    Date_of_Birth            DATE         NOT NULL,
    Social_Security_Number   CHAR(11)     NOT NULL,
    Service_Branch           VARCHAR(50) NOT NULL,
    Discharge_Status         VARCHAR(50) NOT NULL,
    Contact_Info_ID          INTEGER,
    CONSTRAINT FK_Veteran_Contact_Info_ID FOREIGN KEY (Contact_Info_ID) REFERENCES Contact_Info(Contact_Info_ID)
);

/* BENEFIT_TYPE Table */
CREATE TABLE Benefit_Type (
    Benefit_Type_ID          INTEGER       PRIMARY KEY,
    Benefit_Name             VARCHAR(100) NOT NULL,
    Description              VARCHAR(255),
    Eligibility_Criteria     VARCHAR(255),
    Benefit_Category         VARCHAR(50) NOT NULL
);

/* BENEFIT_APPLICATION Table */
CREATE TABLE Benefit_Application (
    Application_ID           INTEGER       PRIMARY KEY,
    Veteran_ID               INTEGER       NOT NULL,
    Application_Date         DATE         NOT NULL,
    Benefit_Type             VARCHAR(50) NOT NULL,
    Benefit_Type_ID          INTEGER,
    Status                   VARCHAR(20) NOT NULL,
    Decision_Date            DATE,
    CONSTRAINT FK_Benefit_Application_Veteran_ID FOREIGN KEY (Veteran_ID) REFERENCES Veteran(Veteran_ID),
    CONSTRAINT FK_Benefit_Application_Benefit_Type_ID FOREIGN KEY (Benefit_Type_ID) REFERENCES Benefit_Type(Benefit_Type_ID)
);

/* CLAIM Table */
CREATE TABLE Claim (
    Claim_ID                 INTEGER       PRIMARY KEY,
    Application_ID           INTEGER       NOT NULL,
    Claim_Type               VARCHAR(50) NOT NULL,
    Claim_Date               DATE         NOT NULL,
    Claim_Status             VARCHAR(20) NOT NULL,
    Decision_Date            DATE,
    Amount_Awarded           DECIMAL(10,2),
    CONSTRAINT FK_Claim_Application_ID FOREIGN KEY (Application_ID) REFERENCES Benefit_Application(Application_ID)
);

/* MEDICAL_RECORD Table */
CREATE TABLE Medical_Record (
    Medical_Record_ID        INTEGER       PRIMARY KEY,
    Veteran_ID               INTEGER       NOT NULL,
    Record_Date              DATE         NOT NULL,
    Diagnosis                VARCHAR(255),
    Service_Related          CHAR(3)      CHECK (Service_Related IN ('Yes', 'No')),
    Treatment_Details        VARCHAR(255),
    CONSTRAINT FK_Medical_Record_Veteran_ID FOREIGN KEY (Veteran_ID) REFERENCES Veteran(Veteran_ID)
);

--INDEXES
-- Index for Veteran Name
CREATE INDEX IDX_Veteran_Name ON Veteran (First_Name, Last_Name);

-- Index for Contact_Info Email
CREATE INDEX IDX_Contact_Info_Email ON Contact_Info (Email);

-- Index for Benefit_Application Status
CREATE INDEX IDX_Benefit_Application_Status ON Benefit_Application (Status);

-- Index for Claim Status
CREATE INDEX IDX_Claim_Status ON Claim (Claim_Status);

--ALTER TABLES
--Alter Contact_Info Table
ALTER TABLE Contact_Info
ADD CONSTRAINT CHK_Contact_Info_ID_Range CHECK (Contact_Info_ID BETWEEN 1 AND 1000000),
ADD UNIQUE (Email);

--Alter Veteran Table
ALTER TABLE Veteran
ADD CONSTRAINT CHK_Veteran_ID_Range CHECK (Veteran_ID BETWEEN 1 AND 1000000),
ADD CONSTRAINT UNIQUE_SSN UNIQUE (Social_Security_Number), 
ALTER COLUMN Contact_Info_ID SET NOT NULL; 

--Alter Benefit_Type Table
ALTER TABLE Benefit_Type
ALTER COLUMN Eligibility_Criteria SET DATA TYPE TEXT,
ALTER COLUMN Eligibility_Criteria SET NOT NULL;

--Alter Benefit_Application Table
ALTER TABLE Benefit_Application
ADD CONSTRAINT CHK_Status CHECK (Status IN ('Pending', 'Approved', 'Denied'));

--Alter Claim Table
ALTER TABLE Claim
ADD CONSTRAINT CHK_Claim_Status CHECK (Claim_Status IN ('Pending', 'Approved', 'Denied', 'Closed'));

--Alter Medical_Record Table
ALTER TABLE Medical_Record
ALTER COLUMN Diagnosis SET DATA TYPE TEXT,
ALTER COLUMN Diagnosis SET NOT NULL,
ALTER COLUMN Treatment_Details SET NOT NULL;

--VIEWS
--Veteran Contact Information View
CREATE VIEW v_veteran_contact_info AS
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, v.Date_of_Birth, v.Social_Security_Number, v.Service_Branch, v.Discharge_Status,
       c.Address, c.City, c.State, c.Postal_Code, c.Phone_Number, c.Email
FROM 
    Veteran v
JOIN 
    Contact_Info c ON v.Contact_Info_ID = c.Contact_Info_ID;

--Veteran Benefit Application Status View
CREATE VIEW v_veteran_benefit_application_status AS
SELECT v.Veteran_ID, v.First_Name, v.Last_Name,
       b.Application_ID, b.Application_Date, bt.Benefit_Name, b.Status AS Application_Status, b.Decision_Date
FROM 
    Veteran v
JOIN 
    Benefit_Application b ON v.Veteran_ID = b.Veteran_ID
JOIN 
    Benefit_Type bt ON b.Benefit_Type_ID = bt.Benefit_Type_ID;

--Veteran Claims View
CREATE VIEW v_veteran_claims AS
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, ba.Application_ID, ba.Application_Date,
       c.Claim_ID, c.Claim_Type, c.Claim_Date, c.Claim_Status, c.Amount_Awarded, c.Decision_Date
FROM 
    Veteran v
JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
JOIN 
    Claim c ON ba.Application_ID = c.Application_ID;

--Veteran Medical Records View
CREATE VIEW v_veteran_medical_records AS
SELECT v.Veteran_ID, v.First_Name, v.Last_Name,
       m.Medical_Record_ID, m.Record_Date, m.Diagnosis, m.Service_Related, m.Treatment_Details
FROM 
    Veteran v
JOIN 
    Medical_Record m ON v.Veteran_ID = m.Veteran_ID;

--Veteran Benefit Summary View
CREATE VIEW v_veteran_benefit_summary AS
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, bt.Benefit_Name, ba.Application_ID,
       ba.Application_Date, ba.Status AS Application_Status, c.Claim_ID, c.Claim_Type, c.Claim_Status, c.Amount_Awarded,
       m.Medical_Record_ID, m.Diagnosis, m.Service_Related
FROM 
    Veteran v
LEFT JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
LEFT JOIN 
    Benefit_Type bt ON ba.Benefit_Type_ID = bt.Benefit_Type_ID
LEFT JOIN 
    Claim c ON ba.Application_ID = c.Application_ID
LEFT JOIN 
    Medical_Record m ON v.Veteran_ID = m.Veteran_ID;

-- Sequence for Contact_Info table
CREATE SEQUENCE SEQ_Contact_Info_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

-- Sequence for Veteran table
CREATE SEQUENCE SEQ_Veteran_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

-- Sequence for Benefit_Type table
CREATE SEQUENCE SEQ_Benefit_Type_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

-- Sequence for Benefit_Application table
CREATE SEQUENCE SEQ_Application_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

-- Sequence for Claim table
CREATE SEQUENCE SEQ_Claim_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

-- Sequence for Medical_Record table
CREATE SEQUENCE SEQ_Medical_Record_ID
    INCREMENT BY 1
    START WITH 1
    MAXVALUE 10
    MINVALUE 1
    CYCLE;

/* Create Triggers */
/* Business purpose: The TRG_Contact_Info trigger automatically assigns a sequential Contact_Info_ID
to a newly-inserted row in the Contact_Info table. */
CREATE OR REPLACE FUNCTION trg_contact_info_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.contact_info_id IS NULL THEN
            NEW.contact_info_id := nextval('seq_contact_info_id'); -- Replace with the actual sequence name
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contact_info
BEFORE INSERT OR UPDATE ON contact_info
FOR EACH ROW
EXECUTE FUNCTION trg_contact_info_function();

/* Business purpose: The TRG_Veteran trigger automatically assigns a sequential Veteran_ID
to a newly-inserted row in the Veteran table and ensures consistency in the creation and modification tracking fields. */
CREATE OR REPLACE FUNCTION trg_veteran_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Veteran_ID IS NULL THEN
        NEW.Veteran_ID := nextval('SEQ_Veteran_ID');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Veteran
BEFORE INSERT ON Veteran
FOR EACH ROW
EXECUTE FUNCTION trg_veteran_id();

/* Business purpose: The TRG_Benefit_Type trigger automatically assigns a sequential Benefit_Type_ID 
to a newly-inserted row in the Benefit_Type table. */
CREATE OR REPLACE FUNCTION trg_benefit_type_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Benefit_Type_ID IS NULL THEN
        NEW.Benefit_Type_ID := nextval('SEQ_Benefit_Type_ID');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Benefit_Type
BEFORE INSERT ON Benefit_Type
FOR EACH ROW
EXECUTE FUNCTION trg_benefit_type_id();

/* Business purpose: The TRG_Benefit_Application trigger automatically assigns a sequential Application_ID 
to a newly-inserted row in the Benefit_Application table and ensures consistency in status values. */
CREATE OR REPLACE FUNCTION trg_application_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Application_ID IS NULL THEN
        NEW.Application_ID := nextval('SEQ_Application_ID');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Benefit_Application
BEFORE INSERT ON Benefit_Application
FOR EACH ROW
EXECUTE FUNCTION trg_application_id();

/* Business purpose: The TRG_Claim trigger automatically assigns a sequential Claim_ID 
to a newly-inserted row in the Claim table and enforces valid status values. */
CREATE OR REPLACE FUNCTION trg_claim_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Claim_ID IS NULL THEN
        NEW.Claim_ID := nextval('SEQ_Claim_ID');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Claim
BEFORE INSERT ON Claim
FOR EACH ROW
EXECUTE FUNCTION trg_claim_id();

/* Business purpose: The TRG_Medical_Record trigger automatically assigns a sequential Medical_Record_ID 
to a newly-inserted row in the Medical_Record table. */
CREATE OR REPLACE FUNCTION trg_medical_record_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Medical_Record_ID IS NULL THEN
        NEW.Medical_Record_ID := nextval('SEQ_Medical_Record_ID');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Medical_Record
BEFORE INSERT ON Medical_Record
FOR EACH ROW
EXECUTE FUNCTION trg_medical_record_id();

/* ---DML--- */
-- Insert into Contact_Info
INSERT INTO Contact_Info (Veteran_ID, Address, City, State, Postal_Code, Phone_Number, Email)
VALUES 
    (1, '123 Elm St', 'Dallas', 'TX', '75201', '1234567890', 'john.doe@gmail.com'),
    (2, '456 Oak St', 'Austin', 'TX', '73301', '2345678901', 'jane.smith@gmail.com'),
    (3, '789 Pine St', 'Houston', 'TX', '77001', '3456789012', 'robert.brown@gmail.com'),
    (4, '101 Maple St', 'San Antonio', 'TX', '78201', '4567890123', 'emily.johnson@gmail.com'),
    (5, '202 Cedar St', 'El Paso', 'TX', '79901', '5678901234', 'michael.williams@gmail.com'),
    (6, '303 Birch St', 'Fort Worth', 'TX', '76101', '6789012345', 'sarah.jones@gmail.com'),
    (7, '404 Walnut St', 'Arlington', 'TX', '76001', '7890123456', 'david.taylor@gmail.com'),
    (8, '505 Cherry St', 'Plano', 'TX', '75001', '8901234567', 'laura.moore@gmail.com'),
    (9, '606 Aspen St', 'Lubbock', 'TX', '79401', '9012345678', 'james.anderson@gmail.com'),
    (10, '707 Willow St', 'Irving', 'TX', '75039', '1234567899', 'linda.clark@gmail.com');

SELECT * FROM Contact_Info;

-- Insert into Veteran
INSERT INTO Veteran (First_Name, Last_Name, Date_of_Birth, Social_Security_Number, Service_Branch, Discharge_Status, Contact_Info_ID)
VALUES 
    ('John', 'Doe', '1980-01-01', '123-45-6789', 'Army', 'Honorably Discharged', 1),
    ('Jane', 'Smith', '1985-02-02', '234-56-7890', 'Navy', 'Honorably Discharged', 2),
    ('Robert', 'Brown', '1990-03-03', '345-67-8901', 'Marines', 'Honorably Discharged', 3),
    ('Emily', 'Johnson', '1975-04-04', '456-78-9012', 'Air Force', 'Honorably Discharged', 4),
    ('Michael', 'Williams', '1965-05-05', '567-89-0123', 'Army', 'Honorably Discharged', 5),
    ('Sarah', 'Jones', '1995-06-06', '678-90-1234', 'Navy', 'Dishonorably Discharged', 6),
    ('David', 'Taylor', '1988-07-07', '789-01-2345', 'Marines', 'Honorably Discharged', 7),
    ('Laura', 'Moore', '1979-08-08', '890-12-3456', 'Air Force', 'Honorably Discharged', 8),
    ('James', 'Anderson', '1982-09-09', '901-23-4567', 'Army', 'Honorably Discharged', 9),
    ('Linda', 'Clark', '1991-10-10', '012-34-5678', 'Navy', 'Honorably Discharged', 10);

SELECT * FROM Veteran;

-- Insert into Benefit_Type
INSERT INTO Benefit_Type (Benefit_Name, Description, Eligibility_Criteria, Benefit_Category)
VALUES 
    ('Healthcare', 'Medical assistance', 'Veteran with service-related injuries', 'Health'),
    ('Education', 'Tuition reimbursement', 'Honorably discharged', 'Education'),
    ('Housing', 'Home loans', 'Service-related disabilities', 'Housing'),
    ('Disability', 'Disability benefits', 'Service-related injuries', 'Financial'),
    ('Pension', 'Monthly pension', 'Over 65 years old', 'Financial'),
    ('Employment', 'Job assistance', 'Service-related injuries', 'Employment'),
    ('Vocational Training', 'Skill training', 'Honorably discharged', 'Education'),
    ('Life Insurance', 'Insurance plans', 'Active duty', 'Financial'),
    ('Counseling', 'Mental health services', 'Any veteran', 'Health'),
    ('Transportation', 'Free public transport', 'Disabled veterans', 'Other');

SELECT * FROM Benefit_Type;

-- Insert into Benefit_Application
INSERT INTO Benefit_Application (Veteran_ID, Application_Date, Benefit_Type, Benefit_Type_ID, Status, Decision_Date)
VALUES 
    (1, '2023-01-01', 'Healthcare', 1, 'Approved', '2023-01-15'),
    (2, '2023-02-01', 'Education', 2, 'Denied', '2023-02-20'),
    (3, '2023-03-01', 'Housing', 3, 'Pending', NULL),
    (4, '2023-04-01', 'Disability', 4, 'Approved', '2023-04-20'),
    (5, '2023-05-01', 'Pension', 5, 'Pending', NULL),
    (6, '2023-06-01', 'Employment', 6, 'Denied', '2023-06-15'),
    (7, '2023-07-01', 'Vocational Training', 7, 'Approved', '2023-07-20'),
    (8, '2023-08-01', 'Life Insurance', 8, 'Pending', NULL),
    (9, '2023-09-01', 'Counseling', 9, 'Approved', '2023-09-15'),
    (10, '2023-10-01', 'Transportation', 10, 'Denied', '2023-10-20');

SELECT * FROM Benefit_Application;

-- Insert into Claim
INSERT INTO Claim (Application_ID, Claim_Type, Claim_Date, Claim_Status, Decision_Date, Amount_Awarded)
VALUES 
    (1, 'Healthcare Claim', '2023-01-05', 'Approved', '2023-01-20', 1000.00),
    (2, 'Education Claim', '2023-02-05', 'Denied', '2023-02-25', 0.00),
    (3, 'Housing Claim', '2023-03-05', 'Pending', NULL, NULL),
    (4, 'Disability Claim', '2023-04-05', 'Approved', '2023-04-25', 5000.00),
    (5, 'Pension Claim', '2023-05-05', 'Pending', NULL, NULL),
    (6, 'Employment Claim', '2023-06-05', 'Denied', '2023-06-25', 0.00),
    (7, 'Vocational Training Claim', '2023-07-05', 'Approved', '2023-07-25', 1500.00),
    (8, 'Travel Claim', '2023-08-05', 'Pending', NULL, NULL),
    (9, 'Special Assistance Claim', '2023-09-05', 'Approved', '2023-09-25', 2000.00),
    (10, 'Medical Equipment Claim', '2023-10-05', 'Denied', '2023-10-25', 0.00);

SELECT * FROM Claim;

-- Insert into Medical_Record
INSERT INTO Medical_Record (Veteran_ID, Record_Date, Diagnosis, Service_Related, Treatment_Details)
VALUES 
    (1, '2023-01-10', 'Hypertension', 'Yes', 'Medication prescribed: Amlodipine'),
    (2, '2023-02-15', 'Diabetes', 'Yes', 'Insulin therapy initiated'),
    (3, '2023-03-20', 'PTSD', 'Yes', 'Cognitive behavioral therapy sessions'),
    (4, '2023-04-25', 'Knee Arthritis', 'No', 'Physical therapy recommended'),
    (5, '2023-05-30', 'Asthma', 'Yes', 'Inhaler prescribed'),
    (6, '2023-06-10', 'Chronic Back Pain', 'No', 'Pain management consultation'),
    (7, '2023-07-18', 'Skin Allergy', 'No', 'Topical ointment prescribed'),
    (8, '2023-08-12', 'Vision Impairment', 'Yes', 'Eyeglasses recommended'),
    (9, '2023-09-05', 'Hearing Loss', 'No', 'Hearing aids prescribed'),
    (10, '2023-10-20', 'High Cholesterol', 'Yes', 'Dietary changes and statin prescribed');

SELECT * FROM Medical_Record;

--12 Simple Queries
--Query1- Retrieve all veterans with their contact information:
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, v.Date_of_Birth, v.Social_Security_Number, v.Service_Branch, v.Discharge_Status, 
       c.Address, c.City, c.State, c.Postal_Code, c.Phone_Number, c.Email
FROM 
    Veteran v
JOIN 
    Contact_Info c ON v.Contact_Info_ID = c.Contact_Info_ID;

--Query2- Get the status of benefit applications for each veteran:
SELECT v.Veteran_ID, v.First_Name, v.Last_Name,
       ba.Application_ID, ba.Application_Date, bt.Benefit_Name, ba.Status AS Application_Status, ba.Decision_Date
FROM 
    Veteran v
JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
JOIN 
    Benefit_Type bt ON ba.Benefit_Type_ID = bt.Benefit_Type_ID;
	
--Query3- Find all claims with their status and awarded amount:
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, 
       c.Claim_ID, c.Claim_Type, c.Claim_Status, c.Amount_Awarded
FROM 
    Veteran v
JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
JOIN 
    Claim c ON ba.Application_ID = c.Application_ID
WHERE 
    c.Claim_Status = 'Approved';
	
--Query4- Get all veterans with medical records related to service:
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, 
       m.Medical_Record_ID, m.Record_Date, m.Diagnosis, m.Service_Related
FROM 
    Veteran v
JOIN 
    Medical_Record m ON v.Veteran_ID = m.Veteran_ID
WHERE 
    m.Service_Related = 'Yes';
	
--Query5- Find all pending benefit applications along with their associated veterans:
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, 
       ba.Application_ID, ba.Application_Date, bt.Benefit_Name, ba.Status AS Application_Status
FROM 
    Veteran v
JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
JOIN 
    Benefit_Type bt ON ba.Benefit_Type_ID = bt.Benefit_Type_ID
WHERE 
    ba.Status = 'Pending';

--Query6- Get all veterans' names and their service branch:
SELECT First_Name, Last_Name, Service_Branch
FROM 
    Veteran;
	
--Query7- List all benefit types and their descriptions:
SELECT Benefit_Name, Description
FROM 
    Benefit_Type;
	
--Query8- Find all veterans who have a pending benefit application:
SELECT v.First_Name, v.Last_Name, ba.Status 
FROM 
    Veteran v
JOIN 
    Benefit_Application ba ON v.Veteran_ID = ba.Veteran_ID
WHERE 
    ba.Status = 'Pending';
	
--Query9- Get the contact information of a specific veteran by ID:
SELECT v.First_Name, v.Last_Name, c.Address, c.City, c.Phone_Number
FROM 
    Veteran v
JOIN 
    Contact_Info c ON v.Contact_Info_ID = c.Contact_Info_ID
WHERE 
    v.Veteran_ID = 1;  -- Replace '1' with the specific Veteran_ID
	
--Query10- List all claims with their claim status:
SELECT Claim_Type, Claim_Status
FROM 
    Claim;

--Query11- Get all veterans' names and their date of birth:
SELECT First_Name, Last_Name, Date_of_Birth
FROM 
    Veteran;

--Query12- Find all medical records related to a specific veteran by ID:
SELECT Benefit_Application.Application_ID, Benefit_Application.Application_Date,
       CONCAT(Veteran.First_Name, ' ', Veteran.Last_Name) AS Veteran_Name
FROM 
    Benefit_Application
JOIN 
    Veteran ON Benefit_Application.Veteran_ID = Veteran.Veteran_ID;

--2 Advanced Queries
--Query1- Find Veterans with Approved Benefit Applications and Claims Awarded Over $1000
SELECT v.Veteran_ID, v.First_Name, v.Last_Name
FROM Veteran v
WHERE v.Veteran_ID IN (
    SELECT DISTINCT ba.Veteran_ID
    FROM Benefit_Application ba
    JOIN Claim c ON ba.Application_ID = c.Application_ID
    WHERE ba.Status = 'Approved' AND c.Amount_Awarded > 1000
);

--Query2- Get Veterans with Pending Applications and Their Related Medical Records
SELECT v.Veteran_ID, v.First_Name, v.Last_Name, m.Diagnosis, m.Treatment_Details
FROM Veteran v
JOIN Medical_Record m ON v.Veteran_ID = m.Veteran_ID
WHERE v.Veteran_ID IN (
    SELECT ba.Veteran_ID
    FROM Benefit_Application ba
    WHERE ba.Status = 'Pending'
);
