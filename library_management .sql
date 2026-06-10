-- ============================================================
-- Library Management System - Complete SQL Script
-- CS160 Database Systems | NUTECH
-- Run this file in SQL Server Management Studio (SSMS)
-- ============================================================

-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'LibraryDB')
BEGIN
    CREATE DATABASE LibraryDB;
END
GO

USE LibraryDB;
GO

-- ============================================================
-- TASK 3: DDL - CREATE TABLE Scripts
-- ============================================================

-- Table: Category
CREATE TABLE Category (
    CategoryID   INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(80)  NOT NULL UNIQUE,
    Description  VARCHAR(255) NULL
);

-- Table: Book
CREATE TABLE Book (
    BookID         INT IDENTITY(1,1) PRIMARY KEY,
    ISBN           VARCHAR(20)  NOT NULL UNIQUE,
    Title          VARCHAR(200) NOT NULL,
    PublicationYear INT          NOT NULL,
    Publisher      VARCHAR(100) NOT NULL,
    CategoryID     INT          NOT NULL,
    TotalCopies    INT          NOT NULL DEFAULT 0 CHECK (TotalCopies >= 0),
    AvailableCopies INT          NOT NULL DEFAULT 0 CHECK (AvailableCopies >= 0),
    CONSTRAINT fk_book_category FOREIGN KEY (CategoryID)
        REFERENCES Category(CategoryID) ON DELETE NO ACTION ON UPDATE CASCADE
);

-- Table: BookCopy (Weak Entity)
CREATE TABLE BookCopy (
    CopyID       INT IDENTITY(1,1) PRIMARY KEY,
    BookID       INT  NOT NULL,
    Condition    VARCHAR(10) NOT NULL DEFAULT 'Good' CHECK (Condition IN ('Good','Fair','Damaged')),
    IsAvailable  BIT NOT NULL DEFAULT 1,
    AcquiredDate DATE    NOT NULL,
    CONSTRAINT fk_copy_book FOREIGN KEY (BookID)
        REFERENCES Book(BookID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table: Author
CREATE TABLE Author (
    AuthorID    INT IDENTITY(1,1) PRIMARY KEY,
    FirstName   VARCHAR(50) NOT NULL,
    LastName    VARCHAR(50) NOT NULL,
    Nationality VARCHAR(50) NULL,
    BirthYear   INT         NULL
);

-- Table: BookAuthor (Associative - Many-to-Many)
CREATE TABLE BookAuthor (
    BookID   INT NOT NULL,
    AuthorID INT NOT NULL,
    PRIMARY KEY (BookID, AuthorID),
    CONSTRAINT fk_ba_book   FOREIGN KEY (BookID)   REFERENCES Book(BookID)     ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID) ON DELETE CASCADE
);

-- Table: Member
CREATE TABLE Member (
    MemberID        INT IDENTITY(1,1) PRIMARY KEY,
    CardNumber      VARCHAR(20)  NOT NULL UNIQUE,
    FullName        VARCHAR(100) NOT NULL,
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Street          VARCHAR(100) NULL,
    City            VARCHAR(50)  NULL,
    ZipCode         VARCHAR(10)  NULL,
    MembershipType VARCHAR(10) NOT NULL DEFAULT 'Standard' CHECK (MembershipType IN ('Standard','Premium')),
    JoinDate        DATE    NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1
);

-- Table: MemberPhone (Multi-valued attribute)
CREATE TABLE MemberPhone (
    PhoneID  INT IDENTITY(1,1) PRIMARY KEY,
    MemberID INT         NOT NULL,
    Phone    VARCHAR(15) NOT NULL,
    CONSTRAINT fk_phone_member FOREIGN KEY (MemberID)
        REFERENCES Member(MemberID) ON DELETE CASCADE
);

-- Table: Staff (Supertype)
CREATE TABLE Staff (
    StaffID   INT IDENTITY(1,1) PRIMARY KEY,
    FullName  VARCHAR(100)  NOT NULL,
    Email     VARCHAR(100)  NOT NULL UNIQUE,
    HireDate  DATE          NOT NULL,
    Salary    DECIMAL(10,2) NOT NULL CHECK (Salary > 0),
    StaffType VARCHAR(15)  NOT NULL CHECK (StaffType IN ('Librarian','Assistant','Admin'))
);

-- Table: Librarian (Subtype)
CREATE TABLE Librarian (
    StaffID        INT PRIMARY KEY,
    Specialization VARCHAR(80) NULL,
    CONSTRAINT fk_librarian_staff FOREIGN KEY (StaffID)
        REFERENCES Staff(StaffID) ON DELETE CASCADE
);

-- Table: Assistant (Subtype)
CREATE TABLE Assistant (
    StaffID   INT PRIMARY KEY,
    ShiftTime VARCHAR(10) NOT NULL CHECK (ShiftTime IN ('Morning','Evening','Night')),
    CONSTRAINT fk_assistant_staff FOREIGN KEY (StaffID)
        REFERENCES Staff(StaffID) ON DELETE CASCADE
);

-- Table: Admin (Subtype)
CREATE TABLE Admin (
    StaffID     INT PRIMARY KEY,
    AccessLevel VARCHAR(10) NOT NULL DEFAULT 'Level1' CHECK (AccessLevel IN ('Level1','Level2','Level3')),
    CONSTRAINT fk_admin_staff FOREIGN KEY (StaffID)
        REFERENCES Staff(StaffID) ON DELETE CASCADE
);

-- Table: BorrowTransaction (Associative Entity)
CREATE TABLE BorrowTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    MemberID      INT  NOT NULL,
    CopyID        INT  NOT NULL,
    BorrowDate    DATE NOT NULL,
    DueDate       DATE NOT NULL,
    ReturnDate    DATE NULL,
    Status        VARCHAR(10) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active','Returned','Overdue')),
    CONSTRAINT fk_bt_member FOREIGN KEY (MemberID)
        REFERENCES Member(MemberID) ON DELETE NO ACTION,
    CONSTRAINT fk_bt_copy FOREIGN KEY (CopyID)
        REFERENCES BookCopy(CopyID) ON DELETE NO ACTION,
    CONSTRAINT chk_due CHECK (DueDate > BorrowDate)
);

