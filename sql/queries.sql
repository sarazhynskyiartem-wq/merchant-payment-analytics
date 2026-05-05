--HHI Index
WITH market_shares AS (			
SELECT date_period,			
bank_name,			
cards_active,			
SUM(cards_active) OVER (PARTITION BY date_period) AS total_active			
FROM banks			
),			
shares_pct AS (			
SELECT date_period,			
bank_name,			
ROUND(cards_active / NULLIF(total_active, 0) * 100, 2) AS share_pct			
FROM market_shares			
),			
hhi AS (			
SELECT date_period,			
ROUND(SUM(POWER(share_pct, 2))::NUMERIC, 0) AS hhi_index			
FROM shares_pct			
GROUP BY date_period			
)			
SELECT s.date_period,			
s.bank_name,			
s.share_pct,			
h.hhi_index			
FROM shares_pct s			
JOIN hhi h USING (date_period)			
WHERE s.share_pct > 1			
ORDER BY s.date_period, s.share_pct DESC;	

--ATM and POS statistics
WITH atm_pos AS(				
SELECT date_period				
, atm_total				
, pos_total				
FROM infra_national				
WHERE date_period IN ('2020-02-01', '2025-12-01')				
), diff AS(				
SELECT *				
, (pos_total - LAG(pos_total) OVER(ORDER BY date_period))*100.0/LAG(pos_total) OVER(ORDER BY date_period) AS pos_change				
	, (atm_total - LAG(atm_total) OVER(ORDER BY date_period))*100.0/LAG(atm_total) OVER(ORDER BY date_period) AS atm_change			
FROM atm_pos				
)				
SELECT date_period				
, atm_total				
	, pos_total			
	, ROUND(atm_change::numeric, 2) AS atm_change			
	, ROUND(pos_change::numeric, 2) AS pos_change			
FROM diff				

--Cashless Ratio and avegare ticket
SELECT ROUND(cashless_ratio_pct,2) AS cashless_ratio_pct							
, ROUND(avg_ticket_uah,2 ) AS avg_ticket							
, date_period							
, ROUND(AVG(cashless_ratio_pct) OVER(PARTITION BY DATE_TRUNC('year', date_period)),2) AS cashless_rt_year							
	, ROUND(AVG(avg_ticket_uah) OVER(PARTITION BY DATE_TRUNC('year', date_period)),2) AS avg_ticket_year						
FROM operations							

--Inflation and real ticket
SELECT o.date_period				
, ROUND(i.infl_mom,1) AS inflation_mom				
	, ROUND(o.avg_ticket_uah,2) AS nominal_avg			
	, ROUND(o.avg_ticket_uah*100/i.cpi_index,2) AS real_avg_feb2020			
FROM operations o				
JOIN inflation i USING (date_period)				
