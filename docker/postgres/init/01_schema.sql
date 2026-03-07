CREATE TABLE IF NOT EXISTS service_events (
  id BIGSERIAL PRIMARY KEY,
  service_name TEXT NOT NULL,
  event_type TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO service_events (service_name, event_type, details)
SELECT 'bootstrap', 'seed', '{"component":"postgres"}'::jsonb
WHERE NOT EXISTS (
  SELECT 1
  FROM service_events
  WHERE service_name = 'bootstrap'
    AND event_type = 'seed'
);
