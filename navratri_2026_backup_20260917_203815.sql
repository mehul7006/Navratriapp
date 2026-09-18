--
-- PostgreSQL database dump
--

\restrict SklSicuC6NKy83c3eq7Vv8jxRKqiTmpnHFjI2C7OMErxScSfGLtxPS28dbeceKf

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
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_timestamp() OWNER TO postgres;

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
-- Name: vw_expense_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_expense_summary AS
 SELECT c.name AS category_name,
    sum(e.amount) AS total_amount,
    count(*) AS item_count
   FROM (public.expenses e
     JOIN public.expense_categories c ON ((e.category_id = c.id)))
  GROUP BY c.name;


ALTER VIEW public.vw_expense_summary OWNER TO postgres;

--
-- Name: vw_income_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_income_summary AS
 SELECT 'fund_collection'::text AS source,
    sum(fund_collections.amount) AS total_amount,
    count(*) AS transaction_count
   FROM public.fund_collections
  WHERE ((fund_collections.payment_status)::text = 'paid'::text)
UNION ALL
 SELECT 'sponsorship'::text AS source,
    sum(sponsors.sponsorship_amount) AS total_amount,
    count(*) AS transaction_count
   FROM public.sponsors
  WHERE ((sponsors.payment_status)::text = 'paid'::text);


ALTER VIEW public.vw_income_summary OWNER TO postgres;

--
-- Name: vw_user_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_user_payments AS
 SELECT u.house_number,
    u.name,
    u.mobile_number,
    COALESCE(sum(fc.amount), (0)::numeric) AS total_paid,
    count(fc.id) AS payment_count
   FROM (public.users u
     LEFT JOIN public.fund_collections fc ON ((((u.house_number)::text = (fc.house_number)::text) AND ((fc.payment_status)::text = 'paid'::text))))
  WHERE ((u.user_type)::text = 'user'::text)
  GROUP BY u.house_number, u.name, u.mobile_number;


ALTER VIEW public.vw_user_payments OWNER TO postgres;

--
-- Name: vw_user_tickets; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_user_tickets AS
 SELECT u.house_number,
    u.name,
    dt.ticket_code,
    dt.day_number,
    nd.goddess_name,
    nd.date AS event_date,
    dt.is_winner,
    dt.assigned_at
   FROM ((public.users u
     JOIN public.draw_tickets dt ON (((u.house_number)::text = (dt.house_number)::text)))
     JOIN public.navratri_days nd ON ((dt.day_number = nd.day_number)))
  ORDER BY u.house_number, dt.day_number;


ALTER VIEW public.vw_user_tickets OWNER TO postgres;

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
-- Name: daily_draws id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws ALTER COLUMN id SET DEFAULT nextval('public.daily_draws_id_seq'::regclass);


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
-- Name: shoutout_reactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutout_reactions ALTER COLUMN id SET DEFAULT nextval('public.shoutout_reactions_id_seq'::regclass);


--
-- Name: shoutouts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shoutouts ALTER COLUMN id SET DEFAULT nextval('public.shoutouts_id_seq'::regclass);


--
-- Name: snack_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snack_orders ALTER COLUMN id SET DEFAULT nextval('public.snack_orders_id_seq'::regclass);


