-- ============================================
-- BASE DE DONNEES - VIDE GRENIERS P1
-- Comité Fête des Roses - Brie-Comte-Robert
-- ============================================

-- 1. TABLE PRINCIPALE
-- ============================================
create table emplacements (
  id serial primary key,
  code text unique not null,              -- ex: 'A-01'
  zone text not null,                     -- ex: 'A'
  statut text default 'libre' not null,   -- 'libre' | 'en_attente' | 'reserve'
  nom text,
  email text,
  telephone text,
  reference_paiement text,                -- identifiant unique de la tentative de paiement
  expiration timestamptz,                 -- date limite pour payer (rempli quand statut = en_attente)
  cree_le timestamptz default now(),
  maj_le timestamptz default now()
);

create index idx_emplacements_statut on emplacements(statut);
create index idx_emplacements_zone on emplacements(zone);
create index idx_emplacements_reference on emplacements(reference_paiement);

-- Met a jour maj_le automatiquement a chaque changement
create or replace function update_maj_le()
returns trigger as $$
begin
  new.maj_le = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_maj_le
before update on emplacements
for each row execute function update_maj_le();


-- 2. SECURITE (Row Level Security)
-- ============================================
alter table emplacements enable row level security;

-- Tout le monde peut lire le plan (savoir ce qui est libre/pris)
create policy "lecture publique" on emplacements
  for select using (true);

-- Une place ne peut passer en "en_attente" QUE si elle est actuellement "libre"
-- -> empeche que 2 personnes reservent la meme place en meme temps
create policy "reservation si libre" on emplacements
  for update using (statut = 'libre')
  with check (statut = 'en_attente');

-- Note : le passage "en_attente" -> "reserve" (confirmation de paiement) ne se fait
-- QUE via le webhook cote serveur (clé service_role), qui n'est pas soumis a RLS.
-- Le client ne peut donc jamais s'auto-confirmer une reservation sans payer.


-- 3. LIBERATION AUTOMATIQUE DES PLACES NON PAYEES
-- ============================================
-- Necessite l'extension pg_cron (Database > Extensions dans Supabase)
create extension if not exists pg_cron;

select cron.schedule(
  'liberer-places-expirees',
  '* * * * *',  -- toutes les minutes
  $$
  update emplacements
  set statut = 'libre',
      nom = null,
      email = null,
      telephone = null,
      reference_paiement = null,
      expiration = null
  where statut = 'en_attente'
    and expiration < now()
  $$
);


