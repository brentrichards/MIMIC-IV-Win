-- flag indicating if patients received dialysis during 
-- the first day of their ICU stay
select
    ie.subject_id
    , ie.stay_id
    , MAX(dialysis_present) AS dialysis_present
    , MAX(dialysis_active) AS dialysis_active
    , STRING_AGG(DISTINCT dialysis_type, ', ') AS dialysis_type
FROM mimic_icu.icustays ie
LEFT JOIN mimiciv.rrt_mv rrt
	ON ie.stay_id = rrt.stay_id
	AND rrt.charttime >= DATE(ie.intime - INTERVAL '6 HOURS')
	AND rrt.charttime <= DATE(ie.intime + INTERVAL '1 DAY')
GROUP BY ie.subject_id, ie.stay_id
