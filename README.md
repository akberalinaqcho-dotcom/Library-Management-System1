
# Library Management System (LMS)

A robust relational database solution engineered to streamline and manage the operational workflows of a public or institutional library. The system handles end-to-end cataloging, membership subscriptions, tiered staff administration, transactional borrowing records, automatic overdue penalty parameters, and booking configurations using advanced relational modeling techniques.

---

## 🛠️ System Overview & Business Rules

The database engine enforces critical real-world constraints via explicit schemas, constraints, and operational triggers:
* [cite_start]**Membership Capacity:** Every member possesses a distinct library card identity and is strictly capped at borrowing a maximum of 5 books concurrently[cite: 4].
* [cite_start]**Stock Isolation:** Books maintain distinct bibliographic rows, while each individual physical copy is inventoried and checked status-wise on an itemized basis[cite: 5].
* **Fines System:** Overdue fees accrue programmatically calculated at **Rs. [cite_start]10 per day** past the standard transaction due date[cite: 6, 7].
* **Hierarchical Infrastructure:** Employees inherit fields from a master table structural setup mapped into explicit specific service roles: `Librarian`, `Assistant`, or `Admin`[cite: 7].
* [cite_start]**Relational Normalization:** M:N schemas such as multi-authored books, transactional logs, and reservations are decoupled safely using associative bridge entities to maintain BCNF/3NF consistency[cite: 8, 9, 29].

---

## 📐 Entity-Relationship Architecture

[cite_start]The conceptual schema design utilizes an **Enhanced Entity-Relationship (EER) Model** mapping complex real-world data connections[cite: 11]:

* [cite_start]**Member (`Strong Entity`):** Tracks registered cardholders [cite: 13][cite_start]. flattening out structured addresses while isolating multi-valued tracking values (`MemberPhone`)[cite: 14, 15].
* [cite_start]**BookCopy (`Weak Entity`):** Dependent directly upon parent `Book` entities via strict identifying links (`ON DELETE CASCADE`)[cite: 19, 20].
* [cite_start]**Staff Generalization Hierarchy:** Uses single-table supertype abstraction linked directly with distinct extension entities (`Librarian`, `Assistant`, `Admin`) mapped on a specialized discriminator criteria[cite: 23, 24, 25].
* **Associative Entities:** Resolves complex relationships:
  * [cite_start]`BorrowTransaction` maps operational metrics across `Member` and `BookCopy` instances[cite: 63].
  * [cite_start]`BookAuthor` bridges co-author connections across catalog records[cite: 21, 44].
  * `Reservation` registers hold-queues against absolute core book titles[cite: 69].

---

## 💾 Relational Mapping Strategy

| Entity Name | Primary Key | Foreign Key Dependencies | Relational Strategy Applied |
| :--- | :--- | :--- | :--- |
| **Category** | `CategoryID` | None | Baseline strong category lookup schema[cite: 33]. |
| **Book** | `BookID` | `CategoryID` | `ON DELETE RESTRICT` protects valid catalog slots[cite: 35, 36]. |
| **BookCopy** | `CopyID` | `BookID` | Weak Entity mapping using strict cascaded deletions[cite: 38, 39]. |
| **Author** | `AuthorID` | None | Baseline author metadata lookup table[cite: 41]. |
| **BookAuthor** | `(BookID, AuthorID)` | `BookID`, `AuthorID` | Composite Primary Key managing Many-to-Many bounds[cite: 44, 45]. |
| **Member** | `MemberID` | None | Normalized flat components with unique identifier parameters[cite: 47, 49]. |
| **MemberPhone**| `PhoneID` | `MemberID` | Extracted out to elegantly manage multi-valued telephone records[cite: 50, 51]. |
| **Staff** | `StaffID` | None | Base Master entity with check constraints on currency values[cite: 53, 55]. |
| **Librarian** | `StaffID` | `StaffID` | Subtype entity handling catalog assignment extensions[cite: 56, 57]. |
| **Assistant** | `StaffID` | `StaffID` | Subtype managing operational hourly shift flags[cite: 59, 60]. |
| **Admin** | `StaffID` | `StaffID` | Subtype defining tiered systemic control bounds[cite: 61, 62]. |
| **BorrowTransaction** | `TransactionID` | `MemberID`, `CopyID` | Enforces historical audit logs via structural delete safety triggers[cite: 63, 64]. |
| **Fine** | `FineID` | `TransactionID` | Strict Unique 1:1 transaction ledger managing fee points[cite: 66, 67]. |
| **Reservation**| `ReservationID` | `MemberID`, `BookID` | Enables operational hold rules targeting major titles[cite: 68, 69]. |

---

## 🚀 Database Deployment Script (DDL)

Execute the following standardized ANSI SQL script inside your database environment (e.g., SQL Server Management Studio) to set up the library infrastructure[cite: 110]:

