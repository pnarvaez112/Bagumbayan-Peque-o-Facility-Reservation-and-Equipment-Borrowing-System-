SET search_path = brgy, public;

INSERT INTO purok (purok_name) VALUES
 ('Purok 1'),('Purok 2'),('Purok 3'),('Purok 4'),('Purok 5');

INSERT INTO official (official_name, official_position) VALUES
 ('Hon. Ricardo M. Valencia',  'Punong Barangay'),
 ('Hon. Teresita B. Almario',  'Barangay Kagawad'),
 ('Corazon L. Reyes',          'Barangay Secretary'),
 ('Ernesto P. Dimaano',        'Barangay Tanod');

INSERT INTO facility (facility_name, facility_type, capacity, hourly_fee) VALUES
 ('Barangay Hall Session Room',   'Hall',          60,  100.00),
 ('Bagumbayan Covered Court',     'Covered Court', 500, 250.00),
 ('Multipurpose Hall',            'Multipurpose',  150, 150.00),
 ('Day Care Center',              'Center',        40,    0.00);

INSERT INTO equipment_category (category_name) VALUES
 ('Furniture'),('Audio-Visual'),('Tents & Canopies'),('Electrical & Accessories');

INSERT INTO equipment (equipment_name, category_id) VALUES
 ('Monobloc Chair',      1),
 ('Folding Table',       1),
 ('Canopy Tent',         3),
 ('Sound System Set',    2),
 ('Projector',           2),
 ('Extension Cord Reel', 4);

INSERT INTO equipment_item (equipment_id, item_no, asset_tag)
SELECT 1, g, 'CHR-' || lpad(g::text, 3, '0') FROM generate_series(1,10) g;
INSERT INTO equipment_item (equipment_id, item_no, asset_tag)
SELECT 2, g, 'TBL-' || lpad(g::text, 3, '0') FROM generate_series(1,5) g;
INSERT INTO equipment_item (equipment_id, item_no, asset_tag)
SELECT 3, g, 'CNP-' || lpad(g::text, 3, '0') FROM generate_series(1,3) g;
INSERT INTO equipment_item (equipment_id, item_no, asset_tag)
SELECT 4, g, 'SND-' || lpad(g::text, 3, '0') FROM generate_series(1,2) g;
INSERT INTO equipment_item (equipment_id, item_no, asset_tag) VALUES (5, 1, 'PRJ-001');
INSERT INTO equipment_item (equipment_id, item_no, asset_tag)
SELECT 6, g, 'EXT-' || lpad(g::text, 3, '0') FROM generate_series(1,3) g;

INSERT INTO resident (resident_id, first_name, last_name, contact_no, purok_id) VALUES
 ('10000000-0000-4000-8000-000000000001','Maria',   'Santos',    '09171234501', 1),
 ('10000000-0000-4000-8000-000000000002','Jose',    'Ramirez',   '09281234502', 2),
 ('10000000-0000-4000-8000-000000000003','Ana',     'Dela Cruz', '09391234503', 3),
 ('10000000-0000-4000-8000-000000000004','Roberto', 'Nacario',   '09451234504', 3),
 ('10000000-0000-4000-8000-000000000005','Liza',    'Buenaflor', '09561234505', 4),
 ('10000000-0000-4000-8000-000000000006','Mark',    'Belleza',   '09171234506', 5),
 ('10000000-0000-4000-8000-000000000007','Cristina','Orbase',    '09281234507', 2),
 ('10000000-0000-4000-8000-000000000008','Jonathan','Aguilar',   '09391234508', 1);

