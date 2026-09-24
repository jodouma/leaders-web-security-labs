-- Compléter dans la base jetable ShopLab. Ne placez aucun mot de passe ici.
-- Créer des rôles NOLOGIN de privilèges puis rattacher un LOGIN éphémère en séance.
-- Prouver les accès permis ET les refus.

BEGIN;
CREATE TABLE IF NOT EXISTS audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_type text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE audit_events OWNER TO websec;
REVOKE ALL ON audit_events FROM PUBLIC;
-- TODO: shoplab_runtime, shoplab_readonly, shoplab_backup
COMMIT;
