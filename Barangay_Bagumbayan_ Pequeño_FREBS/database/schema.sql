CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;

DROP SCHEMA IF EXISTS brgy CASCADE;
CREATE SCHEMA brgy;
SET search_path = brgy, public;

CREATE TABLE purok (
    purok_id    SMALLINT GENERATED ALWAYS AS IDENTITY,
    purok_name  VARCHAR(40) NOT NULL,
    CONSTRAINT pk_purok      PRIMARY KEY (purok_id),
    CONSTRAINT uq_purok_name UNIQUE (purok_name)
);

CREATE TABLE official (
    official_id       SMALLINT GENERATED ALWAYS AS IDENTITY,
    official_name     VARCHAR(100) NOT NULL,
    official_position VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_official PRIMARY KEY (official_id),
    CONSTRAINT ck_official_position CHECK (official_position IN
        ('Punong Barangay','Barangay Kagawad','Barangay Secretary',
         'Barangay Treasurer','SK Chairperson','Barangay Tanod'))
);

CREATE TABLE facility (
    facility_id   SMALLINT GENERATED ALWAYS AS IDENTITY,
    facility_name VARCHAR(80)  NOT NULL,
    facility_type VARCHAR(20)  NOT NULL,
    capacity      INTEGER      NOT NULL,
    hourly_fee    NUMERIC(8,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_facility      PRIMARY KEY (facility_id),
    CONSTRAINT uq_facility_name UNIQUE (facility_name),
    CONSTRAINT ck_facility_type CHECK (facility_type IN
        ('Hall','Covered Court','Multipurpose','Center')),
    CONSTRAINT ck_facility_capacity CHECK (capacity > 0),
    CONSTRAINT ck_facility_fee      CHECK (hourly_fee >= 0)
);

CREATE TABLE equipment_category (
    category_id   SMALLINT GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_equipment_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name      UNIQUE (category_name)
);

CREATE TABLE resident (
    resident_id UUID         NOT NULL DEFAULT gen_random_uuid(),
    first_name  VARCHAR(60)  NOT NULL,
    last_name   VARCHAR(60)  NOT NULL,
    contact_no  VARCHAR(11)  NOT NULL,
    purok_id    SMALLINT     NOT NULL,
    CONSTRAINT pk_resident PRIMARY KEY (resident_id),
    CONSTRAINT fk_resident_purok FOREIGN KEY (purok_id)
        REFERENCES purok (purok_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_resident_contact CHECK (contact_no ~ '^09[0-9]{9}$'),
    CONSTRAINT ck_resident_names   CHECK (btrim(first_name) <> '' AND btrim(last_name) <> '')
);

CREATE TABLE reservation (
    reservation_id UUID         NOT NULL DEFAULT gen_random_uuid(),
    resident_id    UUID         NOT NULL,
    facility_id    SMALLINT     NOT NULL,
    official_id    SMALLINT,
    purpose        VARCHAR(200) NOT NULL,
    start_ts       TIMESTAMP WITH TIME ZONE NOT NULL,
    end_ts         TIMESTAMP WITH TIME ZONE NOT NULL,
    status         VARCHAR(10)  NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_reservation PRIMARY KEY (reservation_id),
    CONSTRAINT fk_res_resident FOREIGN KEY (resident_id)
        REFERENCES resident (resident_id) ON DELETE RESTRICT,
    CONSTRAINT fk_res_facility FOREIGN KEY (facility_id)
        REFERENCES facility (facility_id) ON DELETE RESTRICT,
    CONSTRAINT fk_res_official FOREIGN KEY (official_id)
        REFERENCES official (official_id) ON DELETE RESTRICT,
    CONSTRAINT ck_res_status CHECK (status IN
        ('Pending','Approved','Rejected','Cancelled','Completed')),
    CONSTRAINT ck_res_time CHECK (end_ts > start_ts),
    CONSTRAINT ck_res_approver CHECK (status NOT IN ('Approved','Completed') OR official_id IS NOT NULL),

    CONSTRAINT ex_res_no_overlap EXCLUDE USING gist (
        facility_id WITH =,
        tstzrange(start_ts, end_ts, '[)') WITH &&
    ) WHERE (status IN ('Pending','Approved','Completed'))
);

CREATE TABLE equipment (
    equipment_id   INTEGER  GENERATED ALWAYS AS IDENTITY,
    equipment_name VARCHAR(80) NOT NULL,
    category_id    SMALLINT NOT NULL,
    CONSTRAINT pk_equipment      PRIMARY KEY (equipment_id),
    CONSTRAINT uq_equipment_name UNIQUE (equipment_name),
    CONSTRAINT fk_equipment_category FOREIGN KEY (category_id)
        REFERENCES equipment_category (category_id) ON DELETE RESTRICT
);

CREATE TABLE equipment_item (
    equipment_id INTEGER     NOT NULL,
    item_no      SMALLINT    NOT NULL,
    asset_tag    VARCHAR(20) NOT NULL,
    item_status  VARCHAR(12) NOT NULL DEFAULT 'In Service',
    CONSTRAINT pk_equipment_item PRIMARY KEY (equipment_id, item_no),
    CONSTRAINT uq_asset_tag      UNIQUE (asset_tag),
    CONSTRAINT fk_item_equipment FOREIGN KEY (equipment_id)
        REFERENCES equipment (equipment_id) ON DELETE CASCADE,
    CONSTRAINT ck_item_no     CHECK (item_no > 0),
    CONSTRAINT ck_item_status CHECK (item_status IN ('In Service','Under Repair','Retired'))
);

CREATE TABLE borrowing (
    borrow_id      UUID         NOT NULL DEFAULT gen_random_uuid(),
    resident_id    UUID         NOT NULL,
    official_id    SMALLINT     NOT NULL,
    reservation_id UUID,
    borrow_ts      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    due_ts         TIMESTAMP WITH TIME ZONE NOT NULL,
    purpose        VARCHAR(200) NOT NULL,
    CONSTRAINT pk_borrowing PRIMARY KEY (borrow_id),
    CONSTRAINT fk_borrow_resident FOREIGN KEY (resident_id)
        REFERENCES resident (resident_id) ON DELETE RESTRICT,
    CONSTRAINT fk_borrow_official FOREIGN KEY (official_id)
        REFERENCES official (official_id) ON DELETE RESTRICT,
    CONSTRAINT fk_borrow_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id) ON DELETE RESTRICT,
    CONSTRAINT ck_borrow_due CHECK (due_ts > borrow_ts)
);

CREATE TABLE borrow_item (
    borrow_id        UUID        NOT NULL,
    equipment_id     INTEGER     NOT NULL,
    item_no          SMALLINT    NOT NULL,
    returned_ts      TIMESTAMP WITH TIME ZONE,
    return_condition VARCHAR(10),
    CONSTRAINT pk_borrow_item PRIMARY KEY (borrow_id, equipment_id, item_no),
    CONSTRAINT fk_bi_borrowing FOREIGN KEY (borrow_id)
        REFERENCES borrowing (borrow_id) ON DELETE CASCADE,
    CONSTRAINT fk_bi_item FOREIGN KEY (equipment_id, item_no)
        REFERENCES equipment_item (equipment_id, item_no) ON DELETE RESTRICT,
    CONSTRAINT ck_bi_condition CHECK (return_condition IN ('Good','Damaged','Lost')),
    CONSTRAINT ck_bi_return_pair CHECK ((returned_ts IS NULL) = (return_condition IS NULL))
);

CREATE UNIQUE INDEX ux_borrow_item_open
    ON borrow_item (equipment_id, item_no) WHERE returned_ts IS NULL;

CREATE OR REPLACE FUNCTION fn_borrow_item_rules() RETURNS trigger AS $$
DECLARE
    v_status   TEXT;
    v_borrowed TIMESTAMP WITH TIME ZONE;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT item_status INTO v_status
          FROM equipment_item
         WHERE equipment_id = NEW.equipment_id AND item_no = NEW.item_no;
        IF v_status <> 'In Service' THEN
            RAISE EXCEPTION 'Item %-% cannot be borrowed (status: %)',
                NEW.equipment_id, NEW.item_no, v_status;
        END IF;
    END IF;
    IF NEW.returned_ts IS NOT NULL THEN
        SELECT borrow_ts INTO v_borrowed FROM borrowing WHERE borrow_id = NEW.borrow_id;
        IF NEW.returned_ts < v_borrowed THEN
            RAISE EXCEPTION 'Return time cannot be earlier than borrow time';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_borrow_item_rules
    BEFORE INSERT OR UPDATE ON borrow_item
    FOR EACH ROW EXECUTE FUNCTION fn_borrow_item_rules();


CREATE INDEX idx_resident_purok       ON resident (purok_id);
CREATE INDEX idx_resident_name_lower  ON resident (lower(last_name), lower(first_name));
CREATE INDEX idx_reservation_resident ON reservation (resident_id);
CREATE INDEX idx_reservation_official ON reservation (official_id) WHERE official_id IS NOT NULL;
CREATE INDEX idx_reservation_start_done ON reservation (start_ts)
    WHERE status IN ('Approved','Completed');
CREATE INDEX idx_borrowing_resident   ON borrowing (resident_id);
CREATE INDEX idx_borrowing_reservation ON borrowing (reservation_id) WHERE reservation_id IS NOT NULL;
CREATE INDEX idx_borrow_item_unit     ON borrow_item (equipment_id, item_no);
CREATE INDEX idx_equipment_category   ON equipment (category_id);
