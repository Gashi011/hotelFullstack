-- =============================================================
-- Hotel Management - MySQL schema + demo podaci
-- Import: mysql -u root -p < hotel_management.sql
-- =============================================================
CREATE DATABASE IF NOT EXISTS hotel_management
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE hotel_management;
-- Brišemo redom zbog foreign key-eva (reservations zavisi od ostalih tabela).
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS conference_halls;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS users;
-- -------------------------------------------------------------
-- users - zaposleni hotela koji koriste aplikaciju
-- -------------------------------------------------------------
CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
username VARCHAR(50) NOT NULL UNIQUE,
password_hash VARCHAR(255) NOT NULL,
full_name VARCHAR(100) NOT NULL,
role VARCHAR(30) NOT NULL DEFAULT 'ADMIN',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- -------------------------------------------------------------
-- rooms - sobe hotela
-- -------------------------------------------------------------
CREATE TABLE rooms (
id INT AUTO_INCREMENT PRIMARY KEY,
room_number VARCHAR(20) NOT NULL UNIQUE,
bed_count INT NOT NULL,
bed_type VARCHAR(100) NOT NULL,
has_terrace BOOLEAN NOT NULL DEFAULT FALSE,
window_orientation VARCHAR(30),
floor INT NOT NULL,
free_internet BOOLEAN NOT NULL DEFAULT TRUE,
has_wardrobe BOOLEAN NOT NULL DEFAULT TRUE,
separate_hallway_view BOOLEAN NOT NULL DEFAULT FALSE,
additional_amenities VARCHAR(500),
price_per_night DECIMAL(10,2) NOT NULL,
active BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CHECK (bed_count > 0),
CHECK (price_per_night > 0)
);
-- -------------------------------------------------------------
-- conference_halls - konferencijske sale
-- -------------------------------------------------------------
CREATE TABLE conference_halls (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100) NOT NULL,
seat_count INT NOT NULL,
area_m2 DECIMAL(10,2) NOT NULL,
has_stage BOOLEAN NOT NULL DEFAULT FALSE,
has_lectern BOOLEAN NOT NULL DEFAULT FALSE,
has_projector BOOLEAN NOT NULL DEFAULT FALSE,
has_sound_system BOOLEAN NOT NULL DEFAULT FALSE,
additional_amenities VARCHAR(500),
price_per_day DECIMAL(10,2) NOT NULL,
active BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
CHECK (seat_count > 0),
CHECK (area_m2 > 0),
CHECK (price_per_day > 0)
);
-- -------------------------------------------------------------
-- clients - gosti hotela (nisu korisnici sistema, nemaju login)
-- -------------------------------------------------------------
CREATE TABLE clients (
id INT AUTO_INCREMENT PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
email VARCHAR(100),
phone VARCHAR(30) NOT NULL,
document_number VARCHAR(50),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- -------------------------------------------------------------
-- reservations - jedna rezervacija = jedna soba ILI jedna sala
-- -------------------------------------------------------------
CREATE TABLE reservations (
id INT AUTO_INCREMENT PRIMARY KEY,
client_id INT NOT NULL,
room_id INT NULL,
hall_id INT NULL,
date_from DATE NOT NULL,
date_to DATE NOT NULL,
status ENUM('ACTIVE', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
notes VARCHAR(500),
created_by INT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (client_id) REFERENCES clients(id),
FOREIGN KEY (room_id) REFERENCES rooms(id),
FOREIGN KEY (hall_id) REFERENCES conference_halls(id),
FOREIGN KEY (created_by) REFERENCES users(id),
CHECK (date_from < date_to),
-- Rezervacija se odnosi ili na sobu ili na salu, nikada na oboje.
CHECK (
(room_id IS NOT NULL AND hall_id IS NULL)
OR
(room_id IS NULL AND hall_id IS NOT NULL)
)
);
-- =============================================================
-- DEMO PODACI
-- =============================================================
-- Demo korisnik: username = admin, lozinka = Admin123!
-- Hash je bcrypt hash lozinke Admin123! (lozinka se nikada ne cuva kao tekst).
INSERT INTO users (username, password_hash, full_name, role) VALUES
('admin', '$2b$10$n8.xGo3IlrgtE3ylPdbLOOoRB9BQnk55IyFcPvH3hCojjdFJuceS2', 'Glavni administrator', 'ADMIN');
INSERT INTO rooms
(room_number, bed_count, bed_type, has_terrace, window_orientation, floor,
free_internet, has_wardrobe, separate_hallway_view, additional_amenities, price_per_night, active)
VALUES
('101', 2, 'Double bed', TRUE, 'Jug', 1, TRUE, TRUE, FALSE, 'Mini bar, sef', 90.00, TRUE),
('102', 2, 'Two single beds', FALSE, 'Sever', 1, TRUE, TRUE, FALSE, 'Sef', 75.00, TRUE),
('103', 1, 'Single bed', FALSE, 'Istok', 1, TRUE, FALSE, TRUE, NULL, 55.00, TRUE),
('201', 3, 'One double + one single', TRUE, 'Zapad', 2, TRUE, TRUE, FALSE, 'Mini bar, TV 50\", sef', 120.00, TRUE),
('202', 4, 'Two double beds', TRUE, 'Jug', 2, TRUE, TRUE, FALSE, 'Mini bar, kuhinjica', 150.00, TRUE);
INSERT INTO conference_halls
(name, seat_count, area_m2, has_stage, has_lectern, has_projector, has_sound_system,
additional_amenities, price_per_day, active)
VALUES
('Velika konferencijska sala', 200, 320.00, TRUE, TRUE, TRUE, TRUE, 'Klima, garderoba, bežični mikrofoni', 800.00,
TRUE),
('Mala sala', 60, 90.00, FALSE, TRUE, TRUE, TRUE, 'Klima, flip chart', 350.00,
TRUE),
('Sala za sastanke', 20, 40.00, FALSE, FALSE, TRUE, FALSE, 'Tabla, voda', 150.00,
TRUE);
INSERT INTO clients (first_name, last_name, email, phone, document_number) VALUES
('Marko', 'Markovic', 'marko.markovic@example.com', '+387 65 111 222', 'A1234567'),
('Jovana', 'Jovanovic','jovana.jovanovic@example.com','+387 66 333 444', 'B7654321'),
('Nikola', 'Nikolic', NULL, '+387 65 555 666', 'C1122334'),
('Ana', 'Anic', 'ana.anic@example.com', '+387 66 777 888', NULL),
('Petar', 'Petrovic', 'petar.petrovic@example.com', '+387 65 999 000', 'D5566778');
-- Rezervacije su namerno postavljene tako da u periodu 2026-10-01 do 2026-10-05
-- postoje i zauzeti i slobodni resursi (dobro za demonstraciju).
INSERT INTO reservations (client_id, room_id, hall_id, date_from, date_to, status, notes, created_by) VALUES
(1, 1, NULL, '2026-10-01', '2026-10-04', 'ACTIVE', 'Poslovni gost', 1),
(2, 4, NULL, '2026-10-02', '2026-10-06', 'ACTIVE', 'Porodica sa detetom', 1),
(3, NULL, 1, '2026-10-03', '2026-10-05', 'ACTIVE', 'Godišnja konferencija', 1),
(4, 2, NULL, '2026-11-10', '2026-11-12', 'ACTIVE', 'Kratak boravak', 1),
(5, 3, NULL, '2026-10-02', '2026-10-05', 'CANCELLED', 'Gost je otkazao dolazak', 1);