-- Table: Fine
CREATE TABLE Fine (
    FineID        INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT          NOT NULL UNIQUE,
    Amount        DECIMAL(8,2) NOT NULL CHECK (Amount >= 0),
    PaidStatus    BIT          NOT NULL DEFAULT 0,
    PaidDate      DATE         NULL,
    CONSTRAINT fk_fine_transaction FOREIGN KEY (TransactionID)
        REFERENCES BorrowTransaction(TransactionID) ON DELETE CASCADE
);

-- Table: Reservation
CREATE TABLE Reservation (
    ReservationID   INT IDENTITY(1,1) PRIMARY KEY,
    MemberID        INT  NOT NULL,
    BookID          INT  NOT NULL,
    ReservationDate DATE NOT NULL,
    ExpiryDate      DATE NOT NULL,
    Status          VARCHAR(10) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Fulfilled','Cancelled')),
    CONSTRAINT fk_res_member FOREIGN KEY (MemberID)
        REFERENCES Member(MemberID) ON DELETE CASCADE,
    CONSTRAINT fk_res_book FOREIGN KEY (BookID)
        REFERENCES Book(BookID) ON DELETE CASCADE,
    CONSTRAINT chk_expiry CHECK (ExpiryDate > ReservationDate)
);
GO

-- ============================================================
-- TASK 4: DML - INSERT Data
-- ============================================================

-- Category (10 rows)
INSERT INTO Category (CategoryName, Description) VALUES
('Fiction',     'Novels, short stories, and imaginative narratives'),
('Non-Fiction', 'Factual books based on real events or topics'),
('Science',     'Physics, Biology, Chemistry, and related fields'),
('Technology',  'Computing, networking, AI, and software engineering'),
('History',     'Historical accounts and biographies'),
('Mathematics', 'Pure and applied mathematics'),
('Literature',  'Classic and modern literary works'),
('Self-Help',   'Personal development and motivational books'),
('Business',    'Entrepreneurship, management, and economics'),
('Philosophy',  'Philosophical thought and ethics');

