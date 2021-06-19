-- attempt to calculate urine output per hour
-- rate/hour is the interpretable measure of kidney function
-- though it is difficult to estimate from aperiodic point measures
-- first we get the earliest heart rate documented for the stay
WITH tm AS
(
    SELECT ie.stay_id
      , min(charttime) AS intime_hr
      , max(charttime) AS outtime_hr
    FROM mimic_icu.icustays ie
    INNER JOIN mimic_icu.chartevents ce
      ON ie.stay_id = ce.stay_id
      AND ce.itemid = 220045
      AND ce.charttime > DATE(ie.intime - INTERVAL '1 MONTH')
      AND ce.charttime < DATE(ie.outtime + INTERVAL '1 MONTH')
    GROUP BY ie.stay_id
)
-- now calculate time since last UO measurement
, uo_tm AS
(
    SELECT tm.stay_id
    , CASE
        WHEN LAG(charttime) OVER W IS NULL
 --       THEN DATETIME_DIFF(charttime, intime_hr, MINUTE)
--		 THEN DATE_PART('minute', intime_hr - charttime )  
		 THEN EXTRACT(EPOCH FROM charttime -intime_hr )/60.0
--	ELSE DATETIME_DIFF(charttime, LAG(charttime) OVER W, MINUTE)
--	ELSE DATE_PART('minute', LAG(charttime) OVER W - charttime ) 
		ELSE EXTRACT(EPOCH FROM charttime - LAG(charttime) OVER W  )/60.0
    END AS tm_since_last_uo
    , uo.charttime
    , uo.urineoutput
    FROM tm
    INNER JOIN mimiciv.urine_output_mv uo
        ON tm.stay_id = uo.stay_id
    WINDOW W AS (PARTITION BY tm.stay_id ORDER BY charttime)
)
, ur_stg as
(
  select io.stay_id, io.charttime
  -- we have joined each row to all rows preceding within 24 hours
  -- we can now sum these rows to get total UO over the last 24 hours
  -- we can use case statements to restrict it to only the last 6/12 hours
  -- therefore we have three sums:
  -- 1) over a 6 hour period
  -- 2) over a 12 hour period
  -- 3) over a 24 hour period
  , SUM(DISTINCT io.urineoutput) AS uo
  -- note that we assume data charted at charttime corresponds to 1 hour of UO
  -- therefore we use '5' and '11' to restrict the period, rather than 6/12
  -- this assumption may overestimate UO rate when documentation is done less than hourly
 
--	, sum(case when DATETIME_DIFF(io.charttime, iosum.charttime, HOUR) <= 5
	, sum(case when EXTRACT(EPOCH FROM io.charttime -iosum.charttime)/3600 <= 5	  
      then iosum.urineoutput
    else null end) as urineoutput_6hr
  --, SUM(CASE WHEN DATETIME_DIFF(io.charttime, iosum.charttime, HOUR) <= 5
	, sum(case when EXTRACT(EPOCH FROM io.charttime -iosum.charttime)/3600 <= 5 
		THEN iosum.tm_since_last_uo
    ELSE NULL END)/60.0 AS uo_tm_6hr
-- 	, sum(case when DATETIME_DIFF(io.charttime, iosum.charttime, HOUR) <= 11
	, sum(case when EXTRACT(EPOCH FROM io.charttime -iosum.charttime)/3600 <= 11		  
      then iosum.urineoutput
    else null end) as urineoutput_12hr
--  , SUM(CASE WHEN DATETIME_DIFF(io.charttime, iosum.charttime, HOUR) <= 11
	, sum(case when EXTRACT(EPOCH FROM io.charttime -iosum.charttime)/3600 <= 11		
        THEN iosum.tm_since_last_uo
    ELSE NULL END)/60.0 AS uo_tm_12hr
  -- 24 hours
  , sum(iosum.urineoutput) as urineoutput_24hr
  , SUM(iosum.tm_since_last_uo)/60.0 AS uo_tm_24hr

  from uo_tm io
  -- this join gives you all UO measurements over a 24 hour period
  left join uo_tm iosum
    on  io.stay_id = iosum.stay_id
    and io.charttime >= iosum.charttime
    and io.charttime <= (DATE(iosum.charttime + INTERVAL '23 HOUR'))
  group by io.stay_id, io.charttime
)
select
  ur.stay_id
, ur.charttime
, wd.weight
, ur.uo
, ur.urineoutput_6hr
, ur.urineoutput_12hr
, ur.urineoutput_24hr
, CASE WHEN uo_tm_6hr >= 6 THEN ROUND(CAST((ur.urineoutput_6hr/wd.weight/uo_tm_6hr) AS NUMERIC), 4) END AS uo_mlkghr_6hr
, CASE WHEN uo_tm_12hr >= 12 THEN ROUND(CAST((ur.urineoutput_12hr/wd.weight/uo_tm_12hr) AS NUMERIC), 4) END AS uo_mlkghr_12hr
, CASE WHEN uo_tm_24hr >= 24 THEN ROUND(CAST((ur.urineoutput_24hr/wd.weight/uo_tm_24hr) AS NUMERIC), 4) END AS uo_mlkghr_24hr
-- time of earliest UO measurement that was used to calculate the rate
, ROUND(CAST((uo_tm_6hr) AS NUMERIC), 2) AS uo_tm_6hr
, ROUND(CAST((uo_tm_12hr) AS NUMERIC), 2) AS uo_tm_12hr
, ROUND(CAST((uo_tm_24hr) AS NUMERIC), 2) AS uo_tm_24hr
from ur_stg ur
LEFT JOIN mimiciv.weight_durations_mv wd
    ON ur.stay_id = wd.stay_id
    AND ur.charttime > wd.starttime
    AND ur.charttime <= wd.endtime
    AND wd.weight > 0
;