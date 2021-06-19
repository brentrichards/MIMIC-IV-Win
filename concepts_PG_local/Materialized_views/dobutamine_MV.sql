-- This query extracts dose+durations of dobutmine administration
CREATE MATERIALIZED VIEW mimiciv.dobutamine_mv AS

select
stay_id, linkorderid
, rate as vaso_rate
, amount as vaso_amount
, starttime
, endtime
from mimic_icu.inputevents
where itemid = 221653 -- dobutamine