-- Book (20 rows)
INSERT INTO Book (ISBN, Title, PublicationYear, Publisher, CategoryID, TotalCopies, AvailableCopies) VALUES
('978-0061965784', 'Brave New World',                      1932, 'Harper Perennial', 1, 5, 3),
('978-0743273565', 'The Great Gatsby',                     1925, 'Scribner',         7, 4, 2),
('978-0307474278', 'The Da Vinci Code',                     2003, 'Anchor Books',     1, 6, 4),
('978-0201616224', 'The Pragmatic Programmer',             1999, 'Addison-Wesley',   4, 3, 1),
('978-0132350884', 'Clean Code',                            2008, 'Prentice Hall',    4, 4, 2),
('978-0385737951', 'The Hunger Games',                     2008, 'Scholastic',       1, 7, 5),
('978-0393356250', 'Sapiens',                               2011, 'Harper Collins',   5, 5, 3),
('978-0674034624', 'The Elements of Statistical Learning', 2001, 'Springer',         3, 2, 1),
('978-0062316097', 'The Alchemist',                         1988, 'HarperOne',        8, 6, 4),
('978-1501156700', 'It Ends with Us',                      2016, 'Atria Books',      1, 5, 3),
('978-0521880688', 'Introduction to Algorithms',           2009, 'MIT Press',        6, 3, 0),
('978-0316769174', 'The Catcher in the Rye',               1951, 'Little Brown',     7, 4, 2),
('978-0393351590', 'Thinking Fast and Slow',               2011, 'Farrar Straus',    8, 4, 3),
('978-1501175466', 'Educated',                              2018, 'Random House',     2, 5, 4),
('978-0062641540', 'Shoe Dog',                              2016, 'Scribner',         9, 3, 2),
('978-0374533557', 'Meditations',                          1900, 'Farrar Straus',    10, 4, 3),
('978-0385490818', '1984',                                  1949, 'Secker Warburg',   1, 6, 2),
('978-0198526636', 'A Brief History of Time',               1988, 'Bantam Books',     3, 5, 3),
('978-0735224292', 'Little Fires Everywhere',              2017, 'Penguin Press',    1, 4, 2),
('978-0735211292', 'The Silent Patient',                    2019, 'Celadon Books',    1, 5, 3);

-- Author (20 rows)
INSERT INTO Author (FirstName, LastName, Nationality, BirthYear) VALUES
('Aldous',   'Huxley',      'British',   1894),
('F. Scott', 'Fitzgerald',  'American',  1896),
('Dan',      'Brown',       'American',  1964),
('Andrew',   'Hunt',        'American',  1964),
('Robert',   'Martin',      'American',  1952),
('Suzanne',  'Collins',     'American',  1962),
('Yuval',    'Harari',      'Israeli',   1976),
('Paulo',    'Coelho',      'Brazilian', 1947),
('Colleen',  'Hoover',      'American',  1979),
('Thomas',   'Cormen',      'American',  1956),
('J.D.',     'Salinger',    'American',  1919),
('Daniel',   'Kahneman',    'Israeli',   1934),
('Tara',     'Westover',    'American',  1986),
('Phil',     'Knight',      'American',  1938),
('Marcus',   'Aurelius',    'Roman',     1901),
('George',   'Orwell',      'British',   1903),
('Stephen',  'Hawking',     'British',   1942),
('Celeste',  'Ng',          'American',  1980),
('Alex',     'Michaelides', 'British',   1977),
('Hasib',    'Leiserson',   'American',  1960);

-- BookAuthor (21 rows)
INSERT INTO BookAuthor (BookID, AuthorID) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),
(8,10),(8,20),
(9,8),(10,9),(11,10),(12,11),(13,12),(14,13),
(15,14),(16,15),(17,16),(18,17),(19,18),(20,19);

