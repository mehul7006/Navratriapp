--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

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

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.navratri_days DISABLE TRIGGER ALL;

COPY public.navratri_days (id, day_number, date, goddess_name, dress_code, event_schedule, is_active, is_completed, created_at) FROM stdin;
8	8	2026-10-22	Mahagauri	Peacock Blue	\N	f	f	2026-08-24 22:17:11.691329
9	9	2026-10-23	Siddhidatri	Multi-color	\N	f	f	2026-08-24 22:17:11.691329
5	5	2026-10-19	Skandamata	Orange & Pink	\N	f	f	2026-08-24 22:17:11.691329
7	7	2026-10-21	Kalaratri	Black & Red	\N	f	f	2026-08-24 22:17:11.691329
6	6	2026-10-20	Katyayani	Purple & Magenta	\N	f	f	2026-08-24 22:17:11.691329
4	4	2026-10-18	Kushmanda	Green & Yellow	\N	f	f	2026-08-24 22:17:11.691329
2	2	2026-10-16	Brahmacharini	White & Silver	\N	f	f	2026-08-24 22:17:11.691329
3	3	2026-10-17	Chandraghanta	Red & Gold	\N	f	f	2026-08-24 22:17:11.691329
44	10	2026-10-24	Dussehra	Celebration Colors	\N	f	f	2026-09-06 00:46:21.911849
1	1	2026-10-15	Shailputri	Royal Blue & Bandhani	\N	t	f	2026-08-24 22:17:11.691329
\.


ALTER TABLE public.navratri_days ENABLE TRIGGER ALL;

--
-- Data for Name: aarti_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.aarti_slots DISABLE TRIGGER ALL;

COPY public.aarti_slots (id, day_number, slot_time, slot_label, max_participants, current_participants, is_active, created_at) FROM stdin;
4	2	19:00	Maha Aarti - Slot 1	5	0	t	2026-08-24 22:17:11.776873
5	2	19:30	Maha Aarti - Slot 2	5	0	t	2026-08-24 22:17:11.776873
1	1	19:00	Maha Aarti - Slot 1	5	0	f	2026-08-24 22:17:11.776873
2	1	19:30	Maha Aarti - Slot 2	5	0	f	2026-08-24 22:17:11.776873
3	1	20:00	Aarti - Slot 3	10	0	f	2026-08-24 22:17:11.776873
34	7	18:00	General Slot	50	0	t	2026-09-05 12:19:40.41504
35	6	18:00	General Slot	50	0	t	2026-09-05 14:04:02.411118
36	3	18:00	General Slot	50	0	t	2026-09-05 14:06:53.898658
37	4	18:00	General Slot	50	0	t	2026-09-05 18:01:09.452333
38	5	18:00	General Slot	50	0	t	2026-09-05 19:01:35.847262
40	10	18:00	General Slot	50	0	t	2026-09-06 14:07:55.978222
41	9	18:00	General Slot	50	0	t	2026-09-06 15:33:59.173731
\.


ALTER TABLE public.aarti_slots ENABLE TRIGGER ALL;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.users DISABLE TRIGGER ALL;

COPY public.users (id, house_number, name, mobile_number, user_type, password, profile_image, is_active, created_at, updated_at, member_type) FROM stdin;
1	admin	Organizer Admin	9999999999	organizer	admin123	\N	t	2026-08-24 22:17:11.678904	2026-08-24 22:17:11.678904	main
80	SP-ADMIN	Admin Sponsor	9999999998	sponsor	admin123	\N	t	2026-08-26 14:56:52.822862	2026-08-26 14:56:52.822862	main
81	U-ADMIN	Admin User Updated	1111111111	user	admin123	\N	t	2026-08-26 14:57:29.641322	2026-08-26 20:45:11.922074	main
\.


ALTER TABLE public.users ENABLE TRIGGER ALL;

--
-- Data for Name: aarti_bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.aarti_bookings DISABLE TRIGGER ALL;

COPY public.aarti_bookings (id, user_id, house_number, day_number, slot_id, status, notes, approved_by, approved_at, created_at) FROM stdin;
\.


ALTER TABLE public.aarti_bookings ENABLE TRIGGER ALL;

--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.announcements DISABLE TRIGGER ALL;

COPY public.announcements (id, title, message, announcement_type, priority, is_active, created_by, created_at) FROM stdin;
\.


ALTER TABLE public.announcements ENABLE TRIGGER ALL;

--
-- Data for Name: broadcasts; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.broadcasts DISABLE TRIGGER ALL;

COPY public.broadcasts (id, title, message, broadcast_type, media_url, target_audience, sent_by, sent_at) FROM stdin;
\.


ALTER TABLE public.broadcasts ENABLE TRIGGER ALL;

--
-- Data for Name: draw_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.draw_tickets DISABLE TRIGGER ALL;

COPY public.draw_tickets (id, ticket_code, user_id, house_number, day_number, is_assigned, is_winner, assigned_at, created_at) FROM stdin;
\.


ALTER TABLE public.draw_tickets ENABLE TRIGGER ALL;

--
-- Data for Name: daily_draws; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.daily_draws DISABLE TRIGGER ALL;

COPY public.daily_draws (id, day_number, draw_number, winner_ticket_id, winner_user_id, winner_house_number, prize_description, drawn_at, is_completed, created_at, draw_date, winner_id, ticket_id, drawn_by, ticket_code, house_number, prize_level, status, is_available, rescheduled_to_day, cancelled_reason, cancelled_at) FROM stdin;
\.


ALTER TABLE public.daily_draws ENABLE TRIGGER ALL;

--
-- Data for Name: daily_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.daily_schedules DISABLE TRIGGER ALL;

COPY public.daily_schedules (id, day_number, event_time, event_name, event_description, location, created_at) FROM stdin;
\.


