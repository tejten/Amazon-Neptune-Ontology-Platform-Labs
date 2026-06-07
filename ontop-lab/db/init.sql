CREATE TABLE IF NOT EXISTS rms_record (
    record_id TEXT PRIMARY KEY,
    affected_part_number TEXT NOT NULL,
    severity TEXT NOT NULL,
    status TEXT NOT NULL,
    opened_date DATE NOT NULL,
    summary TEXT NOT NULL
);

INSERT INTO rms_record (
    record_id,
    affected_part_number,
    severity,
    status,
    opened_date,
    summary
) VALUES
    ('RMS-1001', 'FP-8842', 'High', 'Open', DATE '2026-06-01', 'Fuel pump anomaly under review.'),
    ('RMS-1002', 'DSP-1200', 'Medium', 'Closed', DATE '2026-05-15', 'Display flicker investigation closed.')
ON CONFLICT (record_id) DO NOTHING;