-- BookCopy (20 rows) - True mapping to 1, False mapping to 0
INSERT INTO BookCopy (BookID, Condition, IsAvailable, AcquiredDate) VALUES
(1,  'Good',    1, '2021-03-10'),
(1,  'Good',    1, '2021-03-10'),
(1,  'Fair',    0, '2020-01-15'),
(2,  'Good',    1, '2020-06-20'),
(2,  'Fair',    0, '2021-07-01'),
(3,  'Good',    1, '2022-01-05'),
(3,  'Good',    1, '2022-01-05'),
(3,  'Good',    0, '2022-01-05'),
(4,  'Good',    1, '2019-11-11'),
(4,  'Damaged', 0, '2018-08-08'),
(5,  'Good',    1, '2020-05-01'),
(5,  'Fair',    0, '2020-05-01'),
(6,  'Good',    1, '2021-09-15'),
(6,  'Good',    1, '2021-09-15'),
(6,  'Good',    0, '2021-09-15'),
(7,  'Good',    1, '2022-03-20'),
(7,  'Good',    0, '2022-03-20'),
(11, 'Good',    0, '2020-12-25'),
(17, 'Good',    1, '2019-06-01'),
(17, 'Fair',    0, '2019-06-01');

-- Member (15 rows) - True mapping to 1, False mapping to 0
INSERT INTO Member (CardNumber, FullName, Email, Street, City, ZipCode, MembershipType, JoinDate, IsActive) VALUES
('LIB-001', 'Ahmed Khan',       'ahmed.khan@gmail.com',    'Street 5',        'Islamabad',  '44000', 'Premium',  '2022-01-10', 1),
('LIB-002', 'Sara Ali',         'sara.ali@yahoo.com',      'Block B',         'Rawalpindi', '46000', 'Standard', '2022-03-15', 1),
('LIB-003', 'Bilal Nawaz',      'bilal.nawaz@hotmail.com', 'Sector G-9',      'Islamabad',  '44090', 'Standard', '2021-07-20', 1),
('LIB-004', 'Fatima Malik',     'fatima.m@gmail.com',      'Model Town',      'Lahore',     '54000', 'Premium',  '2023-02-01', 1),
('LIB-005', 'Usman Raza',       'usman.raza@gmail.com',    'DHA Phase 2',     'Karachi',    '75500', 'Standard', '2020-11-05', 1),
('LIB-006', 'Zara Hussain',     'zara.h@outlook.com',      'F-7 Markaz',      'Islamabad',  '44000', 'Premium',  '2022-05-22', 1),
('LIB-007', 'Hamid Sheikh',     'hamid.sh@gmail.com',      'Gulshan-e-Iqbal', 'Karachi',    '75300', 'Standard', '2023-06-10', 1),
('LIB-008', 'Nadia Qureshi',    'nadia.q@gmail.com',       'Johar Town',      'Lahore',     '54600', 'Standard', '2021-12-01', 0),
('LIB-009', 'Tariq Jamil',      'tariq.jamil@yahoo.com',   'Clifton',         'Karachi',    '75600', 'Premium',  '2020-08-14', 1),
('LIB-010', 'Ayesha Siddiqui',  'ayesha.s@gmail.com',      'I-8',             'Islamabad',  '44080', 'Standard', '2022-09-30', 1),
('LIB-011', 'Kamran Baig',      'kamran.b@gmail.com',      'Gulberg III',     'Lahore',     '54660', 'Standard', '2023-01-17', 1),
('LIB-012', 'Hina Afzal',       'hina.a@hotmail.com',      'North Nazimabad', 'Karachi',    '74700', 'Premium',  '2021-04-25', 1),
('LIB-013', 'Omer Farooq',      'omer.f@gmail.com',        'G-10',            'Islamabad',  '44100', 'Standard', '2020-06-06', 1),
('LIB-014', 'Sana Tariq',       'sana.t@yahoo.com',        'Township',        'Lahore',     '54800', 'Standard', '2022-11-11', 1),
('LIB-015', 'Asad Mehmood',     'asad.m@gmail.com',        'Malir',           'Karachi',    '75080', 'Premium',  '2023-03-28', 1);

