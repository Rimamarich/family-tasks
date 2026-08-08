-- ============================================================
-- Family Tasks V1
-- Données de test
-- ============================================================

PRAGMA foreign_keys = ON;


-- ============================================================
-- MEMBERS
-- ============================================================

INSERT INTO members (id, name, avatar, stars, color, pause)
VALUES
    (1, 'Marie',   'avatar_01', 12, '#E8A0BF', 0),
    (2, 'Antoine', 'avatar_02',  8, '#7AA7D9', 0),
    (3, 'Mimi',    'avatar_03', 15, '#8BCB9A', 0),
    (4, 'Alex',    'avatar_04',  5, '#F2B36D', 0);


-- ============================================================
-- MOMENTS
-- ============================================================

INSERT INTO moments (id, name, heure_de_fin)
VALUES
    (1, 'Matin',         '10:30'),
    (2, 'Temps de midi', '13:00'),
    (3, 'Après-midi',    '18:00'),
    (4, 'Soirée',        '19:30'),
    (5, 'Fin de soirée', '21:30');


-- ============================================================
-- TASKS
-- ============================================================
--
-- Dans l'ICS :
--
--   "Routine du matin"
--   sans @membre
--
-- signifie que la tâche est destinée à tous les membres.
--
-- Dans SQLite, on crée donc 4 tâches indépendantes.
--
-- ============================================================

-- Routine du matin : tous les membres
INSERT INTO tasks (
    id, ics_uid, title, description,
    member_id, stars, completed, moment_id, task_date
)
VALUES
    (1, 'ics-routine-matin-20260808', 'Routine du matin',
     'Se préparer pour commencer la journée.', 1, 2, 1, 1, '2026-08-08'),

    (2, 'ics-routine-matin-20260808', 'Routine du matin',
     'Se préparer pour commencer la journée.', 2, 2, 0, 1, '2026-08-08'),

    (3, 'ics-routine-matin-20260808', 'Routine du matin',
     'Se préparer pour commencer la journée.', 3, 2, 1, 1, '2026-08-08'),

    (4, 'ics-routine-matin-20260808', 'Routine du matin',
     'Se préparer pour commencer la journée.', 4, 2, 0, 1, '2026-08-08');


-- Tâche individuelle
INSERT INTO tasks (
    id, ics_uid, title, description,
    member_id, stars, completed, moment_id, task_date
)
VALUES
    (5, 'ics-chambre-mimi-20260808', 'Ranger la chambre',
     'Mettre les vêtements dans le panier et ranger les objets.', 3, 3, 0, 3, '2026-08-08');


-- Tâche attribuée à deux membres
-- L'événement ICS contientrait : @Marie @Antoine
INSERT INTO tasks (
    id, ics_uid, title, description,
    member_id, stars, completed, moment_id, task_date
)
VALUES
    (6, 'ics-table-20260808', 'Mettre la table',
     'Préparer les couverts et les assiettes.', 1, 1, 0, 2, '2026-08-08'),

    (7, 'ics-table-20260808', 'Mettre la table',
     'Préparer les couverts et les assiettes.', 2, 1, 0, 2, '2026-08-08');


-- Deux occurrences du même événement ICS
-- pour vérifier que chaque occurrence est une tâche distincte.

INSERT INTO tasks (
    id, ics_uid, title, description,
    member_id, stars, completed, moment_id, task_date
)
VALUES
    (8, 'ics-cartable', 'Préparer le cartable',
     'Vérifier les cahiers et préparer les affaires du lendemain.', 3, 2, 0, 4, '2026-08-08'),

    (9, 'ics-cartable', 'Préparer le cartable',
     'Vérifier les cahiers et préparer les affaires du lendemain.', 3, 2, 0, 4, '2026-08-09');


-- Une tâche sans description
INSERT INTO tasks (
    id, ics_uid, title, description,
    member_id, stars, completed, moment_id, task_date
)
VALUES
    (10, 'ics-dents-alex-20260808', 'Se brosser les dents',
     NULL, 4, 1, 1, 5, '2026-08-08');


-- ============================================================
-- REWARDS
-- ============================================================

INSERT INTO rewards (
    id, title, cost, unique_reward, requires_note
)
VALUES
    (1, 'Choisir le film',       10, 0, 1),
    (2, 'Pizza',                20, 0, 0),
    (3, 'Sortie spéciale',      30, 1, 1),
    (4, 'Petit privilège',       5, 1, 0);


-- ============================================================
-- REWARD CONTRIBUTIONS
-- ============================================================
--
-- Choisir le film : plusieurs membres contribuent.
--
-- Coût = 10
-- Marie = 4
-- Mimi  = 3
-- Alex  = 3
-- Total = 10
--
-- La récompense est donc entièrement financée.
-- ============================================================

INSERT INTO reward_contributions (
    id, reward_id, member_id, stars
)
VALUES
    (1, 1, 1, 4),
    (2, 1, 3, 3),
    (3, 1, 4, 3);


-- Pizza : récompense en cours de financement.
--
-- Coût = 20
-- Antoine = 5
-- Mimi    = 4
-- Total   = 9

INSERT INTO reward_contributions (
    id, reward_id, member_id, stars
)
VALUES
    (4, 2, 2, 5),
    (5, 2, 3, 4);


-- Sortie spéciale : financement complet.
--
-- Coût = 30
-- Marie   = 10
-- Antoine = 10
-- Mimi    = 10

INSERT INTO reward_contributions (
    id, reward_id, member_id, stars
)
VALUES
    (6, 3, 1, 10),
    (7, 3, 2, 10),
    (8, 3, 3, 10);


-- ============================================================
-- REDEMPTIONS
-- ============================================================
--
-- "Choisir le film" a été effectivement obtenu.
-- La note permet de tester requires_note.
-- ============================================================

INSERT INTO redemptions (
    id, reward_id, stars, note, created_at
)
VALUES
    (
        1,
        1,
        10,
        'Mimi choisit le film.',
        '2026-08-08T20:00:00'
    );


-- ============================================================
-- CONFIG
-- ============================================================

INSERT INTO config (
    id, parent_pin, ics_url
)
VALUES
    (
        1,
        '1234',
        'https://example.com/family-tasks.ics'
    );