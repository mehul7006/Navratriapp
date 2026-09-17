--
-- PostgreSQL database dump
--

\restrict i0vcT125iol4ChsZZaqISiLSYQkBh0Zc8xBAPjt5ej4XyTJsXMdH4MjXKQh8niM

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: navratri_days; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.navratri_days VALUES (8, 8, '2026-10-22', 'Mahagauri', 'Peacock Blue', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (9, 9, '2026-10-23', 'Siddhidatri', 'Multi-color', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (5, 5, '2026-10-19', 'Skandamata', 'Orange & Pink', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (7, 7, '2026-10-21', 'Kalaratri', 'Black & Red', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (6, 6, '2026-10-20', 'Katyayani', 'Purple & Magenta', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (44, 10, '2026-10-24', 'Dussehra', 'Celebration Colors', NULL, false, false, '2026-09-06 00:46:21.911849', 3);
INSERT INTO public.navratri_days VALUES (4, 4, '2026-10-18', 'Kushmanda', 'Green & Yellow', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (3, 3, '2026-10-17', 'Chandraghanta', 'Red & Gold', NULL, false, false, '2026-08-24 22:17:11.691329', 3);
INSERT INTO public.navratri_days VALUES (1, 1, '2026-10-15', 'Shailputri', 'Royal Blue & Bandhani', NULL, true, false, '2026-08-24 22:17:11.691329', 5);
INSERT INTO public.navratri_days VALUES (2, 2, '2026-10-16', 'Brahmacharini', 'White & Silver', NULL, false, false, '2026-08-24 22:17:11.691329', 3);


--
-- Data for Name: aarti_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.aarti_slots VALUES (4, 2, '19:00', 'Maha Aarti - Slot 1', 5, 0, true, '2026-08-24 22:17:11.776873');
INSERT INTO public.aarti_slots VALUES (5, 2, '19:30', 'Maha Aarti - Slot 2', 5, 0, true, '2026-08-24 22:17:11.776873');
INSERT INTO public.aarti_slots VALUES (1, 1, '19:00', 'Maha Aarti - Slot 1', 5, 0, false, '2026-08-24 22:17:11.776873');
INSERT INTO public.aarti_slots VALUES (2, 1, '19:30', 'Maha Aarti - Slot 2', 5, 0, false, '2026-08-24 22:17:11.776873');
INSERT INTO public.aarti_slots VALUES (3, 1, '20:00', 'Aarti - Slot 3', 10, 0, false, '2026-08-24 22:17:11.776873');
INSERT INTO public.aarti_slots VALUES (34, 7, '18:00', 'General Slot', 50, 0, true, '2026-09-05 12:19:40.41504');
INSERT INTO public.aarti_slots VALUES (35, 6, '18:00', 'General Slot', 50, 0, true, '2026-09-05 14:04:02.411118');
INSERT INTO public.aarti_slots VALUES (36, 3, '18:00', 'General Slot', 50, 0, true, '2026-09-05 14:06:53.898658');
INSERT INTO public.aarti_slots VALUES (37, 4, '18:00', 'General Slot', 50, 0, true, '2026-09-05 18:01:09.452333');
INSERT INTO public.aarti_slots VALUES (38, 5, '18:00', 'General Slot', 50, 0, true, '2026-09-05 19:01:35.847262');
INSERT INTO public.aarti_slots VALUES (40, 10, '18:00', 'General Slot', 50, 0, true, '2026-09-06 14:07:55.978222');
INSERT INTO public.aarti_slots VALUES (41, 9, '18:00', 'General Slot', 50, 0, true, '2026-09-06 15:33:59.173731');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES (1, 'admin', 'Organizer Admin', '9999999999', 'organizer', 'admin123', NULL, true, '2026-08-24 22:17:11.678904', '2026-08-24 22:17:11.678904', 'main');
INSERT INTO public.users VALUES (80, 'SP-ADMIN', 'Admin Sponsor', '9999999998', 'sponsor', 'admin123', NULL, true, '2026-08-26 14:56:52.822862', '2026-08-26 14:56:52.822862', 'main');
INSERT INTO public.users VALUES (81, 'U-ADMIN', 'Admin User Updated', '1111111111', 'user', 'admin123', NULL, true, '2026-08-26 14:57:29.641322', '2026-08-26 20:45:11.922074', 'main');
INSERT INTO public.users VALUES (102, 'B450', 'raj', '0000000000', 'user', NULL, NULL, true, '2026-09-07 01:06:13.144538', '2026-09-07 01:06:13.144538', 'main');
INSERT INTO public.users VALUES (103, 'B451', 'mangilal', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:14:06.117875', '2026-09-10 01:14:06.117875', 'main');
INSERT INTO public.users VALUES (104, 'B452', 'jagdishbhai', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:14:26.040083', '2026-09-10 01:14:26.040083', 'main');
INSERT INTO public.users VALUES (105, 'B453', 'somabhai', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:14:36.618157', '2026-09-10 01:14:36.618157', 'main');
INSERT INTO public.users VALUES (106, 'B454', 'sureshbhai', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:14:51.792484', '2026-09-10 01:14:51.792484', 'main');
INSERT INTO public.users VALUES (107, 'B455', 'shambhubhai', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:15:09.753892', '2026-09-10 01:15:09.753892', 'main');
INSERT INTO public.users VALUES (108, 'B437', 'mehul2', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:16:07.147841', '2026-09-10 01:16:07.147841', 'sub');
INSERT INTO public.users VALUES (109, 'B453', 'jaimin', '0000000000', 'user', NULL, NULL, true, '2026-09-10 01:17:40.948822', '2026-09-10 01:17:40.948822', 'sub');
INSERT INTO public.users VALUES (110, 'B478', 'jayraj', '0000000000', 'user', NULL, NULL, true, '2026-09-10 20:15:00.637351', '2026-09-10 20:15:00.637351', 'main');
INSERT INTO public.users VALUES (100, 'B437', 'mehul', '0123456789', 'user', NULL, NULL, true, '2026-09-07 01:05:32.816922', '2026-09-11 22:29:14.064332', 'main');
INSERT INTO public.users VALUES (101, 'B440', 'rahul', '1231231231', 'user', NULL, NULL, true, '2026-09-07 01:05:46.618117', '2026-09-16 20:31:53.15852', 'main');
INSERT INTO public.users VALUES (111, 'B300', 'abcd', '0000000000', 'user', NULL, NULL, true, '2026-09-17 00:37:04.540747', '2026-09-17 00:37:04.540747', 'main');


--
-- Data for Name: aarti_bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.aarti_bookings VALUES (2, NULL, 'B437', 1, NULL, 'cancelled', 'Booked by organizer for mehull', NULL, '2026-09-06 18:55:59.322973', '2026-09-07 00:22:15.863318');
INSERT INTO public.aarti_bookings VALUES (3, NULL, 'B300', 6, NULL, 'approved', 'Booked by organizer for Hada', NULL, '2026-09-06 19:06:39.649591', '2026-09-07 00:36:33.727838');
INSERT INTO public.aarti_bookings VALUES (4, NULL, 'B350', 3, NULL, 'approved', 'Booked by organizer for hada', NULL, '2026-09-06 19:07:14.566994', '2026-09-07 00:36:59.744072');
INSERT INTO public.aarti_bookings VALUES (7, 108, 'B437', 6, NULL, 'approved', '[B437] |day:6|booked_by:organizer', NULL, '2026-09-10 19:21:57.531548', '2026-09-11 00:51:45.14474');
INSERT INTO public.aarti_bookings VALUES (8, 101, 'B440', 2, NULL, 'pending', '[B440] |day:2|booked_by:organizer', NULL, NULL, '2026-09-11 00:55:28.41954');
INSERT INTO public.aarti_bookings VALUES (5, NULL, 'B437', 1, NULL, 'cancelled', 'Booked by organizer for mehul', NULL, '2026-09-06 19:13:14.529274', '2026-09-07 00:43:12.674113');
INSERT INTO public.aarti_bookings VALUES (6, 100, 'B437', 1, NULL, 'cancelled', NULL, NULL, '2026-09-10 19:25:38.546536', '2026-09-11 00:22:41.233639');
INSERT INTO public.aarti_bookings VALUES (9, 100, 'B437', 3, NULL, 'cancelled', '[B437] |day:3|booked_by:organizer', NULL, NULL, '2026-09-11 23:33:55.544141');
INSERT INTO public.aarti_bookings VALUES (10, 100, 'B437', 3, NULL, 'cancelled', '[B437] |day:3|booked_by:organizer', NULL, NULL, '2026-09-11 23:33:57.18426');
INSERT INTO public.aarti_bookings VALUES (11, 100, 'B437', 3, NULL, 'cancelled', '[B437] |day:3|booked_by:organizer', NULL, NULL, '2026-09-11 23:33:58.55203');
INSERT INTO public.aarti_bookings VALUES (12, 100, 'B437', 5, NULL, 'approved', '[B437] mehul|day:5|booked_by:organizer', NULL, '2026-09-14 14:00:38.92987', '2026-09-12 00:47:55.287979');
INSERT INTO public.aarti_bookings VALUES (15, 100, 'B437', 6, NULL, 'approved', '[B437] mehul|day:6|booked_by:organizer', NULL, '2026-09-14 14:00:47.380353', '2026-09-12 01:10:33.176724');
INSERT INTO public.aarti_bookings VALUES (14, 100, 'B437', 6, NULL, 'approved', '[B437] mehul|day:6|booked_by:organizer', NULL, '2026-09-14 14:00:48.202226', '2026-09-12 01:10:32.391853');
INSERT INTO public.aarti_bookings VALUES (13, 100, 'B437', 9, NULL, 'approved', '[B437] mehul|day:9|booked_by:organizer', NULL, '2026-09-14 14:00:53.2157', '2026-09-12 01:07:53.732387');
INSERT INTO public.aarti_bookings VALUES (16, 108, 'B437', 3, NULL, 'approved', '[B437] |day:3|booked_by:organizer', NULL, '2026-09-14 14:01:37.20477', '2026-09-14 19:31:24.758144');
INSERT INTO public.aarti_bookings VALUES (18, 100, 'B437', 3, NULL, 'cancelled', '[B437] mehul|day:3|booked_by:organizer', NULL, NULL, '2026-09-14 22:22:32.767819');
INSERT INTO public.aarti_bookings VALUES (19, 100, 'B437', 4, NULL, 'pending', '[B437] mehul|day:4|booked_by:organizer', NULL, NULL, '2026-09-14 22:34:24.980328');
INSERT INTO public.aarti_bookings VALUES (20, 100, 'B437', 7, NULL, 'pending', '[B437] mehul|day:7|booked_by:organizer', NULL, NULL, '2026-09-15 00:52:45.959953');
INSERT INTO public.aarti_bookings VALUES (21, 101, 'B440', 4, NULL, 'pending', '[B440] rahul|day:4|booked_by:organizer', NULL, NULL, '2026-09-16 21:10:31.867379');
INSERT INTO public.aarti_bookings VALUES (22, 101, 'B440', 4, NULL, 'pending', '[B440] rahul|day:4|booked_by:organizer', NULL, NULL, '2026-09-16 21:10:36.068028');


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: broadcasts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: draw_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.draw_tickets VALUES (1, '2026100001', 100, 'B437', 1, true, false, '2026-09-09 19:45:49.551707', '2026-09-10 01:15:29.422694');
INSERT INTO public.draw_tickets VALUES (2, '2026100002', 108, 'B437', 1, true, false, '2026-09-09 19:46:08.630559', '2026-09-10 01:15:29.430385');
INSERT INTO public.draw_tickets VALUES (4, '2026100004', 102, 'B450', 1, true, false, '2026-09-09 19:46:41.68673', '2026-09-10 01:15:29.435521');
INSERT INTO public.draw_tickets VALUES (9, '2026100009', 107, 'B455', 1, true, false, '2026-09-09 19:47:53.564824', '2026-09-10 01:15:29.449112');
INSERT INTO public.draw_tickets VALUES (6, '2026100006', 104, 'B452', 1, true, true, '2026-09-09 19:47:14.429725', '2026-09-10 01:15:29.440538');
INSERT INTO public.draw_tickets VALUES (3, '2026100003', 101, 'B440', 1, true, true, '2026-09-09 19:46:28.577386', '2026-09-10 01:15:29.43298');
INSERT INTO public.draw_tickets VALUES (11, '2026100011', 110, 'B478', 1, true, false, '2026-09-10 14:46:08.401608', '2026-09-10 20:15:30.054688');
INSERT INTO public.draw_tickets VALUES (7, '2026100007', 105, 'B453', 1, true, false, '2026-09-09 19:47:25.348883', '2026-09-10 01:15:29.443163');
INSERT INTO public.draw_tickets VALUES (8, '2026100008', 109, 'B453', 1, true, false, '2026-09-09 19:47:42.723964', '2026-09-10 01:15:29.445759');
INSERT INTO public.draw_tickets VALUES (5, '2026100005', 103, 'B451', 1, true, true, '2026-09-09 19:46:58.22425', '2026-09-10 01:15:29.437864');
INSERT INTO public.draw_tickets VALUES (10, '2026100010', 106, 'B454', 1, true, true, '2026-09-09 19:48:07.667963', '2026-09-10 01:15:29.453321');
INSERT INTO public.draw_tickets VALUES (12, '2026100012', 100, 'B437', 10, true, false, '2026-09-11 16:14:41.297196', '2026-09-11 21:36:51.222848');
INSERT INTO public.draw_tickets VALUES (16, '2026100016', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.588748');
INSERT INTO public.draw_tickets VALUES (17, '2026100017', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.59278');
INSERT INTO public.draw_tickets VALUES (18, '2026100018', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.596936');
INSERT INTO public.draw_tickets VALUES (19, '2026100019', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.600895');
INSERT INTO public.draw_tickets VALUES (20, '2026100020', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.60504');
INSERT INTO public.draw_tickets VALUES (21, '2026100021', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.60896');
INSERT INTO public.draw_tickets VALUES (22, '2026100022', NULL, NULL, 3, false, false, NULL, '2026-09-17 00:37:24.613535');
INSERT INTO public.draw_tickets VALUES (14, '2026100014', 101, 'B440', 3, true, false, '2026-09-16 19:08:28.189694', '2026-09-17 00:37:24.579829');
INSERT INTO public.draw_tickets VALUES (13, '2026100013', 101, 'B440', 4, true, false, '2026-09-16 20:34:05.071638', '2026-09-17 00:37:24.571782');


--
-- Data for Name: daily_draws; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.daily_draws VALUES (1, 1, 1, NULL, NULL, NULL, NULL, '2026-09-10 01:18:22.051586', false, '2026-09-10 01:18:22.051586', '2026-09-10', 104, 6, 1, '2026100006', 'B452', 3, 'confirmed', true, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (3, 1, 3, NULL, NULL, NULL, NULL, '2026-09-10 01:18:41.704945', false, '2026-09-10 01:18:41.704945', '2026-09-10', 101, 3, 1, '2026100003', 'B440', 1, 'confirmed', true, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (5, 1, 5, NULL, NULL, NULL, NULL, '2026-09-10 01:29:59.178579', false, '2026-09-10 01:29:59.178579', '2026-09-10', 108, 2, 1, '2026100002', 'B437', NULL, 'drawn', NULL, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (4, 1, 4, NULL, NULL, NULL, NULL, '2026-09-10 01:18:54.192976', false, '2026-09-10 01:18:54.192976', '2026-09-10', 105, 7, 1, '2026100007', 'B453', NULL, 'cancelled', true, NULL, 'dfdf', '2026-09-10 20:20:08.714454');
INSERT INTO public.daily_draws VALUES (2, 1, 2, NULL, NULL, NULL, NULL, '2026-09-10 01:18:33.912495', false, '2026-09-10 01:18:33.912495', '2026-09-10', 109, 8, 1, '2026100008', 'B453', 2, 'cancelled', true, NULL, 'asdasdasd', '2026-09-10 20:20:15.466563');
INSERT INTO public.daily_draws VALUES (7, 1, 7, NULL, NULL, NULL, NULL, '2026-09-10 21:26:30.899205', false, '2026-09-10 21:26:30.899205', '2026-09-10', 106, 10, 1, '2026100010', 'B454', NULL, 'drawn', NULL, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (6, 1, 6, NULL, NULL, NULL, NULL, '2026-09-10 21:25:59.577275', false, '2026-09-10 21:25:59.577275', '2026-09-10', 103, 5, 1, '2026100005', 'B451', 2, 'confirmed', true, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (8, 1, 8, NULL, NULL, NULL, NULL, '2026-09-10 21:55:21.76282', false, '2026-09-10 21:55:21.76282', '2026-09-10', 106, 10, 1, '2026100010', 'B454', NULL, 'confirmed', true, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (9, 10, 1, NULL, NULL, NULL, NULL, '2026-09-11 21:44:57.020216', false, '2026-09-11 21:44:57.020216', '2026-09-11', 100, 12, 1, '2026100012', 'B437', NULL, 'drawn', NULL, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (10, 3, 1, NULL, NULL, NULL, NULL, '2026-09-17 02:02:54.702549', false, '2026-09-17 02:02:54.702549', '2026-09-17', 101, 14, 1, '2026100014', 'B440', NULL, 'drawn', NULL, NULL, NULL, NULL);
INSERT INTO public.daily_draws VALUES (11, 4, 1, NULL, NULL, NULL, NULL, '2026-09-17 02:04:15.975345', false, '2026-09-17 02:04:15.975345', '2026-09-17', 101, 13, 1, '2026100013', 'B440', NULL, 'drawn', NULL, NULL, NULL, NULL);


--
-- Data for Name: daily_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: expense_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.expense_categories VALUES (1, 'Light', 'Lighting and electrical expenses', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (2, 'Sound', 'Sound system and music expenses', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (3, 'Decoration', 'Decoration and setup expenses', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (4, 'Food & Drinks', 'Food and beverages', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (5, 'Prizes & Gifts', 'Prizes for winners and gifts', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (6, 'Miscellaneous', 'Other expenses', true, '2026-08-24 22:17:11.687841');
INSERT INTO public.expense_categories VALUES (7, 'Sponsor Expense', 'Sponsored distributions', true, '2026-09-05 00:24:48.42113');


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.expenses VALUES (1, 4, 'Snack Distribution - B437', 0.00, NULL, 'cash', NULL, 'Auto:  (B437) approved snack day 1', '2026-10-15', '2026-09-07 01:10:51.077543', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (2, 7, 'Sponsor Distribution - mehul', 0.00, 'mehul', 'cash', NULL, 'Day 1 - samosa', '2026-09-07', '2026-09-07 01:10:51.098468', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (5, 4, 'Snack Distribution - ORGANIZOR', 0.00, NULL, 'cash', NULL, 'Auto:  (ORGANIZOR) approved snack day 1', '2026-10-15', '2026-09-07 01:21:27.613487', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (6, 4, 'Snack Distribution - self', 500.00, 'self', 'cash', NULL, 'Day 1 - patra', '2026-09-07', '2026-09-07 01:21:27.623384', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (3, 7, 'Snack Distribution - B450', 0.00, '.', 'cash', NULL, 'Auto:  (B450) approved snack day 2', '2026-10-16', '2026-09-07 01:20:32.245911', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (7, 7, 'Sponsor Distribution - mehul', 0.00, 'mehul', 'cash', NULL, 'Day 1 - ', '2026-09-10', '2026-09-10 00:49:20.626311', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (8, 5, '[Organizer] (B440) rahul - poket', 50.00, 'rahul', 'cash', NULL, 'Day 1 - poket', '2026-09-10', '2026-09-10 01:09:02.363291', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (9, 4, '[Organizer] Snack: samosa - mehul (B437)', 500.00, 'mehul', 'cash', NULL, 'Day 3 - samosa distributed to mehul (B437)', '2026-09-14', '2026-09-14 19:57:44.425281', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (10, 7, '[Sponsor] Snack: Day 4 - rahu (B400)', 0.00, 'rahu', 'cash', NULL, 'Day 4 - Snack distributed to rahu (B400)', '2026-09-14', '2026-09-14 19:58:03.294639', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (11, 5, '[Organizer] Gift: Day 3 - kkbk (B401)', 100.00, 'kkbk', 'cash', NULL, 'Day 3 - Gift donated by kkbk (B401)', '2026-09-14', '2026-09-14 19:59:56.468589', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (12, 7, '[Sponsor] Gift: Day 3 - mehul (B437)', 0.00, 'mehul', 'cash', NULL, 'Day 3 - Gift donated by mehul (B437)', '2026-09-14', '2026-09-14 20:00:18.555467', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (13, 4, '[Organizer] Snack: samosa - yuvak mandal (B444)', 500.00, 'yuvak mandal', 'cash', NULL, 'Day 5 - samosa distributed to yuvak mandal (B444)', '2026-09-16', '2026-09-16 20:22:36.995551', false, NULL, NULL, 'organizer');
INSERT INTO public.expenses VALUES (15, 4, '[Organizer] Snack: samosa - organizer (ORGANIER)', 5000.00, 'organizer', 'cash', NULL, 'Day 4 - samosa distributed to organizer (ORGANIER)', '2026-09-16', '2026-09-16 20:30:12.833389', false, NULL, NULL, 'organizer');


--
-- Data for Name: fund_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.fund_collections VALUES (1, 100, 'B437', 5000.00, 'cash', 'paid', NULL, '2026-09-07', NULL, NULL, NULL, '2026-09-07 01:05:32.871485', 'mehul', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (2, 101, 'B440', 15000.00, 'online', 'paid', NULL, '2026-09-07', NULL, NULL, NULL, '2026-09-07 01:05:46.650815', 'rahul', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (3, 102, 'B450', 6000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-07 01:06:13.178484', 'raj', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (4, 103, 'B451', 1000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 01:14:06.175938', 'mangilal', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (5, 104, 'B452', 1000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 01:14:26.093566', 'jagdishbhai', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (6, 105, 'B453', 1000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 01:14:36.673584', 'somabhai', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (7, 106, 'B454', 1000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 01:14:51.84758', 'sureshbhai', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (8, 107, 'B455', 1000.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 01:15:09.809049', 'shambhubhai', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (9, 110, 'B478', 1500.00, 'cash', 'paid', NULL, '2026-09-10', NULL, NULL, NULL, '2026-09-10 20:15:00.727283', 'jayraj', false, NULL, NULL);
INSERT INTO public.fund_collections VALUES (10, 111, 'B300', 500.00, 'cash', 'paid', NULL, '2026-09-17', NULL, NULL, NULL, '2026-09-17 00:37:04.831327', 'abcd', false, NULL, NULL);


--
-- Data for Name: sponsors; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: gifts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: gift_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.gift_assignments VALUES (36, NULL, NULL, 'B437', 1, NULL, '[B437] mehul|SPONSOR_EXPENSE:0:mehul', '2026-09-10 00:21:24.786409', 'approved', '');
INSERT INTO public.gift_assignments VALUES (3, NULL, NULL, 'B437', 1, NULL, '[B437] mehul - aa|SPONSOR_EXPENSE:0:mehul', '2026-09-07 02:04:46.433054', 'rejected', '');
INSERT INTO public.gift_assignments VALUES (37, NULL, NULL, 'B437', 2, NULL, '[B437] mehul|SPONSOR_EXPENSE:0:mehul', '2026-09-10 00:22:17.999379', 'rejected', '');
INSERT INTO public.gift_assignments VALUES (38, NULL, NULL, 'B437', 3, NULL, '[B437] mehul', '2026-09-10 00:49:37.765203', 'approved', '');
INSERT INTO public.gift_assignments VALUES (39, NULL, NULL, 'B440', 1, NULL, '[B440] rahul - poket|ORG_EXPENSE:50:Gifts', '2026-09-10 01:08:58.890897', 'approved', '');
INSERT INTO public.gift_assignments VALUES (40, NULL, NULL, 'B401', 3, NULL, '[B401] kkbk|ORG_EXPENSE:100:Gifts', '2026-09-14 19:59:51.370197', 'rejected', '');
INSERT INTO public.gift_assignments VALUES (41, NULL, NULL, 'B437', 3, NULL, '[B437] mehul|SPONSOR_EXPENSE:0:mehul', '2026-09-14 20:00:16.590352', 'approved', '');
INSERT INTO public.gift_assignments VALUES (44, NULL, 100, 'B437', 4, NULL, '', '2026-09-15 00:44:48.927759', 'approved', 'kachori');
INSERT INTO public.gift_assignments VALUES (43, NULL, 100, 'B437', 4, NULL, '', '2026-09-15 00:36:35.167528', 'approved', 'JALEBI');
INSERT INTO public.gift_assignments VALUES (42, NULL, 100, 'B437', 4, NULL, '', '2026-09-15 00:36:13.913657', 'approved', 'FAFDA');
INSERT INTO public.gift_assignments VALUES (45, NULL, 100, 'B437', 7, NULL, '', '2026-09-15 00:52:16.751681', 'approved', 'samosa');
INSERT INTO public.gift_assignments VALUES (46, NULL, 101, 'B440', 4, NULL, '', '2026-09-16 20:32:52.192583', 'approved', 'asasasas');


--
-- Data for Name: shoutout_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.shoutout_reactions VALUES (1, 1, 101, '🔥', '2026-09-17 19:10:12.997986');
INSERT INTO public.shoutout_reactions VALUES (6, 1, 101, '💪', '2026-09-17 19:10:14.716856');
INSERT INTO public.shoutout_reactions VALUES (8, 1, 101, '👏', '2026-09-17 19:10:15.827069');
INSERT INTO public.shoutout_reactions VALUES (11, 1, 101, '❤️', '2026-09-17 19:10:16.644461');


--
-- Data for Name: shoutouts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.shoutouts VALUES (1, 100, 101, 'zdasdasdasdasdasd', '#', 1, 'general', true, '2026-09-15 11:48:33.508146');


--
-- Data for Name: snacks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.snacks VALUES (1, 'Samosa', 'Crispy fried pastry with spiced filling', 20.00, 50, 0, true, true, '2026-09-14 19:36:12.43862');
INSERT INTO public.snacks VALUES (2, 'Patra', 'Steamed gram flour snack', 15.00, 40, 0, true, true, '2026-09-14 19:36:12.43862');
INSERT INTO public.snacks VALUES (3, 'Fafda', 'Crispy gram flour snack', 25.00, 30, 0, true, true, '2026-09-14 19:36:12.43862');
INSERT INTO public.snacks VALUES (4, 'Dhokla', 'Steamed fermented gram flour cake', 30.00, 25, 0, true, true, '2026-09-14 19:36:12.43862');
INSERT INTO public.snacks VALUES (5, 'Jalebi', 'Sweet crispy spiral dessert', 40.00, 20, 0, true, true, '2026-09-14 19:36:12.43862');
INSERT INTO public.snacks VALUES (6, 'Chai', 'Masala tea', 10.00, 100, 0, true, true, '2026-09-14 19:36:12.43862');


--
-- Data for Name: snack_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.snack_orders VALUES (2, NULL, 'B437', NULL, 1, 1, NULL, 'approved', '[B437] mehul - samosa|SPONSOR_EXPENSE:0:mehul', '2026-09-07 01:10:44.942206', NULL);
INSERT INTO public.snack_orders VALUES (3, NULL, 'B450', NULL, 2, 1, NULL, 'rejected', '[B450] raj - pakoda|SPONSOR_EXPENSE:0:raj', '2026-09-07 01:20:27.302541', NULL);
INSERT INTO public.snack_orders VALUES (4, NULL, 'ORGANIZOR', NULL, 1, 1, NULL, 'approved', '[ORGANIZOR] self - patra|ORG_EXPENSE:500:Snacks', '2026-09-07 01:21:23.955566', NULL);
INSERT INTO public.snack_orders VALUES (5, 0, 'B437', 6, 3, 1, NULL, 'approved', '[B437] mehul - samosa|ORG_EXPENSE:500:Snacks', '2026-09-14 19:57:42.508033', NULL);
INSERT INTO public.snack_orders VALUES (6, 0, 'B400', 6, 4, 1, NULL, 'approved', '[B400] rahu|SPONSOR_EXPENSE:0:rahu', '2026-09-14 19:58:00.311657', NULL);
INSERT INTO public.snack_orders VALUES (8, 0, 'B400', 6, 4, 1, NULL, 'rejected', '[B400] rahu|SPONSOR_EXPENSE:0:rahu', '2026-09-14 19:58:45.508591', NULL);
INSERT INTO public.snack_orders VALUES (7, 0, 'B400', 6, 4, 1, NULL, 'rejected', '[B400] rahu|SPONSOR_EXPENSE:0:rahu', '2026-09-14 19:58:45.345084', NULL);
INSERT INTO public.snack_orders VALUES (9, 108, 'B437', 1, 3, 1, NULL, 'approved', '', '2026-09-14 23:01:21.295355', 'chai');
INSERT INTO public.snack_orders VALUES (11, 100, 'B437', 1, 6, 1, NULL, 'approved', '', '2026-09-14 23:39:30.881805', 'chai');
INSERT INTO public.snack_orders VALUES (10, 108, 'B437', 1, 3, 1, NULL, 'approved', '', '2026-09-14 23:19:03.769539', 'cahi');
INSERT INTO public.snack_orders VALUES (12, 100, 'B437', 1, 8, 1, NULL, 'approved', '', '2026-09-15 00:53:03.465907', 'samosa');
INSERT INTO public.snack_orders VALUES (13, 0, 'B444', 6, 5, 1, NULL, 'approved', '[B444] yuvak mandal - samosa|ORG_EXPENSE:500:Snacks', '2026-09-16 20:22:34.717888', '');
INSERT INTO public.snack_orders VALUES (14, 0, 'B450', 6, 5, 1, NULL, 'approved', '[B450] raj - pani puri|SPONSOR_EXPENSE:0:raj', '2026-09-16 20:22:56.616159', '');
INSERT INTO public.snack_orders VALUES (16, 0, 'B469', 6, 4, 1, NULL, 'approved', '[B469] kavi - kachori|SPONSOR_EXPENSE:0:kavi', '2026-09-16 20:30:08.377311', '');
INSERT INTO public.snack_orders VALUES (15, 0, 'ORGANIER', 6, 4, 1, NULL, 'approved', '[ORGANIER] organizer - samosa|ORG_EXPENSE:5000:Snacks', '2026-09-16 20:29:40.320946', '');
INSERT INTO public.snack_orders VALUES (17, 101, 'B440', 1, 4, 1, NULL, 'approved', '', '2026-09-16 20:32:35.117862', 'aaaaaaaaaaa');


--
-- Data for Name: song_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.song_requests VALUES (1, 100, 'sasasas', '', 10, 'live', 'pending', 1, NULL, '2026-09-15 11:48:14.803084');


--
-- Data for Name: song_suggestions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: song_upvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: aarti_bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aarti_bookings_id_seq', 22, true);


--
-- Name: aarti_slots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aarti_slots_id_seq', 41, true);


--
-- Name: announcements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.announcements_id_seq', 1, false);


--
-- Name: broadcasts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.broadcasts_id_seq', 1, false);


--
-- Name: daily_draws_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.daily_draws_id_seq', 11, true);


--
-- Name: daily_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.daily_schedules_id_seq', 1, false);


--
-- Name: draw_tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.draw_tickets_id_seq', 22, true);


--
-- Name: expense_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_categories_id_seq', 33, true);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expenses_id_seq', 15, true);


--
-- Name: fund_collections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fund_collections_id_seq', 10, true);


--
-- Name: gift_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gift_assignments_id_seq', 46, true);


--
-- Name: gifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gifts_id_seq', 1, false);


--
-- Name: navratri_days_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.navratri_days_id_seq', 111, true);


--
-- Name: shoutout_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shoutout_reactions_id_seq', 15, true);


--
-- Name: shoutouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shoutouts_id_seq', 1, true);


--
-- Name: snack_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.snack_orders_id_seq', 17, true);


--
-- Name: snacks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.snacks_id_seq', 6, true);


--
-- Name: song_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.song_requests_id_seq', 1, true);


--
-- Name: song_suggestions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.song_suggestions_id_seq', 1, false);


--
-- Name: song_upvotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.song_upvotes_id_seq', 1, false);


--
-- Name: sponsors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sponsors_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 111, true);


--
-- PostgreSQL database dump complete
--

\unrestrict i0vcT125iol4ChsZZaqISiLSYQkBh0Zc8xBAPjt5ej4XyTJsXMdH4MjXKQh8niM