-- MemberPhone (17 rows)
INSERT INTO MemberPhone (MemberID, Phone) VALUES
(1,  '0300-1234567'), (1,  '0321-9876543'),
(2,  '0333-1112222'), (3,  '0311-3334444'),
(4,  '0345-5556666'), (4,  '0321-7778888'),
(5,  '0301-9990000'), (6,  '0322-1231231'),
(7,  '0312-4564564'), (8,  '0315-7897897'),
(9,  '0346-1010101'), (10, '0303-2020202'),
(11, '0344-3030303'), (12, '0308-4040404'),
(13, '0319-5050505'), (14, '0329-6060606'),
(15, '0302-7070707');

-- Staff (10 rows)
INSERT INTO Staff (FullName, Email, HireDate, Salary, StaffType) VALUES
('Dr. Imran Shah',   'imran.shah@library.edu.pk', '2018-01-15', 75000.00, 'Librarian'),
('Ms. Rabia Noor',   'rabia.noor@library.edu.pk', '2019-06-01', 45000.00, 'Assistant'),
('Mr. Faisal Khan',  'faisal.k@library.edu.pk',   '2020-03-10', 80000.00, 'Admin'),
('Mrs. Amna Riaz',   'amna.r@library.edu.pk',     '2021-08-20', 70000.00, 'Librarian'),
('Mr. Rizwan Butt',  'rizwan.b@library.edu.pk',   '2022-02-14', 42000.00, 'Assistant'),
('Ms. Sobia Akhtar', 'sobia.a@library.edu.pk',    '2017-11-30', 48000.00, 'Assistant'),
('Mr. Asif Raza',    'asif.r@library.edu.pk',     '2016-05-05', 90000.00, 'Admin'),
('Dr. Nadia Islam',  'nadia.i@library.edu.pk',    '2023-01-10', 68000.00, 'Librarian'),
('Mr. Junaid Ali',   'junaid.a@library.edu.pk',   '2022-09-25', 44000.00, 'Assistant'),
('Ms. Bushra Khan',  'bushra.k@library.edu.pk',   '2015-03-20', 95000.00, 'Admin');

INSERT INTO Librarian (StaffID, Specialization) VALUES
(1, 'Digital Resources'), (4, 'Archiving'), (8, 'Cataloguing');

INSERT INTO Assistant (StaffID, ShiftTime) VALUES
(2, 'Morning'), (5, 'Evening'), (6, 'Night'), (9, 'Morning');

INSERT INTO Admin (StaffID, AccessLevel) VALUES
(3, 'Level3'), (7, 'Level3'), (10, 'Level2');

-- BorrowTransaction (20 rows)
INSERT INTO BorrowTransaction (MemberID, CopyID, BorrowDate, DueDate, ReturnDate, Status) VALUES
(1,  3,  '2024-01-10', '2024-01-24', '2024-01-22', 'Returned'),
(2,  5,  '2024-02-01', '2024-02-15', NULL,           'Overdue'),
(3,  10, '2024-02-20', '2024-03-06', '2024-03-10', 'Returned'),
(4,  12, '2024-03-01', '2024-03-15', NULL,           'Active'),
(5,  18, '2024-03-05', '2024-03-19', '2024-03-19', 'Returned'),
(6,  8,  '2024-03-12', '2024-03-26', NULL,           'Overdue'),
(7,  2,  '2024-04-01', '2024-04-15', '2024-04-13', 'Returned'),
(8,  20, '2024-04-10', '2024-04-24', NULL,           'Active'),
(9,  15, '2024-04-15', '2024-04-29', '2024-05-05', 'Returned'),
(10, 7,  '2024-05-01', '2024-05-15', NULL,           'Overdue'),
(11, 4,  '2024-05-10', '2024-05-24', '2024-05-23', 'Returned'),
(12, 11, '2024-05-20', '2024-06-03', NULL,           'Active'),
(13, 19, '2024-06-01', '2024-06-15', '2024-06-14', 'Returned'),
(14, 6,  '2024-06-05', '2024-06-19', NULL,           'Active'),
(15, 9,  '2024-06-10', '2024-06-24', '2024-06-30', 'Returned'),
(1,  13, '2024-07-01', '2024-07-15', NULL,           'Active'),
(2,  16, '2024-07-05', '2024-07-19', '2024-07-18', 'Returned'),
(3,  1,  '2024-07-10', '2024-07-24', NULL,           'Overdue'),
(4,  17, '2024-07-20', '2024-08-03', '2024-08-02', 'Returned'),
(5,  14, '2024-08-01', '2024-08-15', NULL,           'Active');