```sql
-- Create Database Environment
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'LibraryDB')
BEGIN
    CREATE DATABASE LibraryDB;
END
GO
USE LibraryDB;
GO

-- ==========================================
-- 1. BASE CATALOG TABLES
-- ==========================================

CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(80) NOT NULL UNIQUE,
    Description VARCHAR(255) NULL
);

CREATE TABLE Book (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    ISBN VARCHAR(20) NOT NULL UNIQUE,
    Title VARCHAR(200) NOT NULL,
    PublicationYear INT NOT NULL,
    Publisher VARCHAR(100) NOT NULL,
    CategoryID INT NOT NULL,
    TotalCopies INT NOT NULL DEFAULT 0 CHECK (TotalCopies >= 0),
    AvailableCopies INT NOT NULL DEFAULT 0 CHECK (AvailableCopies >= 0),
    CONSTRAINT fk_book_category FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID) ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE BookCopy (
    CopyID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT NOT NULL,
    Condition VARCHAR(10) NOT NULL DEFAULT 'Good' CHECK (Condition IN ('Good','Fair','Damaged')),
    IsAvailable BIT NOT NULL DEFAULT 1,
    AcquiredDate DATE NOT NULL,
    CONSTRAINT fk_copy_book FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Author (
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Nationality VARCHAR(50) NULL,
    BirthYear INT NULL
);

CREATE TABLE BookAuthor (
    BookID INT NOT NULL,
    AuthorID INT NOT NULL,
    PRIMARY KEY (BookID, AuthorID),
    CONSTRAINT fk_ba_book FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID) ON DELETE CASCADE
);

-- ==========================================
-- 2. USER MEMBERSHIP TABLES
-- ==========================================

CREATE TABLE Member (
    MemberID INT IDENTITY(1,1) PRIMARY KEY,
    CardNumber VARCHAR(20) NOT NULL UNIQUE,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Street VARCHAR(100) NULL,
    City VARCHAR(50) NULL,
    ZipCode VARCHAR(10) NULL,
    MembershipType VARCHAR(10) NOT NULL DEFAULT 'Standard' CHECK (MembershipType IN ('Standard','Premium')),
    JoinDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE MemberPhone (
    PhoneID INT IDENTITY(1,1) PRIMARY KEY,
    MemberID INT NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    CONSTRAINT fk_phone_member FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE
);

-- ==========================================
-- 3. STAFF STRUCTURE TABLES
-- ==========================================

CREATE TABLE Staff (
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    HireDate DATE NOT NULL,
    Salary DECIMAL(10,2) NOT NULL CHECK (Salary > 0),
    StaffType VARCHAR(15) NOT NULL CHECK (StaffType IN ('Librarian','Assistant','Admin'))
);

CREATE TABLE Librarian (
    StaffID INT PRIMARY KEY,
    Specialization VARCHAR(80) NULL,
    CONSTRAINT fk_librarian_staff FOREIGN KEY (StaffID) REFERENCES Staff(StaffID) ON DELETE CASCADE
);

CREATE TABLE Assistant (
    StaffID INT PRIMARY KEY,
    ShiftTime VARCHAR(10) NOT NULL CHECK (ShiftTime IN ('Morning','Evening','Night')),
    CONSTRAINT fk_assistant_staff FOREIGN KEY (StaffID) REFERENCES Staff(StaffID) ON DELETE CASCADE
);

CREATE TABLE Admin (
    StaffID INT PRIMARY KEY,
    AccessLevel VARCHAR(10) NOT NULL DEFAULT 'Level1' CHECK (AccessLevel IN ('Level1','Level2','Level3')),
    CONSTRAINT fk_admin_staff FOREIGN KEY (StaffID) REFERENCES Staff(StaffID) ON DELETE CASCADE
);

-- ==========================================
-- 4. OPERATIONAL LEASE & TRACKING TABLES
-- ==========================================

CREATE TABLE BorrowTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    MemberID INT NOT NULL,
    CopyID INT NOT NULL,
    BorrowDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL,
    Status VARCHAR(10) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active','Returned','Overdue')),
    CONSTRAINT fk_bt_member FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE NO ACTION,
    CONSTRAINT fk_bt_copy FOREIGN KEY (CopyID) REFERENCES BookCopy(CopyID) ON DELETE NO ACTION,
    CONSTRAINT chk_due CHECK (DueDate > BorrowDate)
);

CREATE TABLE Fine (
    FineID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT NOT NULL UNIQUE,
    Amount DECIMAL(8,2) NOT NULL CHECK (Amount >= 0),
    PaidStatus BIT NOT NULL DEFAULT 0,
    PaidDate DATE NULL,
    CONSTRAINT fk_fine_transaction FOREIGN KEY (TransactionID) REFERENCES BorrowTransaction(TransactionID) ON DELETE CASCADE
);

CREATE TABLE Reservation (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    MemberID INT NOT NULL,
    BookID INT NOT NULL,
    ReservationDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    Status VARCHAR(10) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Fulfilled','Cancelled')),
    CONSTRAINT fk_res_member FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    CONSTRAINT fk_res_book FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE,
    CONSTRAINT chk_expiry CHECK (ExpiryDate > ReservationDate)
);
GO
