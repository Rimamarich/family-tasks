-- ============================================================
-- Family Tasks V1
-- Données de test
-- ============================================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ============================================================
-- NETTOYAGE
-- Permet de réexécuter le seed sur une base existante.
-- ============================================================

DELETE FROM reward_contributions;
DELETE FROM redemptions;
DELETE FROM rewards;
DELETE FROM tasks;
DELETE FROM moments;
DELETE FROM members;
DELETE FROM config;

-- ============================================================
-- MEMBERS
-- ============================================================

INSERT INTO members (
    id, name, avatar, stars, color, pause
)
VALUES
    (1, 'Marie',   'avatar_01', 12, '#E8A0BF', 0),
    (2, 'Antoine', 'avatar_02',  8, '#7AA7D9', 0),
    (3, 'Mimi',    'avatar_03', 15, '#8BCB9A', 0),
    (4, 'Alex',    'avatar_04',  5, '#F2B36D', 0);

-- ============================================================
-- MOMENTS
-- ============================================================

INSERT INTO moments (
    id, name, heure_de_fin
)
VALUES
    (1, 'Matin',         '10:30'),
    (2, 'Temps de midi', '13:00'),
    (3, 'Après-midi',    '18:00'),
    (4, 'Soirée',        '19:30'),
    (5, 'Fin de soirée', '21:30');

-- ============================================================
-- TASKS
-- ============================================================

-- ------------------------------------------------------------
-- Tâche sans membre explicite dans l'ICS
-- → une tâche pour chaque membre.
--
-- Date : aujourd'hui
-- ------------------------------------------------------------

INSERT INTO tasks (
    id,
    ics_uid,
    title,
    description,
    member_id,
    stars,
    completed,
    moment_id,
    task_date
)
VALUES
    (
        1,
        'ics-routine-matin',
        'Routine du matin',
        'Se préparer pour commencer la journée.',
        1,
        2,
        1,
        1,
        date('now', 'localtime')
    ),
    (
        2,
        'ics-routine-matin',
        'Routine du matin',
        'Se préparer pour commencer la journée.',
        2,
        2,
        0,
        1,
        date('now', 'localtime')
    ),
    (
        3,
        'ics-routine-matin',
        'Routine du matin',
        'Se préparer pour commencer la journée.',
        3,
        2,
        1,
        1,
        date('now', 'localtime')
    ),
    (
        4,
        'ics-routine-matin',
        'Routine du matin',
        'Se préparer pour commencer la journée.',
        4,
        2,
        0,
        1,
        date('now', 'localtime')
    );

-- ------------------------------------------------------------
-- Tâche individuelle
-- ------------------------------------------------------------

INSERT INTO tasks (
    id,
    ics_uid,
    title,
    description,
    member_id,
    stars,
    completed,
    moment_id,
    task_date
)
VALUES
    (
        5,
        'ics-chambre-mimi',
        'Ranger la chambre',
        'Mettre les vêtements dans le panier et ranger les objets.',
        3,
        3,
        0,
        3,
        date('now', 'localtime')
    );

-- ------------------------------------------------------------
-- Tâche attribuée à plusieurs membres
--
-- Événement ICS :
-- @Marie @Antoine
-- → deux tâches indépendantes.
-- ------------------------------------------------------------

INSERT INTO tasks (
    id,
    ics_uid,
    title,
    description,
    member_id,
    stars,
    completed,
    moment_id,
    task_date
)
VALUES
    (
        6,
        'ics-table',
        'Mettre la table',
        'Préparer les couverts et les assiettes.',
        1,
        1,
        0,
        2,
        date('now', 'localtime')
    ),
    (
        7,
        'ics-table',
        'Mettre la table',
        'Préparer les couverts et les assiettes.',
        2,
        1,
        0,
        2,
        date('now', 'localtime')
    );

