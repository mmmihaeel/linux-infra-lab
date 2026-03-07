CREATE TABLE IF NOT EXISTS maintenance_runs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_name VARCHAR(128) NOT NULL,
  status VARCHAR(64) NOT NULL,
  details JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

INSERT INTO maintenance_runs (task_name, status, details)
SELECT 'bootstrap', 'seed', JSON_OBJECT('component', 'mysql')
WHERE NOT EXISTS (
  SELECT 1
  FROM maintenance_runs
  WHERE task_name = 'bootstrap'
    AND status = 'seed'
);
