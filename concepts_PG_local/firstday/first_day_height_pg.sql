-- This query extracts heights for adult ICU patients.
-- It uses all information from the patient's first ICU day.
-- This is done for consistency with other queries - it's not necessarily needed.
-- Height is unlikely to change throughout a patient's stay.

-- The MIMIC-III version used echo data, this is not available in MIMIC-IV v0.4
WITH ce AS
(
    SELECT
      c.stay_id
      , AVG(valuenum) as Height_chart
    FROM mimic_icu.chartevents c
    INNER JOIN mimic_icu.icustays ie ON
        c.stay_id = ie.stay_id
        AND c.charttime BETWEEN DATE(ie.intime - INTERVAL '1 DAY') AND DATE(ie.intime + INTERVAL '1 DAY')
    WHERE c.valuenum IS NOT NULL
    AND c.itemid in (226730) -- height
    AND c.valuenum != 0
    GROUP BY c.stay_id
)
SELECT
    ie.subject_id
    , ie.stay_id
    , ROUND(AVG(height), 2) AS height
FROM mimic_icu.icustays ie
LEFT JOIN mimiciv.height_mv ht
    ON ie.stay_id = ht.stay_id
    AND ht.charttime >= DATE(ie.intime - INTERVAL '6 HOUR')
    AND ht.charttime <= DATE(ie.intime + INTERVAL '1 DAY')
GROUP BY ie.subject_id, ie.stay_id;