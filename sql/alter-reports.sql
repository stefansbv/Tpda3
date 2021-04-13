ALTER TABLE public.reports
    ADD COLUMN draft SMALLINT DEFAULT 0 NOT NULL CHECK (draft IN (0,1));