-- Fine (7 rows) - True mapping to 1, False mapping to 0
INSERT INTO Fine (TransactionID, Amount, PaidStatus, PaidDate) VALUES
(2,  140.00, 1, '2024-04-01'),
(3,   40.00, 1, '2024-03-20'),
(6,  210.00, 0, NULL),
(9,   60.00, 1, '2024-05-10'),
(10, 180.00, 0, NULL),
(15,  60.00, 1, '2024-07-05'),
(18, 150.00, 0, NULL);

-- Reservation (15 rows)
INSERT INTO Reservation (MemberID, BookID, ReservationDate, ExpiryDate, Status) VALUES
(1,  11, '2024-06-01', '2024-06-15', 'Pending'),
(2,   5, '2024-05-10', '2024-05-24', 'Fulfilled'),
(3,  17, '2024-06-20', '2024-07-04', 'Pending'),
(4,   3, '2024-07-01', '2024-07-15', 'Cancelled'),
(5,   8, '2024-07-10', '2024-07-24', 'Pending'),
(6,  11, '2024-07-15', '2024-07-29', 'Pending'),
(7,  13, '2024-08-01', '2024-08-15', 'Fulfilled'),
(8,   1, '2024-08-05', '2024-08-19', 'Pending'),
(9,   6, '2024-08-10', '2024-08-24', 'Cancelled'),
(10, 20, '2024-08-15', '2024-08-29', 'Pending'),
(11,  4, '2024-08-20', '2024-09-03', 'Fulfilled'),
(12, 15, '2024-09-01', '2024-09-15', 'Pending'),
(13,  9, '2024-09-05', '2024-09-19', 'Pending'),
(14, 12, '2024-09-10', '2024-09-24', 'Cancelled'),
(15,  7, '2024-09-15', '2024-09-29', 'Pending');
GO

-- ============================================================
-- Done. All tables created and populated for SQL Server.
-- ============================================================

USE LibraryDB;
GO

-- ============================================================
-- GROUP 1: BOOK CATALOG & INVENTORY TABLES
-- ============================================================

PRINT '==================== 1. CATEGORIES ====================';
SELECT * FROM Category;

PRINT '==================== 2. BOOKS ====================';
SELECT * FROM Book;

PRINT '==================== 3. AUTHORS ====================';
SELECT * FROM Author;

PRINT '==================== 4. BOOK-AUTHOR MAPPINGS ====================';
SELECT * FROM BookAuthor;

PRINT '==================== 5. PHYSICAL BOOK COPIES ====================';
SELECT * FROM BookCopy;


-- ============================================================
-- GROUP 2: MEMBERSHIP TABLES
-- ============================================================

PRINT '==================== 6. MEMBERS ====================';
SELECT * FROM Member;

PRINT '==================== 7. MEMBER PHONE NUMBERS ====================';
SELECT * FROM MemberPhone;


-- ============================================================
-- GROUP 3: STAFF HIERARCHY TABLES
-- ============================================================

PRINT '==================== 8. BASE STAFF RECORDS ====================';
SELECT * FROM Staff;

PRINT '==================== 9. LIBRARIANS (SUBTYPE) ====================';
SELECT * FROM Librarian;

PRINT '==================== 10. ASSISTANTS (SUBTYPE) ====================';
SELECT * FROM Assistant;

PRINT '==================== 11. ADMINS (SUBTYPE) ====================';
SELECT * FROM Admin;


-- ============================================================
-- GROUP 4: TRANSACTION & FINANCIAL TABLES
-- ============================================================

PRINT '==================== 12. BORROW TRANSACTIONS ====================';
SELECT * FROM BorrowTransaction;

PRINT '==================== 13. FINES ====================';
SELECT * FROM Fine;

PRINT '==================== 14. RESERVATIONS ====================';
SELECT * FROM Reservation;
GO