-- 4. DONNEES : LES 232 EMPLACEMENTS DU PLAN
-- ============================================
insert into emplacements (code, zone) values
('A-01', 'A'),
('A-02', 'A'),
('A-03', 'A'),
('A-04', 'A'),
('A-05', 'A'),
('A-06', 'A'),
('A-07', 'A'),
('A-08', 'A'),
('A-09', 'A'),
('A-10', 'A'),
('A-11', 'A'),
('A-12', 'A'),
('A-13', 'A'),
('A-14', 'A'),
('A-15', 'A'),
('A-16', 'A'),
('A-17', 'A'),
('A-18', 'A'),
('A-19', 'A'),
('A-20', 'A'),
('B-01', 'B'),
('B-02', 'B'),
('B-03', 'B'),
('B-04', 'B'),
('B-05', 'B'),
('B-06', 'B'),
('B-07', 'B'),
('B-08', 'B'),
('C-01', 'C'),
('C-02', 'C'),
('C-03', 'C'),
('C-04', 'C'),
('C-05', 'C'),
('C-06', 'C'),
('C-07', 'C'),
('C-08', 'C'),
('D-01', 'D'),
('D-02', 'D'),
('D-03', 'D'),
('D-04', 'D'),
('D-05', 'D'),
('D-06', 'D'),
('D-07', 'D'),
('D-08', 'D'),
('E-01', 'E'),
('E-02', 'E'),
('E-03', 'E'),
('E-04', 'E'),
('E-05', 'E'),
('E-06', 'E'),
('E-07', 'E'),
('E-08', 'E'),
('F-01', 'F'),
('F-02', 'F'),
('F-03', 'F'),
('F-04', 'F'),
('F-05', 'F'),
('F-06', 'F'),
('F-07', 'F'),
('F-08', 'F'),
('F-09', 'F'),
('G-01', 'G'),
('G-02', 'G'),
('G-03', 'G'),
('G-04', 'G'),
('G-05', 'G'),
('G-06', 'G'),
('G-07', 'G'),
('G-08', 'G'),
('G-09', 'G'),
('G-10', 'G'),
('G-11', 'G'),
('G-12', 'G'),
('G-13', 'G'),
('G-14', 'G'),
('G-15', 'G'),
('G-16', 'G'),
('G-17', 'G'),
('G-18', 'G'),
('G-19', 'G'),
('G-20', 'G'),
('G-21', 'G'),
('G-22', 'G'),
('G-23', 'G'),
('G-24', 'G'),
('G-25', 'G'),
('G-26', 'G'),
('G-27', 'G'),
('G-28', 'G'),
('G-29', 'G'),
('G-30', 'G'),
('H-01', 'H'),
('H-02', 'H'),
('H-03', 'H'),
('H-04', 'H'),
('H-05', 'H'),
('H-06', 'H'),
('H-07', 'H'),
('H-08', 'H'),
('H-09', 'H'),
('H-10', 'H'),
('H-11', 'H'),
('H-12', 'H'),
('H-13', 'H'),
('H-14', 'H'),
('H-15', 'H'),
('H-16', 'H'),
('H-17', 'H'),
('H-18', 'H'),
('H-19', 'H'),
('H-20', 'H'),
('H-21', 'H'),
('H-22', 'H'),
('H-23', 'H'),
('I-01', 'I'),
('I-02', 'I'),
('I-03', 'I'),
('I-04', 'I'),
('I-05', 'I'),
('I-06', 'I'),
('I-07', 'I'),
('I-08', 'I'),
('I-09', 'I'),
('I-10', 'I'),
('I-11', 'I'),
('I-12', 'I'),
('I-13', 'I'),
('I-14', 'I'),
('I-15', 'I'),
('I-16', 'I'),
('I-17', 'I'),
('I-18', 'I'),
('I-19', 'I'),
('I-20', 'I'),
('I-21', 'I'),
('I-22', 'I'),
('I-23', 'I'),
('I-24', 'I'),
('I-25', 'I'),
('I-26', 'I'),
('I-27', 'I'),
('J-01', 'J'),
('J-02', 'J'),
('J-03', 'J'),
('J-04', 'J'),
('J-05', 'J'),
('J-06', 'J'),
('J-07', 'J'),
('J-08', 'J'),
('J-09', 'J'),
('J-10', 'J'),
('J-11', 'J'),
('J-12', 'J'),
('J-13', 'J'),
('J-14', 'J'),
('J-15', 'J'),
('J-16', 'J'),
('J-17', 'J'),
('J-18', 'J'),
('J-19', 'J'),
('J-20', 'J'),
('J-21', 'J'),
('J-22', 'J'),
('J-23', 'J'),
('J-24', 'J'),
('J-25', 'J'),
('J-26', 'J'),
('J-27', 'J'),
('K-01', 'K'),
('K-02', 'K'),
('K-03', 'K'),
('K-04', 'K'),
('K-05', 'K'),
('K-06', 'K'),
('K-07', 'K'),
('K-08', 'K'),
('K-09', 'K'),
('K-10', 'K'),
('K-11', 'K'),
('K-12', 'K'),
('K-13', 'K'),
('K-14', 'K'),
('K-15', 'K'),
('K-16', 'K'),
('K-17', 'K'),
('K-18', 'K'),
('K-19', 'K'),
('K-20', 'K'),
('K-21', 'K'),
('K-22', 'K'),
('K-23', 'K'),
('L-01', 'L'),
('L-02', 'L'),
('L-03', 'L'),
('L-04', 'L'),
('L-05', 'L'),
('L-06', 'L'),
('L-07', 'L'),
('L-08', 'L'),
('L-09', 'L'),
('L-10', 'L'),
('L-11', 'L'),
('L-12', 'L'),
('L-13', 'L'),
('L-14', 'L'),
('L-15', 'L'),
('L-16', 'L'),
('L-17', 'L'),
('L-18', 'L'),
('L-19', 'L'),
('L-20', 'L'),
('L-21', 'L'),
('L-22', 'L'),
('L-23', 'L'),
('L-24', 'L'),
('L-25', 'L'),
('L-26', 'L'),
('L-27', 'L'),
('L-28', 'L'),
('M-01', 'M'),
('M-02', 'M'),
('M-03', 'M'),
('M-04', 'M'),
('M-05', 'M'),
('M-06', 'M'),
('M-07', 'M'),
('M-08', 'M'),
('M-09', 'M'),
('M-10', 'M'),
('M-11', 'M'),
('M-12', 'M'),
('M-13', 'M');