--
-- Name: snacks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.snacks ALTER COLUMN id SET DEFAULT nextval('public.snacks_id_seq'::regclass);


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
-- Name: sponsors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sponsors ALTER COLUMN id SET DEFAULT nextval('public.sponsors_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: aarti_bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.aarti_bookings (id, user_id, house_number, day_number, slot_id, status, notes, approved_by, approved_at, created_at) FROM stdin;
2	\N	B437	1	\N	cancelled	Booked by organizer for mehull	\N	2026-09-06 18:55:59.322973	2026-09-07 00:22:15.863318
3	\N	B300	6	\N	approved	Booked by organizer for Hada	\N	2026-09-06 19:06:39.649591	2026-09-07 00:36:33.727838
4	\N	B350	3	\N	approved	Booked by organizer for hada	\N	2026-09-06 19:07:14.566994	2026-09-07 00:36:59.744072
7	108	B437	6	\N	approved	[B437] |day:6|booked_by:organizer	\N	2026-09-10 19:21:57.531548	2026-09-11 00:51:45.14474
8	101	B440	2	\N	pending	[B440] |day:2|booked_by:organizer	\N	\N	2026-09-11 00:55:28.41954
5	\N	B437	1	\N	cancelled	Booked by organizer for mehul	\N	2026-09-06 19:13:14.529274	2026-09-07 00:43:12.674113
6	100	B437	1	\N	cancelled	\N	\N	2026-09-10 19:25:38.546536	2026-09-11 00:22:41.233639
9	100	B437	3	\N	cancelled	[B437] |day:3|booked_by:organizer	\N	\N	2026-09-11 23:33:55.544141
10	100	B437	3	\N	cancelled	[B437] |day:3|booked_by:organizer	\N	\N	2026-09-11 23:33:57.18426
11	100	B437	3	\N	cancelled	[B437] |day:3|booked_by:organizer	\N	\N	2026-09-11 23:33:58.55203
12	100	B437	5	\N	approved	[B437] mehul|day:5|booked_by:organizer	\N	2026-09-14 14:00:38.92987	2026-09-12 00:47:55.287979
15	100	B437	6	\N	approved	[B437] mehul|day:6|booked_by:organizer	\N	2026-09-14 14:00:47.380353	2026-09-12 01:10:33.176724
14	100	B437	6	\N	approved	[B437] mehul|day:6|booked_by:organizer	\N	2026-09-14 14:00:48.202226	2026-09-12 01:10:32.391853
13	100	B437	9	\N	approved	[B437] mehul|day:9|booked_by:organizer	\N	2026-09-14 14:00:53.2157	2026-09-12 01:07:53.732387
16	108	B437	3	\N	approved	[B437] |day:3|booked_by:organizer	\N	2026-09-14 14:01:37.20477	2026-09-14 19:31:24.758144
18	100	B437	3	\N	cancelled	[B437] mehul|day:3|booked_by:organizer	\N	\N	2026-09-14 22:22:32.767819
19	100	B437	4	\N	pending	[B437] mehul|day:4|booked_by:organizer	\N	\N	2026-09-14 22:34:24.980328
20	100	B437	7	\N	pending	[B437] mehul|day:7|booked_by:organizer	\N	\N	2026-09-15 00:52:45.959953
21	101	B440	4	\N	pending	[B440] rahul|day:4|booked_by:organizer	\N	\N	2026-09-16 21:10:31.867379
22	101	B440	4	\N	pending	[B440] rahul|day:4|booked_by:organizer	\N	\N	2026-09-16 21:10:36.068028
\.


--
-- Data for Name: aarti_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

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


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.announcements (id, title, message, announcement_type, priority, is_active, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: broadcasts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.broadcasts (id, title, message, broadcast_type, media_url, target_audience, sent_by, sent_at) FROM stdin;
\.


--
-- Data for Name: daily_draws; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.daily_draws (id, day_number, draw_number, winner_ticket_id, winner_user_id, winner_house_number, prize_description, drawn_at, is_completed, created_at, draw_date, winner_id, ticket_id, drawn_by, ticket_code, house_number, prize_level, status, is_available, rescheduled_to_day, cancelled_reason, cancelled_at) FROM stdin;
1	1	1	\N	\N	\N	\N	2026-09-10 01:18:22.051586	f	2026-09-10 01:18:22.051586	2026-09-10	104	6	1	2026100006	B452	3	confirmed	t	\N	\N	\N
3	1	3	\N	\N	\N	\N	2026-09-10 01:18:41.704945	f	2026-09-10 01:18:41.704945	2026-09-10	101	3	1	2026100003	B440	1	confirmed	t	\N	\N	\N
5	1	5	\N	\N	\N	\N	2026-09-10 01:29:59.178579	f	2026-09-10 01:29:59.178579	2026-09-10	108	2	1	2026100002	B437	\N	drawn	\N	\N	\N	\N
4	1	4	\N	\N	\N	\N	2026-09-10 01:18:54.192976	f	2026-09-10 01:18:54.192976	2026-09-10	105	7	1	2026100007	B453	\N	cancelled	t	\N	dfdf	2026-09-10 20:20:08.714454
2	1	2	\N	\N	\N	\N	2026-09-10 01:18:33.912495	f	2026-09-10 01:18:33.912495	2026-09-10	109	8	1	2026100008	B453	2	cancelled	t	\N	asdasdasd	2026-09-10 20:20:15.466563
7	1	7	\N	\N	\N	\N	2026-09-10 21:26:30.899205	f	2026-09-10 21:26:30.899205	2026-09-10	106	10	1	2026100010	B454	\N	drawn	\N	\N	\N	\N
6	1	6	\N	\N	\N	\N	2026-09-10 21:25:59.577275	f	2026-09-10 21:25:59.577275	2026-09-10	103	5	1	2026100005	B451	2	confirmed	t	\N	\N	\N
8	1	8	\N	\N	\N	\N	2026-09-10 21:55:21.76282	f	2026-09-10 21:55:21.76282	2026-09-10	106	10	1	2026100010	B454	\N	confirmed	t	\N	\N	\N
9	10	1	\N	\N	\N	\N	2026-09-11 21:44:57.020216	f	2026-09-11 21:44:57.020216	2026-09-11	100	12	1	2026100012	B437	\N	drawn	\N	\N	\N	\N
10	3	1	\N	\N	\N	\N	2026-09-17 02:02:54.702549	f	2026-09-17 02:02:54.702549	2026-09-17	101	14	1	2026100014	B440	\N	drawn	\N	\N	\N	\N
11	4	1	\N	\N	\N	\N	2026-09-17 02:04:15.975345	f	2026-09-17 02:04:15.975345	2026-09-17	101	13	1	2026100013	B440	\N	drawn	\N	\N	\N	\N
\.


--
-- Data for Name: daily_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.daily_schedules (id, day_number, event_time, event_name, event_description, location, created_at) FROM stdin;
\.


--
-- Data for Name: draw_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.draw_tickets (id, ticket_code, user_id, house_number, day_number, is_assigned, is_winner, assigned_at, created_at) FROM stdin;
1	2026100001	100	B437	1	t	f	2026-09-09 19:45:49.551707	2026-09-10 01:15:29.422694
2	2026100002	108	B437	1	t	f	2026-09-09 19:46:08.630559	2026-09-10 01:15:29.430385
4	2026100004	102	B450	1	t	f	2026-09-09 19:46:41.68673	2026-09-10 01:15:29.435521
9	2026100009	107	B455	1	t	f	2026-09-09 19:47:53.564824	2026-09-10 01:15:29.449112
6	2026100006	104	B452	1	t	t	2026-09-09 19:47:14.429725	2026-09-10 01:15:29.440538
3	2026100003	101	B440	1	t	t	2026-09-09 19:46:28.577386	2026-09-10 01:15:29.43298
11	2026100011	110	B478	1	t	f	2026-09-10 14:46:08.401608	2026-09-10 20:15:30.054688
7	2026100007	105	B453	1	t	f	2026-09-09 19:47:25.348883	2026-09-10 01:15:29.443163
8	2026100008	109	B453	1	t	f	2026-09-09 19:47:42.723964	2026-09-10 01:15:29.445759
5	2026100005	103	B451	1	t	t	2026-09-09 19:46:58.22425	2026-09-10 01:15:29.437864
10	2026100010	106	B454	1	t	t	2026-09-09 19:48:07.667963	2026-09-10 01:15:29.453321
12	2026100012	100	B437	10	t	f	2026-09-11 16:14:41.297196	2026-09-11 21:36:51.222848
16	2026100016	\N	\N	3	f	f	\N	2026-09-17 00:37:24.588748
17	2026100017	\N	\N	3	f	f	\N	2026-09-17 00:37:24.59278
18	2026100018	\N	\N	3	f	f	\N	2026-09-17 00:37:24.596936
19	2026100019	\N	\N	3	f	f	\N	2026-09-17 00:37:24.600895
20	2026100020	\N	\N	3	f	f	\N	2026-09-17 00:37:24.60504
21	2026100021	\N	\N	3	f	f	\N	2026-09-17 00:37:24.60896
22	2026100022	\N	\N	3	f	f	\N	2026-09-17 00:37:24.613535
14	2026100014	101	B440	3	t	f	2026-09-16 19:08:28.189694	2026-09-17 00:37:24.579829
13	2026100013	101	B440	4	t	f	2026-09-16 20:34:05.071638	2026-09-17 00:37:24.571782
\.


--
-- Data for Name: expense_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense_categories (id, name, description, is_active, created_at) FROM stdin;
1	Light	Lighting and electrical expenses	t	2026-08-24 22:17:11.687841
2	Sound	Sound system and music expenses	t	2026-08-24 22:17:11.687841
3	Decoration	Decoration and setup expenses	t	2026-08-24 22:17:11.687841
4	Food & Drinks	Food and beverages	t	2026-08-24 22:17:11.687841
5	Prizes & Gifts	Prizes for winners and gifts	t	2026-08-24 22:17:11.687841
6	Miscellaneous	Other expenses	t	2026-08-24 22:17:11.687841
7	Sponsor Expense	Sponsored distributions	t	2026-09-05 00:24:48.42113
\.


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expenses (id, category_id, item_name, amount, paid_to, payment_method, receipt_image, notes, expense_date, created_at, is_deleted, deleted_at, deleted_reason, paid_by) FROM stdin;
1	4	Snack Distribution - B437	0.00	\N	cash	\N	Auto:  (B437) approved snack day 1	2026-10-15	2026-09-07 01:10:51.077543	f	\N	\N	organizer
2	7	Sponsor Distribution - mehul	0.00	mehul	cash	\N	Day 1 - samosa	2026-09-07	2026-09-07 01:10:51.098468	f	\N	\N	organizer
5	4	Snack Distribution - ORGANIZOR	0.00	\N	cash	\N	Auto:  (ORGANIZOR) approved snack day 1	2026-10-15	2026-09-07 01:21:27.613487	f	\N	\N	organizer
6	4	Snack Distribution - self	500.00	self	cash	\N	Day 1 - patra	2026-09-07	2026-09-07 01:21:27.623384	f	\N	\N	organizer
3	7	Snack Distribution - B450	0.00	.	cash	\N	Auto:  (B450) approved snack day 2	2026-10-16	2026-09-07 01:20:32.245911	f	\N	\N	organizer
7	7	Sponsor Distribution - mehul	0.00	mehul	cash	\N	Day 1 - 	2026-09-10	2026-09-10 00:49:20.626311	f	\N	\N	organizer
8	5	[Organizer] (B440) rahul - poket	50.00	rahul	cash	\N	Day 1 - poket	2026-09-10	2026-09-10 01:09:02.363291	f	\N	\N	organizer
9	4	[Organizer] Snack: samosa - mehul (B437)	500.00	mehul	cash	\N	Day 3 - samosa distributed to mehul (B437)	2026-09-14	2026-09-14 19:57:44.425281	f	\N	\N	organizer
10	7	[Sponsor] Snack: Day 4 - rahu (B400)	0.00	rahu	cash	\N	Day 4 - Snack distributed to rahu (B400)	2026-09-14	2026-09-14 19:58:03.294639	f	\N	\N	organizer
11	5	[Organizer] Gift: Day 3 - kkbk (B401)	100.00	kkbk	cash	\N	Day 3 - Gift donated by kkbk (B401)	2026-09-14	2026-09-14 19:59:56.468589	f	\N	\N	organizer
12	7	[Sponsor] Gift: Day 3 - mehul (B437)	0.00	mehul	cash	\N	Day 3 - Gift donated by mehul (B437)	2026-09-14	2026-09-14 20:00:18.555467	f	\N	\N	organizer
13	4	[Organizer] Snack: samosa - yuvak mandal (B444)	500.00	yuvak mandal	cash	\N	Day 5 - samosa distributed to yuvak mandal (B444)	2026-09-16	2026-09-16 20:22:36.995551	f	\N	\N	organizer
15	4	[Organizer] Snack: samosa - organizer (ORGANIER)	5000.00	organizer	cash	\N	Day 4 - samosa distributed to organizer (ORGANIER)	2026-09-16	2026-09-16 20:30:12.833389	f	\N	\N	organizer
\.


--
-- Data for Name: fund_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fund_collections (id, user_id, house_number, amount, payment_method, payment_status, tentative_date, paid_date, received_by, receipt_number, notes, created_at, payer_name, is_deleted, deleted_at, deleted_reason) FROM stdin;
1	100	B437	5000.00	cash	paid	\N	2026-09-07	\N	\N	\N	2026-09-07 01:05:32.871485	mehul	f	\N	\N
2	101	B440	15000.00	online	paid	\N	2026-09-07	\N	\N	\N	2026-09-07 01:05:46.650815	rahul	f	\N	\N
3	102	B450	6000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-07 01:06:13.178484	raj	f	\N	\N
4	103	B451	1000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 01:14:06.175938	mangilal	f	\N	\N
5	104	B452	1000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 01:14:26.093566	jagdishbhai	f	\N	\N
6	105	B453	1000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 01:14:36.673584	somabhai	f	\N	\N
7	106	B454	1000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 01:14:51.84758	sureshbhai	f	\N	\N
8	107	B455	1000.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 01:15:09.809049	shambhubhai	f	\N	\N
9	110	B478	1500.00	cash	paid	\N	2026-09-10	\N	\N	\N	2026-09-10 20:15:00.727283	jayraj	f	\N	\N
10	111	B300	500.00	cash	paid	\N	2026-09-17	\N	\N	\N	2026-09-17 00:37:04.831327	abcd	f	\N	\N
\.


--
-- Data for Name: gift_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gift_assignments (id, gift_id, user_id, house_number, day_number, assigned_by, notes, assigned_at, status, gift_name) FROM stdin;
36	\N	\N	B437	1	\N	[B437] mehul|SPONSOR_EXPENSE:0:mehul	2026-09-10 00:21:24.786409	approved	
3	\N	\N	B437	1	\N	[B437] mehul - aa|SPONSOR_EXPENSE:0:mehul	2026-09-07 02:04:46.433054	rejected	
37	\N	\N	B437	2	\N	[B437] mehul|SPONSOR_EXPENSE:0:mehul	2026-09-10 00:22:17.999379	rejected	
38	\N	\N	B437	3	\N	[B437] mehul	2026-09-10 00:49:37.765203	approved	
39	\N	\N	B440	1	\N	[B440] rahul - poket|ORG_EXPENSE:50:Gifts	2026-09-10 01:08:58.890897	approved	
40	\N	\N	B401	3	\N	[B401] kkbk|ORG_EXPENSE:100:Gifts	2026-09-14 19:59:51.370197	rejected	
41	\N	\N	B437	3	\N	[B437] mehul|SPONSOR_EXPENSE:0:mehul	2026-09-14 20:00:16.590352	approved	
44	\N	100	B437	4	\N		2026-09-15 00:44:48.927759	approved	kachori
43	\N	100	B437	4	\N		2026-09-15 00:36:35.167528	approved	JALEBI
42	\N	100	B437	4	\N		2026-09-15 00:36:13.913657	approved	FAFDA
45	\N	100	B437	7	\N		2026-09-15 00:52:16.751681	approved	samosa
46	\N	101	B440	4	\N		2026-09-16 20:32:52.192583	approved	asasasas
\.


--
-- Data for Name: gifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gifts (id, name, description, sponsor_id, gift_type, day_number, quantity, quantity_assigned, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: navratri_days; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.navratri_days (id, day_number, date, goddess_name, dress_code, event_schedule, is_active, is_completed, created_at, max_winners) FROM stdin;
8	8	2026-10-22	Mahagauri	Peacock Blue	\N	f	f	2026-08-24 22:17:11.691329	3
9	9	2026-10-23	Siddhidatri	Multi-color	\N	f	f	2026-08-24 22:17:11.691329	3
5	5	2026-10-19	Skandamata	Orange & Pink	\N	f	f	2026-08-24 22:17:11.691329	3
7	7	2026-10-21	Kalaratri	Black & Red	\N	f	f	2026-08-24 22:17:11.691329	3
6	6	2026-10-20	Katyayani	Purple & Magenta	\N	f	f	2026-08-24 22:17:11.691329	3
44	10	2026-10-24	Dussehra	Celebration Colors	\N	f	f	2026-09-06 00:46:21.911849	3
1	1	2026-10-15	Shailputri	Royal Blue & Bandhani	\N	f	t	2026-08-24 22:17:11.691329	5
2	2	2026-10-16	Brahmacharini	White & Silver	\N	f	t	2026-08-24 22:17:11.691329	3
3	3	2026-10-17	Chandraghanta	Red & Gold	\N	f	t	2026-08-24 22:17:11.691329	3
4	4	2026-10-18	Kushmanda	Green & Yellow	\N	t	f	2026-08-24 22:17:11.691329	3
\.


--
-- Data for Name: shoutout_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shoutout_reactions (id, shoutout_id, user_id, reaction, created_at) FROM stdin;
1	1	101	🔥	2026-09-17 19:10:12.997986
6	1	101	💪	2026-09-17 19:10:14.716856
8	1	101	👏	2026-09-17 19:10:15.827069
11	1	101	❤️	2026-09-17 19:10:16.644461
\.


--
-- Data for Name: shoutouts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shoutouts (id, from_user_id, to_user_id, message, emoji, day_number, shoutout_type, is_approved, created_at) FROM stdin;
1	100	101	zdasdasdasdasdasd	#	1	general	t	2026-09-15 11:48:33.508146
\.


--
-- Data for Name: snack_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.snack_orders (id, user_id, house_number, snack_id, day_number, quantity, total_price, status, notes, created_at, snack_name) FROM stdin;
2	\N	B437	\N	1	1	\N	approved	[B437] mehul - samosa|SPONSOR_EXPENSE:0:mehul	2026-09-07 01:10:44.942206	\N
3	\N	B450	\N	2	1	\N	rejected	[B450] raj - pakoda|SPONSOR_EXPENSE:0:raj	2026-09-07 01:20:27.302541	\N
4	\N	ORGANIZOR	\N	1	1	\N	approved	[ORGANIZOR] self - patra|ORG_EXPENSE:500:Snacks	2026-09-07 01:21:23.955566	\N
5	0	B437	6	3	1	\N	approved	[B437] mehul - samosa|ORG_EXPENSE:500:Snacks	2026-09-14 19:57:42.508033	\N
6	0	B400	6	4	1	\N	approved	[B400] rahu|SPONSOR_EXPENSE:0:rahu	2026-09-14 19:58:00.311657	\N
8	0	B400	6	4	1	\N	rejected	[B400] rahu|SPONSOR_EXPENSE:0:rahu	2026-09-14 19:58:45.508591	\N
7	0	B400	6	4	1	\N	rejected	[B400] rahu|SPONSOR_EXPENSE:0:rahu	2026-09-14 19:58:45.345084	\N
9	108	B437	1	3	1	\N	approved		2026-09-14 23:01:21.295355	chai
11	100	B437	1	6	1	\N	approved		2026-09-14 23:39:30.881805	chai
10	108	B437	1	3	1	\N	approved		2026-09-14 23:19:03.769539	cahi
12	100	B437	1	8	1	\N	approved		2026-09-15 00:53:03.465907	samosa
13	0	B444	6	5	1	\N	approved	[B444] yuvak mandal - samosa|ORG_EXPENSE:500:Snacks	2026-09-16 20:22:34.717888	
14	0	B450	6	5	1	\N	approved	[B450] raj - pani puri|SPONSOR_EXPENSE:0:raj	2026-09-16 20:22:56.616159	
16	0	B469	6	4	1	\N	approved	[B469] kavi - kachori|SPONSOR_EXPENSE:0:kavi	2026-09-16 20:30:08.377311	
15	0	ORGANIER	6	4	1	\N	approved	[ORGANIER] organizer - samosa|ORG_EXPENSE:5000:Snacks	2026-09-16 20:29:40.320946	
17	101	B440	1	4	1	\N	approved		2026-09-16 20:32:35.117862	aaaaaaaaaaa
\.


--
-- Data for Name: snacks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.snacks (id, name, description, price, quantity_available, quantity_sold, is_vegetarian, is_active, created_at) FROM stdin;
1	Samosa	Crispy fried pastry with spiced filling	20.00	50	0	t	t	2026-09-14 19:36:12.43862
2	Patra	Steamed gram flour snack	15.00	40	0	t	t	2026-09-14 19:36:12.43862
3	Fafda	Crispy gram flour snack	25.00	30	0	t	t	2026-09-14 19:36:12.43862
4	Dhokla	Steamed fermented gram flour cake	30.00	25	0	t	t	2026-09-14 19:36:12.43862
5	Jalebi	Sweet crispy spiral dessert	40.00	20	0	t	t	2026-09-14 19:36:12.43862
6	Chai	Masala tea	10.00	100	0	t	t	2026-09-14 19:36:12.43862
\.


--
-- Data for Name: song_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.song_requests (id, user_id, song_name, youtube_link, day_number, request_type, status, request_count, played_at, created_at) FROM stdin;
1	100	sasasas		10	live	pending	1	\N	2026-09-15 11:48:14.803084
\.


--
-- Data for Name: song_suggestions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.song_suggestions (id, user_id, song_name, youtube_link, target_day, upvotes, created_at) FROM stdin;
\.


--
-- Data for Name: song_upvotes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.song_upvotes (id, song_suggestion_id, user_id, created_at) FROM stdin;
\.


--
-- Data for Name: sponsors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sponsors (id, user_id, company_name, advertisement_text, advertisement_image, sponsorship_amount, payment_status, start_date, end_date, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, house_number, name, mobile_number, user_type, password, profile_image, is_active, created_at, updated_at, member_type) FROM stdin;
1	admin	Organizer Admin	9999999999	organizer	admin123	\N	t	2026-08-24 22:17:11.678904	2026-08-24 22:17:11.678904	main
80	SP-ADMIN	Admin Sponsor	9999999998	sponsor	admin123	\N	t	2026-08-26 14:56:52.822862	2026-08-26 14:56:52.822862	main
81	U-ADMIN	Admin User Updated	1111111111	user	admin123	\N	t	2026-08-26 14:57:29.641322	2026-08-26 20:45:11.922074	main
102	B450	raj	0000000000	user	\N	\N	t	2026-09-07 01:06:13.144538	2026-09-07 01:06:13.144538	main
103	B451	mangilal	0000000000	user	\N	\N	t	2026-09-10 01:14:06.117875	2026-09-10 01:14:06.117875	main
104	B452	jagdishbhai	0000000000	user	\N	\N	t	2026-09-10 01:14:26.040083	2026-09-10 01:14:26.040083	main
105	B453	somabhai	0000000000	user	\N	\N	t	2026-09-10 01:14:36.618157	2026-09-10 01:14:36.618157	main
106	B454	sureshbhai	0000000000	user	\N	\N	t	2026-09-10 01:14:51.792484	2026-09-10 01:14:51.792484	main
107	B455	shambhubhai	0000000000	user	\N	\N	t	2026-09-10 01:15:09.753892	2026-09-10 01:15:09.753892	main
108	B437	mehul2	0000000000	user	\N	\N	t	2026-09-10 01:16:07.147841	2026-09-10 01:16:07.147841	sub
109	B453	jaimin	0000000000	user	\N	\N	t	2026-09-10 01:17:40.948822	2026-09-10 01:17:40.948822	sub
110	B478	jayraj	0000000000	user	\N	\N	t	2026-09-10 20:15:00.637351	2026-09-10 20:15:00.637351	main
100	B437	mehul	0123456789	user	\N	\N	t	2026-09-07 01:05:32.816922	2026-09-11 22:29:14.064332	main
101	B440	rahul	1231231231	user	\N	\N	t	2026-09-07 01:05:46.618117	2026-09-16 20:31:53.15852	main
111	B300	abcd	0000000000	user	\N	\N	t	2026-09-17 00:37:04.540747	2026-09-17 00:37:04.540747	main
\.


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
-- Name: daily_draws daily_draws_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_draws
    ADD CONSTRAINT daily_draws_pkey PRIMARY KEY (id);


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


--
-- Name: users update_users_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_timestamp BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


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

\unrestrict SklSicuC6NKy83c3eq7Vv8jxRKqiTmpnHFjI2C7OMErxScSfGLtxPS28dbeceKf