INSERT INTO reservation
 (reservation_id, resident_id, facility_id, official_id, purpose, start_ts, end_ts, status) VALUES
 ('a0000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001',2,1,'Barangay Basketball League Opening','2026-10-10 14:00+08','2026-10-10 20:00+08','Completed'),
 ('a0000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002',1,2,'Debut Celebration',                 '2026-10-17 10:00+08','2026-10-17 16:00+08','Completed'),
 ('a0000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000003',3,2,'Purok 3 General Assembly',          '2026-10-24 18:00+08','2026-10-24 21:00+08','Completed'),
 ('a0000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000004',2,1,'Wedding Reception',                 '2026-11-07 09:00+08','2026-11-07 15:00+08','Approved'),
 ('a0000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000005',1,NULL,'Livelihood Seminar',             '2026-11-09 08:00+08','2026-11-09 12:00+08','Pending'),
 ('a0000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000006',2,NULL,'Zumba Session (cancelled by requester)','2026-11-07 10:00+08','2026-11-07 12:00+08','Cancelled'),
 ('a0000000-0000-4000-8000-000000000007','10000000-0000-4000-8000-000000000007',3,3,'Youth Organization Meeting',        '2026-11-14 13:00+08','2026-11-14 17:00+08','Approved'),
 ('a0000000-0000-4000-8000-000000000008','10000000-0000-4000-8000-000000000008',4,NULL,'Feeding Program Orientation',     '2026-11-12 09:00+08','2026-11-12 11:00+08','Pending'),

 ('a0000000-0000-4000-8000-000000000009','10000000-0000-4000-8000-000000000001',2,1,'Senior Citizens Program',           '2026-11-07 15:00+08','2026-11-07 18:00+08','Approved');

INSERT INTO borrowing (borrow_id, resident_id, official_id, reservation_id, borrow_ts, due_ts, purpose) VALUES
 ('b0000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001',4,'a0000000-0000-4000-8000-000000000001','2026-10-09 16:00+08','2026-10-11 12:00+08','Basketball League Opening'),
 ('b0000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002',4,'a0000000-0000-4000-8000-000000000002','2026-10-16 15:00+08','2026-10-18 12:00+08','Debut Celebration'),
 ('b0000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000003',3,'a0000000-0000-4000-8000-000000000003','2026-10-24 15:00+08','2026-10-25 12:00+08','Purok 3 General Assembly'),
 ('b0000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000004',4,'a0000000-0000-4000-8000-000000000004','2026-11-01 15:00+08','2026-11-08 12:00+08','Wedding Reception'),
 ('b0000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000005',3,NULL,                                  '2026-10-28 09:00+08','2026-10-30 17:00+08','Seminar rehearsal'),
 ('b0000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000007',3,'a0000000-0000-4000-8000-000000000007','2026-10-20 10:00+08','2026-10-21 17:00+08','Youth outreach');

INSERT INTO borrow_item (borrow_id, equipment_id, item_no, returned_ts, return_condition) VALUES

 ('b0000000-0000-4000-8000-000000000001',1,1,'2026-10-11 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000001',1,2,'2026-10-11 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000001',1,3,'2026-10-11 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000001',1,4,'2026-10-11 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000001',1,5,'2026-10-11 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000001',4,1,'2026-10-11 10:00+08','Good'),

 ('b0000000-0000-4000-8000-000000000002',2,1,'2026-10-18 09:30+08','Good'),
 ('b0000000-0000-4000-8000-000000000002',2,2,'2026-10-18 09:30+08','Damaged'),
 ('b0000000-0000-4000-8000-000000000002',3,1,'2026-10-18 09:30+08','Good'),

 ('b0000000-0000-4000-8000-000000000003',1,6,'2026-10-25 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000003',1,7,'2026-10-25 10:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000003',1,8,'2026-10-25 10:00+08','Good'),

 ('b0000000-0000-4000-8000-000000000004',3,2,NULL,NULL),
 ('b0000000-0000-4000-8000-000000000004',1,1,NULL,NULL),
 ('b0000000-0000-4000-8000-000000000004',1,2,NULL,NULL),
 ('b0000000-0000-4000-8000-000000000004',1,3,NULL,NULL),
 ('b0000000-0000-4000-8000-000000000004',1,4,NULL,NULL),

 ('b0000000-0000-4000-8000-000000000005',5,1,NULL,NULL),

 ('b0000000-0000-4000-8000-000000000006',6,1,'2026-10-21 16:00+08','Good'),
 ('b0000000-0000-4000-8000-000000000006',6,2,'2026-10-22 09:00+08','Lost');

UPDATE equipment_item SET item_status = 'Retired'      WHERE equipment_id = 6 AND item_no = 2;
UPDATE equipment_item SET item_status = 'Under Repair' WHERE equipment_id = 2 AND item_no = 2;