-- ------------------------------------------------------------
-- Deux occurrences du même événement ICS
--
-- Même ics_uid, dates différentes.
-- ------------------------------------------------------------

INSERT INTO tasks (
    id,
    ics_uid,
    title,
    description,
    member_id,
    stars,
    completed,
    moment_id,
    task_date
)
VALUES
    (
        8,
        'ics-cartable',
        'Préparer le cartable',
        'Vérifier les cahiers et préparer les affaires du lendemain.',
        3,
        2,
        0,
        4,
        date('now', 'localtime')
    ),
    (
        9,
        'ics-cartable',
        'Préparer le cartable',
        'Vérifier les cahiers et préparer les affaires du lendemain.',
        3,
        2,
        0,
        4,
        date('now', 'localtime', '+1 day')
    );

-- ------------------------------------------------------------
-- Tâche sans description
-- ------------------------------------------------------------

INSERT INTO tasks (
    id,
    ics_uid,
    title,
    description,
    member_id,
    stars,
    completed,
    moment_id,
    task_date
)
VALUES
    (
        10,
        'ics-dents-alex',
        'Se brosser les dents',
        NULL,
        4,
        1,
        1,
        5,
        date('now', 'localtime')
    );

-- ============================================================
-- REWARDS
-- ============================================================

INSERT INTO rewards (
    id,
    title,
    cost,
    unique_reward,
    requires_note
)
VALUES
    (1, 'Choisir le film',  10, 0, 1),
    (2, 'Pizza',             20, 0, 0),
    (3, 'Sortie spéciale',   30, 1, 1),
    (4, 'Petit privilège',   5, 1, 0);

-- ============================================================
-- REDEMPTIONS
-- ============================================================

-- ------------------------------------------------------------
-- "Choisir le film" a été effectivement obtenu.
-- La récompense nécessite une note.
-- ------------------------------------------------------------

INSERT INTO redemptions (
    id,
    reward_id,
    stars,
    note,
    created_at
)
VALUES
    (
        1,
        1,
        10,
        'Mimi choisit le film.',
        datetime('now', 'localtime')
    );

-- ============================================================
-- REWARD CONTRIBUTIONS
-- ============================================================

-- ------------------------------------------------------------
-- Choisir le film
--
-- Coût : 10
-- Marie : 4
-- Mimi  : 3
-- Alex  : 3
-- Total : 10
--
-- Ces contributions ont été consommées par la redemption 1.
-- ------------------------------------------------------------

INSERT INTO reward_contributions (
    id,
    reward_id,
    member_id,
    stars,
    redemption_id
)
VALUES
    (1, 1, 1, 4, 1),
    (2, 1, 3, 3, 1),
    (3, 1, 4, 3, 1);

-- ------------------------------------------------------------
-- Pizza
--
-- Coût : 20
-- Antoine : 5
-- Mimi    : 4
-- Total   : 9
--
-- Contributions encore disponibles.
-- ------------------------------------------------------------

INSERT INTO reward_contributions (
    id,
    reward_id,
    member_id,
    stars,
    redemption_id
)
VALUES
    (4, 2, 2, 5, NULL),
    (5, 2, 3, 4, NULL);

-- ------------------------------------------------------------
-- Sortie spéciale
--
-- Coût : 30
-- Marie   : 10
-- Antoine : 10
-- Mimi    : 10
--
-- Financement complet mais pas encore consommé.
-- ------------------------------------------------------------

INSERT INTO reward_contributions (
    id,
    reward_id,
    member_id,
    stars,
    redemption_id
)
VALUES
    (6, 3, 1, 10, NULL),
    (7, 3, 2, 10, NULL),
    (8, 3, 3, 10, NULL);

-- ============================================================
-- CONFIG
-- ============================================================

INSERT INTO config (
    id,
    parent_pin,
    ics_url
)
VALUES
    (
        1,
        '1234',
        'https://example.com/family-tasks.ics'
    );

COMMIT;