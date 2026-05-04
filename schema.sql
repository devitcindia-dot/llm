-- SQL Schema for ISO 27001 AI Auditor - Agentic System
-- PostgreSQL (Render free tier)

CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'active',
    user_agent TEXT,
    ip_address INET,
    organization_name VARCHAR(200) NULL,
    industry VARCHAR(100) NULL,
    company_size VARCHAR(50) NULL,
    isms_scope TEXT NULL,
    total_messages INT DEFAULT 0,
    session_duration_seconds INT DEFAULT 0,
    final_compliance_score DECIMAL(5,2) NULL,
    risk_level VARCHAR(20) NULL,
    auditor_version VARCHAR(20) DEFAULT '2.0.0',
    current_phase VARCHAR(30) DEFAULT 'gathering',
    phase_progress JSONB NULL
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message_index INT NOT NULL,
    agent_role VARCHAR(30) NULL,
    phase VARCHAR(30) NULL,
    retrieved_context JSONB NULL,
    response_time_ms INT NULL,
    model_used VARCHAR(50) NULL,
    embedding_similarity_avg DECIMAL(5,4) NULL
);

CREATE TABLE IF NOT EXISTS audit_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    question_topic VARCHAR(100) NULL,
    compliance_assessment VARCHAR(30) NULL,
    confidence_score DECIMAL(3,2) NULL,
    iso_clause VARCHAR(20) NULL,
    iso_clause_title VARCHAR(200) NULL,
    evidence_provided BOOLEAN DEFAULT FALSE,
    evidence_type VARCHAR(50) NULL,
    sentiment VARCHAR(20) NULL,
    risk_indicators TEXT NULL,
    finding_detail TEXT NULL,
    recommendation TEXT NULL
);

CREATE TABLE IF NOT EXISTS gap_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    clause_id VARCHAR(10) NOT NULL,
    clause_title VARCHAR(200) NOT NULL,
    category VARCHAR(30) NULL,
    compliance VARCHAR(20) NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    findings TEXT NULL,
    evidence_requested JSONB NULL,
    evidence_provided JSONB NULL,
    gaps JSONB NULL,
    strengths JSONB NULL,
    recommendations JSONB NULL,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    risk_id VARCHAR(20) NOT NULL,
    risk_name VARCHAR(200) NOT NULL,
    assessment_type VARCHAR(20) NOT NULL,
    impact_score INT NOT NULL,
    impact_justification TEXT NULL,
    likelihood_score INT NOT NULL,
    likelihood_justification TEXT NULL,
    risk_score INT NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    existing_controls JSONB NULL,
    control_effectiveness VARCHAR(30) NULL,
    residual_risk_level VARCHAR(20) NULL,
    recommended_treatment VARCHAR(20) NULL,
    treatment_details TEXT NULL,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_label VARCHAR(100) NOT NULL,
    file_name VARCHAR(200) NULL,
    file_path VARCHAR(500) NULL,
    file_size INT NULL,
    mime_type VARCHAR(50) NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    review_status VARCHAR(30) NULL,
    review_score DECIMAL(5,2) NULL,
    review_findings JSONB NULL,
    parsed_content TEXT NULL
);

CREATE TABLE IF NOT EXISTS training_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    certification VARCHAR(100) NULL,
    employee_count INT NULL,
    verified BOOLEAN DEFAULT FALSE,
    certificate_file VARCHAR(500) NULL,
    training_program_exists BOOLEAN NULL,
    maturity_level INT NULL,
    awareness_program TEXT NULL,
    training_frequency VARCHAR(50) NULL,
    records_maintained BOOLEAN NULL,
    gaps JSONB NULL,
    recommendations JSONB NULL,
    overall_score DECIMAL(5,2) NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS generated_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    sections JSONB NULL,
    customization_notes TEXT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    asset_name VARCHAR(200) NOT NULL,
    asset_type VARCHAR(50) NULL,
    asset_owner VARCHAR(100) NULL,
    confidentiality INT NULL,
    integrity INT NULL,
    availability INT NULL,
    threats JSONB NULL,
    vulnerabilities JSONB NULL,
    existing_controls JSONB NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    report_version VARCHAR(10) DEFAULT '2.0',
    executive_summary TEXT NULL,
    overall_score DECIMAL(5,2) NULL,
    risk_level VARCHAR(20) NULL,
    clauses_assessed INT DEFAULT 0,
    clauses_compliant INT DEFAULT 0,
    clauses_partial INT DEFAULT 0,
    clauses_non_compliant INT DEFAULT 0,
    risks_assessed INT DEFAULT 0,
    risks_critical INT DEFAULT 0,
    risks_high INT DEFAULT 0,
    risks_medium INT DEFAULT 0,
    risks_low INT DEFAULT 0,
    documents_reviewed INT DEFAULT 0,
    training_score DECIMAL(5,2) NULL,
    key_findings JSONB NULL,
    gap_summary JSONB NULL,
    risk_summary JSONB NULL,
    action_items JSONB NULL,
    generated_policies JSONB NULL,
    full_report_json JSONB NULL,
    pdf_generated BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS analytics_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    view_name VARCHAR(50) NOT NULL UNIQUE
);

