-- Total urine output over the first 24 hours in the ICU

CREATE MATERIALIZED VIEW mimiciv.first_day_urine_output_mv AS

SELECT
  -- patient identifiers
  ie.subject_id
  , ie.stay_id
  , SUM(urineoutput) AS urineoutput
FROM mimic_icu.icustays ie
-- Join to the outputevents table to get urine output
LEFT JOIN mimiciv.urine_output_mv uo
    ON ie.stay_id = uo.stay_id
    -- ensure the data occurs during the first day
    AND uo.charttime >= ie.intime
    AND uo.charttime <= DATE(ie.intime + INTERVAL '1 DAY')
GROUP BY ie.subject_id, ie.stay_id