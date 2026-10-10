CREATE OR REPLACE FUNCTION public.update_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$

--
-- PostgreSQL database dump
--

\restrict NuHmSJuPhKG8yeEph2hGcFiTstavgrVwrQD8DaKGRQ5oFiFdkeoL2uq9BJOOSJu

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aarti_bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aarti_bookings (
    id integer NOT NULL,
    user_id integer,
    house_number character varying(50) NOT NULL,
    day_number integer NOT NULL,
    slot_id integer,
    status character varying(20) DEFAULT 'pending'::character varying,
    notes text,
    approved_by integer,
    approved_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.aarti_bookings OWNER TO postgres;

--
-- Name: aarti_bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aarti_bookings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aarti_bookings_id_seq OWNER TO postgres;

--
-- Name: aarti_bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aarti_bookings_id_seq OWNED BY public.aarti_bookings.id;


--
-- Name: aarti_slots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aarti_slots (
    id integer NOT NULL,
    day_number integer NOT NULL,
    slot_time character varying(20) NOT NULL,
    slot_label character varying(100),
    max_participants integer DEFAULT 1,
    current_participants integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.aarti_slots OWNER TO postgres;

--
-- Name: aarti_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aarti_slots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aarti_slots_id_seq OWNER TO postgres;

--
-- Name: aarti_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aarti_slots_id_seq OWNED BY public.aarti_slots.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.announcements (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    announcement_type character varying(50) DEFAULT 'general'::character varying,
    priority integer DEFAULT 1,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.announcements OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.announcements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.announcements_id_seq OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: broadcasts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.broadcasts (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    broadcast_type character varying(20) DEFAULT 'text'::character varying,
    media_url text,
    target_audience character varying(20) DEFAULT 'all'::character varying,
    sent_by integer,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.broadcasts OWNER TO postgres;

--
-- Name: broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.broadcasts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.broadcasts_id_seq OWNER TO postgres;

--
-- Name: broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.broadcasts_id_seq OWNED BY public.broadcasts.id;


--
-- Name: daily_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_schedules (
    id integer NOT NULL,
    day_number integer NOT NULL,
    event_time time without time zone,
    event_name character varying(200) NOT NULL,
    event_description text,
    location character varying(200),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.daily_schedules OWNER TO postgres;

--
-- Name: daily_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.daily_schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.daily_schedules_id_seq OWNER TO postgres;

--
-- Name: daily_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.daily_schedules_id_seq OWNED BY public.daily_schedules.id;


--
-- Name: draw_tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.draw_tickets (
    id integer NOT NULL,
    ticket_code character varying(100) NOT NULL,
    user_id integer,
    house_number character varying(50),
    day_number integer NOT NULL,
    is_assigned boolean DEFAULT false,
    is_winner boolean DEFAULT false,
    assigned_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.draw_tickets OWNER TO postgres;

--
-- Name: draw_tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.draw_tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.draw_tickets_id_seq OWNER TO postgres;

--
-- Name: draw_tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.draw_tickets_id_seq OWNED BY public.draw_tickets.id;


--
-- Name: expense_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense_categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.expense_categories OWNER TO postgres;

--
-- Name: expense_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_categories_id_seq OWNER TO postgres;

--
-- Name: expense_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_categories_id_seq OWNED BY public.expense_categories.id;


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expenses (
    id integer NOT NULL,
    category_id integer NOT NULL,
    item_name character varying(200) NOT NULL,
    amount numeric(10,2) NOT NULL,
    paid_to character varying(200),
    payment_method character varying(20) DEFAULT 'cash'::character varying,
    receipt_image text,
    notes text,
    expense_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_deleted boolean DEFAULT false,
    deleted_at timestamp without time zone,
    deleted_reason text,
    paid_by character varying DEFAULT 'organizer'::character varying
);


ALTER TABLE public.expenses OWNER TO postgres;

--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expenses_id_seq OWNER TO postgres;

--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- Name: fund_collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fund_collections (
    id integer NOT NULL,
    user_id integer NOT NULL,
    house_number character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(20) NOT NULL,
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    tentative_date date,
    paid_date date,
    received_by integer,
    receipt_number character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    payer_name character varying(100),
    is_deleted boolean DEFAULT false,
    deleted_at timestamp without time zone,
    deleted_reason text
);


ALTER TABLE public.fund_collections OWNER TO postgres;

--
-- Name: fund_collections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fund_collections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fund_collections_id_seq OWNER TO postgres;

--
-- Name: fund_collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fund_collections_id_seq OWNED BY public.fund_collections.id;


--
-- Name: gift_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gift_assignments (
    id integer NOT NULL,
    gift_id integer,
    user_id integer,
    house_number character varying(50) NOT NULL,
    day_number integer,
    assigned_by integer,
    notes text,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying DEFAULT 'pending'::character varying,
    gift_name character varying(255) DEFAULT ''::character varying
);


ALTER TABLE public.gift_assignments OWNER TO postgres;

--
-- Name: gift_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gift_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gift_assignments_id_seq OWNER TO postgres;

--
-- Name: gift_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gift_assignments_id_seq OWNED BY public.gift_assignments.id;


--
-- Name: gifts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gifts (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    sponsor_id integer,
    gift_type character varying(30) NOT NULL,
    day_number integer,
    quantity integer DEFAULT 1,
    quantity_assigned integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.gifts OWNER TO postgres;

--
-- Name: gifts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gifts_id_seq OWNER TO postgres;

--
-- Name: gifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gifts_id_seq OWNED BY public.gifts.id;


--
-- Name: navratri_days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.navratri_days (
    id integer NOT NULL,
    day_number integer NOT NULL,
    date date NOT NULL,
    goddess_name character varying(100),
    dress_code character varying(200),
    event_schedule text,
    is_active boolean DEFAULT false,
    is_completed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    max_winners integer DEFAULT 3
);


ALTER TABLE public.navratri_days OWNER TO postgres;

--
-- Name: navratri_days_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.navratri_days_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.navratri_days_id_seq OWNER TO postgres;

--
-- Name: navratri_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.navratri_days_id_seq OWNED BY public.navratri_days.id;


--
-- Name: snack_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.snack_orders (
    id integer NOT NULL,
    user_id integer,
    house_number character varying(50) NOT NULL,
    snack_id integer,
    day_number integer NOT NULL,
    quantity integer DEFAULT 1,
    total_price numeric(10,2),
    status character varying(20) DEFAULT 'pending'::character varying,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    snack_name character varying(255)
);


ALTER TABLE public.snack_orders OWNER TO postgres;

--
-- Name: snack_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.snack_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.snack_orders_id_seq OWNER TO postgres;

--
-- Name: snack_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.snack_orders_id_seq OWNED BY public.snack_orders.id;


--
-- Name: snacks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.snacks (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    price numeric(10,2) DEFAULT 0,
    quantity_available integer DEFAULT 0,
    quantity_sold integer DEFAULT 0,
    is_vegetarian boolean DEFAULT true,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.snacks OWNER TO postgres;

--
-- Name: snacks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.snacks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.snacks_id_seq OWNER TO postgres;

--
-- Name: snacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.snacks_id_seq OWNED BY public.snacks.id;


--
-- Name: sponsors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sponsors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    company_name character varying(200),
    advertisement_text text,
    advertisement_image text,
    sponsorship_amount numeric(10,2),
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    start_date date,
    end_date date,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sponsors OWNER TO postgres;

--
-- Name: sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sponsors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sponsors_id_seq OWNER TO postgres;

--
-- Name: sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sponsors_id_seq OWNED BY public.sponsors.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    house_number character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    mobile_number character varying(15) NOT NULL,
    user_type character varying(20) DEFAULT 'user'::character varying,
    password character varying(255),
    profile_image text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    member_type character varying DEFAULT 'main'::character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: aarti_bookings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_bookings ALTER COLUMN id SET DEFAULT nextval('public.aarti_bookings_id_seq'::regclass);


--
-- Name: aarti_slots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_slots ALTER COLUMN id SET DEFAULT nextval('public.aarti_slots_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: broadcasts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcasts ALTER COLUMN id SET DEFAULT nextval('public.broadcasts_id_seq'::regclass);


--
-- Name: daily_schedules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_schedules ALTER COLUMN id SET DEFAULT nextval('public.daily_schedules_id_seq'::regclass);


--
-- Name: draw_tickets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.draw_tickets ALTER COLUMN id SET DEFAULT nextval('public.draw_tickets_id_seq'::regclass);


--
-- Name: expense_categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_categories ALTER COLUMN id SET DEFAULT nextval('public.expense_categories_id_seq'::regclass);


--
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- Name: fund_collections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_collections ALTER COLUMN id SET DEFAULT nextval('public.fund_collections_id_seq'::regclass);


--
-- Name: gift_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_assignments ALTER COLUMN id SET DEFAULT nextval('public.gift_assignments_id_seq'::regclass);


--
-- Name: gifts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts ALTER COLUMN id SET DEFAULT nextval('public.gifts_id_seq'::regclass);


--
-- Name: navratri_days id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navratri_days ALTER COLUMN id SET DEFAULT nextval('public.navratri_days_id_seq'::regclass);


--
-- Name: snack_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snack_orders ALTER COLUMN id SET DEFAULT nextval('public.snack_orders_id_seq'::regclass);


--
-- Name: snacks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snacks ALTER COLUMN id SET DEFAULT nextval('public.snacks_id_seq'::regclass);


--
-- Name: sponsors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsors ALTER COLUMN id SET DEFAULT nextval('public.sponsors_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: aarti_bookings aarti_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_bookings
    ADD CONSTRAINT aarti_bookings_pkey PRIMARY KEY (id);


--
-- Name: aarti_slots aarti_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_slots
    ADD CONSTRAINT aarti_slots_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: broadcasts broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcasts
    ADD CONSTRAINT broadcasts_pkey PRIMARY KEY (id);


--
-- Name: daily_schedules daily_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_schedules
    ADD CONSTRAINT daily_schedules_pkey PRIMARY KEY (id);


--
-- Name: draw_tickets draw_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.draw_tickets
    ADD CONSTRAINT draw_tickets_pkey PRIMARY KEY (id);


--
-- Name: draw_tickets draw_tickets_ticket_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.draw_tickets
    ADD CONSTRAINT draw_tickets_ticket_code_key UNIQUE (ticket_code);


--
-- Name: expense_categories expense_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT expense_categories_name_key UNIQUE (name);


--
-- Name: expense_categories expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: fund_collections fund_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_collections
    ADD CONSTRAINT fund_collections_pkey PRIMARY KEY (id);


--
-- Name: gift_assignments gift_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_assignments
    ADD CONSTRAINT gift_assignments_pkey PRIMARY KEY (id);


--
-- Name: gifts gifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts
    ADD CONSTRAINT gifts_pkey PRIMARY KEY (id);


--
-- Name: navratri_days navratri_days_day_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navratri_days
    ADD CONSTRAINT navratri_days_day_number_key UNIQUE (day_number);


--
-- Name: navratri_days navratri_days_day_number_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navratri_days
    ADD CONSTRAINT navratri_days_day_number_unique UNIQUE (day_number);


--
-- Name: navratri_days navratri_days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.navratri_days
    ADD CONSTRAINT navratri_days_pkey PRIMARY KEY (id);


--
-- Name: snack_orders snack_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snack_orders
    ADD CONSTRAINT snack_orders_pkey PRIMARY KEY (id);


--
-- Name: snacks snacks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snacks
    ADD CONSTRAINT snacks_pkey PRIMARY KEY (id);


--
-- Name: sponsors sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_aarti_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aarti_bookings_status ON public.aarti_bookings USING btree (status);


--
-- Name: idx_aarti_bookings_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aarti_bookings_user ON public.aarti_bookings USING btree (user_id);


--
-- Name: idx_aarti_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_aarti_day ON public.aarti_slots USING btree (day_number);


--
-- Name: idx_funds_house; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_funds_house ON public.fund_collections USING btree (house_number);


--
-- Name: idx_funds_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_funds_status ON public.fund_collections USING btree (payment_status);


--
-- Name: idx_funds_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_funds_user ON public.fund_collections USING btree (user_id);


--
-- Name: idx_gift_assignments_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gift_assignments_day ON public.gift_assignments USING btree (day_number);


--
-- Name: idx_gift_assignments_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gift_assignments_user ON public.gift_assignments USING btree (user_id);


--
-- Name: idx_gifts_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gifts_day ON public.gifts USING btree (day_number);


--
-- Name: idx_gifts_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gifts_type ON public.gifts USING btree (gift_type);


--
-- Name: idx_snack_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_snack_orders_status ON public.snack_orders USING btree (status);


--
-- Name: idx_snack_orders_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_snack_orders_user ON public.snack_orders USING btree (user_id);


--
-- Name: idx_tickets_day; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_day ON public.draw_tickets USING btree (day_number);


--
-- Name: idx_tickets_house; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_house ON public.draw_tickets USING btree (house_number);


--
-- Name: idx_tickets_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_user ON public.draw_tickets USING btree (user_id);


--
-- Name: idx_users_house; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_house ON public.users USING btree (house_number);


--
-- Name: idx_users_mobile; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_mobile ON public.users USING btree (mobile_number);


-- update_users_timestamp trigger REMOVED (2026-10-10): the trigger function
-- breaks every UPDATE on users through this API stack, so member edits
-- never saved. updated_at is informational only; nothing depends on it.
-- (Kept update_timestamp() function above harmlessly unused.)


--
-- Name: aarti_bookings aarti_bookings_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_bookings
    ADD CONSTRAINT aarti_bookings_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: aarti_bookings aarti_bookings_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_bookings
    ADD CONSTRAINT aarti_bookings_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.aarti_slots(id) ON DELETE SET NULL;


--
-- Name: aarti_bookings aarti_bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_bookings
    ADD CONSTRAINT aarti_bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: aarti_slots aarti_slots_day_number_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aarti_slots
    ADD CONSTRAINT aarti_slots_day_number_fkey FOREIGN KEY (day_number) REFERENCES public.navratri_days(day_number);


--
-- Name: announcements announcements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: broadcasts broadcasts_sent_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broadcasts
    ADD CONSTRAINT broadcasts_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.users(id);


--
-- Name: draw_tickets draw_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.draw_tickets
    ADD CONSTRAINT draw_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: expenses expenses_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE CASCADE;


--
-- Name: fund_collections fund_collections_received_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_collections
    ADD CONSTRAINT fund_collections_received_by_fkey FOREIGN KEY (received_by) REFERENCES public.users(id);


--
-- Name: fund_collections fund_collections_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_collections
    ADD CONSTRAINT fund_collections_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: gift_assignments gift_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_assignments
    ADD CONSTRAINT gift_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: gift_assignments gift_assignments_gift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_assignments
    ADD CONSTRAINT gift_assignments_gift_id_fkey FOREIGN KEY (gift_id) REFERENCES public.gifts(id) ON DELETE SET NULL;


--
-- Name: gift_assignments gift_assignments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gift_assignments
    ADD CONSTRAINT gift_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: gifts gifts_sponsor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gifts
    ADD CONSTRAINT gifts_sponsor_id_fkey FOREIGN KEY (sponsor_id) REFERENCES public.sponsors(id);


--
-- Name: snack_orders snack_orders_snack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snack_orders
    ADD CONSTRAINT snack_orders_snack_id_fkey FOREIGN KEY (snack_id) REFERENCES public.snacks(id) ON DELETE SET NULL;


--
-- Name: sponsors sponsors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict NuHmSJuPhKG8yeEph2hGcFiTstavgrVwrQD8DaKGRQ5oFiFdkeoL2uq9BJOOSJu


--
-- PostgreSQL database dump
--

\restrict 2sBHSr3BIliHHRhzRuooJ6htRhy0ugyZdLi3W2cwffVXNENFgy3T5hTxerSEpLW

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_config (
    key character varying(100) NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.app_config OWNER TO postgres;

--
-- Name: daily_draws; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_draws (
    id integer NOT NULL,
    day_number integer NOT NULL,
    draw_number integer NOT NULL,
    winner_ticket_id integer,
    winner_user_id integer,
    winner_house_number character varying(50),
    prize_description text,
    drawn_at timestamp without time zone,
    is_completed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    draw_date date DEFAULT CURRENT_DATE,
    winner_id integer,
    ticket_id integer,
    drawn_by integer,
    ticket_code character varying,
    house_number character varying,
    prize_level integer,
    status character varying DEFAULT 'drawn'::character varying,
    is_available boolean,
    rescheduled_to_day integer,
    cancelled_reason text,
    cancelled_at timestamp without time zone
);


ALTER TABLE public.daily_draws OWNER TO postgres;

--
-- Name: daily_draws_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.daily_draws_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.daily_draws_id_seq OWNER TO postgres;

--
-- Name: daily_draws_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.daily_draws_id_seq OWNED BY public.daily_draws.id;


--
-- Name: fcm_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fcm_tokens (
    id integer NOT NULL,
    token text NOT NULL,
    user_id integer,
    user_type character varying(20),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.fcm_tokens OWNER TO postgres;

--
-- Name: fcm_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fcm_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fcm_tokens_id_seq OWNER TO postgres;

--
-- Name: fcm_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fcm_tokens_id_seq OWNED BY public.fcm_tokens.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    user_type character varying(20) DEFAULT 'user'::character varying NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    type character varying(50) DEFAULT 'general'::character varying NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: shoutout_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shoutout_reactions (
    id integer NOT NULL,
    shoutout_id integer,
    user_id integer,
    reaction character varying(5) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.shoutout_reactions OWNER TO postgres;

--
-- Name: shoutout_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shoutout_reactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shoutout_reactions_id_seq OWNER TO postgres;

--
-- Name: shoutout_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shoutout_reactions_id_seq OWNED BY public.shoutout_reactions.id;


--
-- Name: shoutouts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shoutouts (
    id integer NOT NULL,
    from_user_id integer,
    to_user_id integer,
    message text NOT NULL,
    emoji character varying(10) DEFAULT '🎉'::character varying,
    day_number integer NOT NULL,
    shoutout_type character varying DEFAULT 'general'::character varying,
    is_approved boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.shoutouts OWNER TO postgres;

--
-- Name: shoutouts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shoutouts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shoutouts_id_seq OWNER TO postgres;

--
-- Name: shoutouts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shoutouts_id_seq OWNED BY public.shoutouts.id;


--
-- Name: song_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.song_requests (
    id integer NOT NULL,
    user_id integer,
    song_name character varying NOT NULL,
    youtube_link character varying,
    day_number integer NOT NULL,
    request_type character varying DEFAULT 'live'::character varying,
    status character varying DEFAULT 'pending'::character varying,
    request_count integer DEFAULT 1,
    played_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.song_requests OWNER TO postgres;

--
-- Name: song_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.song_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.song_requests_id_seq OWNER TO postgres;

--
-- Name: song_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.song_requests_id_seq OWNED BY public.song_requests.id;


--
-- Name: song_suggestions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.song_suggestions (
    id integer NOT NULL,
    user_id integer,
    song_name character varying NOT NULL,
    youtube_link character varying,
    target_day integer NOT NULL,
    upvotes integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.song_suggestions OWNER TO postgres;

--
-- Name: song_suggestions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.song_suggestions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.song_suggestions_id_seq OWNER TO postgres;

--
-- Name: song_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.song_suggestions_id_seq OWNED BY public.song_suggestions.id;


--
-- Name: song_upvotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.song_upvotes (
    id integer NOT NULL,
    song_suggestion_id integer,
    user_id integer,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.song_upvotes OWNER TO postgres;

--
-- Name: song_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.song_upvotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.song_upvotes_id_seq OWNER TO postgres;

--
-- Name: song_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.song_upvotes_id_seq OWNED BY public.song_upvotes.id;


--
-- Name: sponsor_advertisements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sponsor_advertisements (
    id integer NOT NULL,
    user_id integer NOT NULL,
    image_data text NOT NULL,
    day_number integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    status character varying(20) DEFAULT 'pending'::character varying
);


ALTER TABLE public.sponsor_advertisements OWNER TO postgres;

--
-- Name: sponsor_advertisements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sponsor_advertisements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sponsor_advertisements_id_seq OWNER TO postgres;

--
-- Name: sponsor_advertisements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sponsor_advertisements_id_seq OWNED BY public.sponsor_advertisements.id;


--
-- Name: daily_draws id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws ALTER COLUMN id SET DEFAULT nextval('public.daily_draws_id_seq'::regclass);


--
-- Name: fcm_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fcm_tokens ALTER COLUMN id SET DEFAULT nextval('public.fcm_tokens_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: shoutout_reactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutout_reactions ALTER COLUMN id SET DEFAULT nextval('public.shoutout_reactions_id_seq'::regclass);


--
-- Name: shoutouts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutouts ALTER COLUMN id SET DEFAULT nextval('public.shoutouts_id_seq'::regclass);


--
-- Name: song_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_requests ALTER COLUMN id SET DEFAULT nextval('public.song_requests_id_seq'::regclass);


--
-- Name: song_suggestions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_suggestions ALTER COLUMN id SET DEFAULT nextval('public.song_suggestions_id_seq'::regclass);


--
-- Name: song_upvotes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_upvotes ALTER COLUMN id SET DEFAULT nextval('public.song_upvotes_id_seq'::regclass);


--
-- Name: sponsor_advertisements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsor_advertisements ALTER COLUMN id SET DEFAULT nextval('public.sponsor_advertisements_id_seq'::regclass);


--
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (key);


--
-- Name: daily_draws daily_draws_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws
    ADD CONSTRAINT daily_draws_pkey PRIMARY KEY (id);


--
-- Name: fcm_tokens fcm_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fcm_tokens
    ADD CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id);


--
-- Name: fcm_tokens fcm_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fcm_tokens
    ADD CONSTRAINT fcm_tokens_token_key UNIQUE (token);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: shoutout_reactions shoutout_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutout_reactions
    ADD CONSTRAINT shoutout_reactions_pkey PRIMARY KEY (id);


--
-- Name: shoutout_reactions shoutout_reactions_shoutout_id_user_id_reaction_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutout_reactions
    ADD CONSTRAINT shoutout_reactions_shoutout_id_user_id_reaction_key UNIQUE (shoutout_id, user_id, reaction);


--
-- Name: shoutouts shoutouts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutouts
    ADD CONSTRAINT shoutouts_pkey PRIMARY KEY (id);


--
-- Name: song_requests song_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_requests
    ADD CONSTRAINT song_requests_pkey PRIMARY KEY (id);


--
-- Name: song_suggestions song_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_suggestions
    ADD CONSTRAINT song_suggestions_pkey PRIMARY KEY (id);


--
-- Name: song_upvotes song_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_upvotes
    ADD CONSTRAINT song_upvotes_pkey PRIMARY KEY (id);


--
-- Name: song_upvotes song_upvotes_song_suggestion_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.song_upvotes
    ADD CONSTRAINT song_upvotes_song_suggestion_id_user_id_key UNIQUE (song_suggestion_id, user_id);


--
-- Name: sponsor_advertisements sponsor_advertisements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsor_advertisements
    ADD CONSTRAINT sponsor_advertisements_pkey PRIMARY KEY (id);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id, user_type, is_read);


--
-- Name: daily_draws daily_draws_winner_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws
    ADD CONSTRAINT daily_draws_winner_ticket_id_fkey FOREIGN KEY (winner_ticket_id) REFERENCES public.draw_tickets(id);


--
-- Name: daily_draws daily_draws_winner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws
    ADD CONSTRAINT daily_draws_winner_user_id_fkey FOREIGN KEY (winner_user_id) REFERENCES public.users(id);


--
-- Name: sponsor_advertisements sponsor_advertisements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsor_advertisements
    ADD CONSTRAINT sponsor_advertisements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 2sBHSr3BIliHHRhzRuooJ6htRhy0ugyZdLi3W2cwffVXNENFgy3T5hTxerSEpLW


-- Audit log (login / app_download / report_viewed, no UI)
CREATE TABLE IF NOT EXISTS audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INT,
  user_type VARCHAR(20),
  house_number VARCHAR,
  event VARCHAR(50) NOT NULL,
  details TEXT,
  ip_address VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_event ON audit_logs(event, created_at);