-- VIEW: Daily session stats
CREATE OR REPLACE VIEW v_session_stats AS
SELECT
    DATE(created_at) as audit_date,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sessions,
    COUNT(CASE WHEN status = 'abandoned' THEN 1 END) as abandoned_sessions,
    AVG(session_duration_seconds) as avg_duration_seconds,
    AVG(total_messages) as avg_messages_per_session,
    AVG(final_compliance_score) as avg_compliance_score
FROM sessions
GROUP BY DATE(created_at);

-- VIEW: Compliance gaps by clause
CREATE OR REPLACE VIEW v_compliance_gaps AS
SELECT
    ga.clause_id,
    ga.clause_title,
    ga.category,
    ga.compliance,
    ga.score,
    COUNT(*) as times_assessed,
    ROUND(AVG(ga.score), 1) as avg_score,
    COUNT(CASE WHEN ga.compliance = 'non-compliant' THEN 1 END) as non_compliant_count,
    COUNT(CASE WHEN ga.compliance = 'partial' THEN 1 END) as partial_count
FROM gap_assessments ga
GROUP BY ga.clause_id, ga.clause_title, ga.category, ga.compliance, ga.score
ORDER BY ga.score ASC;

-- VIEW: Response patterns
CREATE OR REPLACE VIEW v_response_patterns AS
SELECT
    sentiment,
    COUNT(*) as count,
    ROUND(AVG(confidence_score), 2) as avg_ai_confidence,
    COUNT(CASE WHEN evidence_provided = TRUE THEN 1 END) as with_evidence_count
FROM audit_responses
GROUP BY sentiment;

-- VIEW: Session funnel
CREATE OR REPLACE VIEW v_session_funnel AS
SELECT
    CASE
        WHEN total_messages BETWEEN 1 AND 5 THEN '1-5 messages'
        WHEN total_messages BETWEEN 6 AND 15 THEN '6-15 messages'
        WHEN total_messages BETWEEN 16 AND 30 THEN '16-30 messages'
        WHEN total_messages BETWEEN 31 AND 60 THEN '31-60 messages'
        ELSE '60+ messages'
    END as message_range,
    COUNT(*) as session_count,
    ROUND(COUNT(*)::numeric / NULLIF(SUM(COUNT(*)) OVER (), 0) * 100, 1) as percentage
FROM sessions
GROUP BY message_range
ORDER BY MIN(total_messages);

-- VIEW: Risk distribution
CREATE OR REPLACE VIEW v_risk_distribution AS
SELECT
    ra.risk_level,
    COUNT(*) as count,
    ROUND(AVG(ra.risk_score), 1) as avg_score,
    COUNT(DISTINCT ra.session_id) as sessions_assessed
FROM risk_assessments ra
GROUP BY ra.risk_level;

-- VIEW: Hourly activity
CREATE OR REPLACE VIEW v_hourly_activity AS
SELECT
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as sessions_started
FROM sessions
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- VIEW: Top failing clauses
CREATE OR REPLACE VIEW v_top_failing_clauses AS
SELECT
    ga.clause_id,
    ga.clause_title,
    ga.category,
    ROUND(AVG(ga.score), 1) as avg_score,
    COUNT(*) as total_assessments,
    COUNT(CASE WHEN ga.compliance = 'non-compliant' THEN 1 END) as non_compliant_count,
    COUNT(DISTINCT ga.session_id) as organizations_affected
FROM gap_assessments ga
GROUP BY ga.clause_id, ga.clause_title, ga.category
ORDER BY avg_score ASC
LIMIT 20;

-- VIEW: Industry compliance comparison
CREATE OR REPLACE VIEW v_industry_compliance AS
SELECT
    s.industry,
    COUNT(DISTINCT s.id) as audits,
    ROUND(AVG(s.final_compliance_score), 1) as avg_score,
    ROUND(AVG(s.session_duration_seconds) / 60, 1) as avg_duration_min
FROM sessions s
WHERE s.industry IS NOT NULL AND s.final_compliance_score IS NOT NULL
GROUP BY s.industry
ORDER BY avg_score DESC;

-- VIEW: Training maturity across audits
CREATE OR REPLACE VIEW v_training_maturity AS
SELECT
    tr.maturity_level,
    COUNT(*) as count,
    ROUND(AVG(tr.overall_score), 1) as avg_score,
    ROUND(AVG(CASE WHEN tr.verified THEN 100 ELSE 0 END), 1) as verification_rate
FROM training_records tr
GROUP BY tr.maturity_level
ORDER BY tr.maturity_level;

-- VIEW: Document review summary
CREATE OR REPLACE VIEW v_document_review AS
SELECT
    de.document_type,
    de.document_label,
    COUNT(*) as total_uploads,
    COUNT(CASE WHEN de.review_status = 'adequate' THEN 1 END) as adequate_count,
    COUNT(CASE WHEN de.review_status = 'needs improvement' THEN 1 END) as improvement_count,
    COUNT(CASE WHEN de.review_status = 'inadequate' THEN 1 END) as inadequate_count,
    ROUND(AVG(de.review_score), 1) as avg_score
FROM document_evidence de
GROUP BY de.document_type, de.document_label
ORDER BY avg_score ASC;