ALTER TABLE public.daily_schedules ENABLE TRIGGER ALL;

--
-- Data for Name: expense_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.expense_categories DISABLE TRIGGER ALL;

COPY public.expense_categories (id, name, description, is_active, created_at) FROM stdin;
1	Light	Lighting and electrical expenses	t	2026-08-24 22:17:11.687841
2	Sound	Sound system and music expenses	t	2026-08-24 22:17:11.687841
3	Decoration	Decoration and setup expenses	t	2026-08-24 22:17:11.687841
4	Food & Drinks	Food and beverages	t	2026-08-24 22:17:11.687841
5	Prizes & Gifts	Prizes for winners and gifts	t	2026-08-24 22:17:11.687841
6	Miscellaneous	Other expenses	t	2026-08-24 22:17:11.687841
7	Sponsor Expense	Sponsored distributions	t	2026-09-05 00:24:48.42113
\.


ALTER TABLE public.expense_categories ENABLE TRIGGER ALL;

--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.expenses DISABLE TRIGGER ALL;

COPY public.expenses (id, category_id, item_name, amount, paid_to, payment_method, receipt_image, notes, expense_date, created_at, is_deleted, deleted_at, deleted_reason, paid_by) FROM stdin;
\.


ALTER TABLE public.expenses ENABLE TRIGGER ALL;

--
-- Data for Name: fund_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.fund_collections DISABLE TRIGGER ALL;

COPY public.fund_collections (id, user_id, house_number, amount, payment_method, payment_status, tentative_date, paid_date, received_by, receipt_number, notes, created_at, payer_name, is_deleted, deleted_at, deleted_reason) FROM stdin;
\.


ALTER TABLE public.fund_collections ENABLE TRIGGER ALL;

--
-- Data for Name: sponsors; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.sponsors DISABLE TRIGGER ALL;

COPY public.sponsors (id, user_id, company_name, advertisement_text, advertisement_image, sponsorship_amount, payment_status, start_date, end_date, is_active, created_at) FROM stdin;
\.


ALTER TABLE public.sponsors ENABLE TRIGGER ALL;

--
-- Data for Name: gifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.gifts DISABLE TRIGGER ALL;

COPY public.gifts (id, name, description, sponsor_id, gift_type, day_number, quantity, quantity_assigned, is_active, created_at) FROM stdin;
\.


ALTER TABLE public.gifts ENABLE TRIGGER ALL;

--
-- Data for Name: gift_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.gift_assignments DISABLE TRIGGER ALL;

COPY public.gift_assignments (id, gift_id, user_id, house_number, day_number, assigned_by, notes, assigned_at, status) FROM stdin;
\.


ALTER TABLE public.gift_assignments ENABLE TRIGGER ALL;

--
-- Data for Name: shoutout_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shoutout_reactions DISABLE TRIGGER ALL;

COPY public.shoutout_reactions (id, shoutout_id, user_id, reaction, created_at) FROM stdin;
\.


ALTER TABLE public.shoutout_reactions ENABLE TRIGGER ALL;

--
-- Data for Name: shoutouts; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shoutouts DISABLE TRIGGER ALL;

COPY public.shoutouts (id, from_user_id, to_user_id, message, emoji, day_number, shoutout_type, is_approved, created_at) FROM stdin;
\.


ALTER TABLE public.shoutouts ENABLE TRIGGER ALL;

--
-- Data for Name: snacks; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.snacks DISABLE TRIGGER ALL;

COPY public.snacks (id, name, description, price, quantity_available, quantity_sold, is_vegetarian, is_active, created_at) FROM stdin;
\.


ALTER TABLE public.snacks ENABLE TRIGGER ALL;

--
-- Data for Name: snack_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.snack_orders DISABLE TRIGGER ALL;

COPY public.snack_orders (id, user_id, house_number, snack_id, day_number, quantity, total_price, status, notes, created_at) FROM stdin;
\.


ALTER TABLE public.snack_orders ENABLE TRIGGER ALL;

--
-- Data for Name: song_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.song_requests DISABLE TRIGGER ALL;

COPY public.song_requests (id, user_id, song_name, youtube_link, day_number, request_type, status, request_count, played_at, created_at) FROM stdin;
\.


ALTER TABLE public.song_requests ENABLE TRIGGER ALL;

--
-- Data for Name: song_suggestions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.song_suggestions DISABLE TRIGGER ALL;

COPY public.song_suggestions (id, user_id, song_name, youtube_link, target_day, upvotes, created_at) FROM stdin;
\.


ALTER TABLE public.song_suggestions ENABLE TRIGGER ALL;

--
-- Data for Name: song_upvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.song_upvotes DISABLE TRIGGER ALL;

COPY public.song_upvotes (id, song_suggestion_id, user_id, created_at) FROM stdin;
\.


ALTER TABLE public.song_upvotes ENABLE TRIGGER ALL;

--
-- Name: aarti_bookings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aarti_bookings_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.daily_draws_id_seq', 1, false);


--
-- Name: daily_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.daily_schedules_id_seq', 1, false);


--
-- Name: draw_tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.draw_tickets_id_seq', 1, false);


--
-- Name: expense_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_categories_id_seq', 33, true);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expenses_id_seq', 1, false);


--
-- Name: fund_collections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fund_collections_id_seq', 1, false);


--
-- Name: gift_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gift_assignments_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.shoutout_reactions_id_seq', 1, false);


--
-- Name: shoutouts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shoutouts_id_seq', 1, false);


--
-- Name: snack_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.snack_orders_id_seq', 1, true);


--
-- Name: snacks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.snacks_id_seq', 1, false);


--
-- Name: song_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.song_requests_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.users_id_seq', 100, false);


--
-- PostgreSQL database dump complete
--

