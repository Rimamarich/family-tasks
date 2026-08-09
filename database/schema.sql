PRAGMA foreign_keys = ON;

CREATE TABLE members (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    avatar TEXT NOT NULL,
    stars INTEGER NOT NULL DEFAULT 0,
    color TEXT NOT NULL,
    pause INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE moments (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    heure_de_fin TEXT NOT NULL
);

CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    ics_uid TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    member_id INTEGER NOT NULL,
    stars INTEGER NOT NULL DEFAULT 0,
    completed INTEGER NOT NULL DEFAULT 0,
    moment_id INTEGER NOT NULL,
    task_date TEXT NOT NULL,

    FOREIGN KEY (member_id) REFERENCES members(id),
    FOREIGN KEY (moment_id) REFERENCES moments(id),

    UNIQUE (ics_uid, task_date, member_id)
);

CREATE TABLE rewards (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    cost INTEGER NOT NULL,
    unique_reward INTEGER NOT NULL DEFAULT 0,
    requires_note INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE redemptions (
    id INTEGER PRIMARY KEY,
    reward_id INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,

    FOREIGN KEY (reward_id) REFERENCES rewards(id)
);

CREATE TABLE reward_contributions (
    id INTEGER PRIMARY KEY,
    reward_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    stars INTEGER NOT NULL,
    redemption_id INTEGER,

    FOREIGN KEY (reward_id) REFERENCES rewards(id),
    FOREIGN KEY (member_id) REFERENCES members(id),
    FOREIGN KEY (redemption_id) REFERENCES redemptions(id)
);

CREATE TABLE config (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    parent_pin TEXT NOT NULL,
    ics_url TEXT NOT NULL
);