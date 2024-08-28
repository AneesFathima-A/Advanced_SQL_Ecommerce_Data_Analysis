-- TABLES AVAILABLE
SELECT * FROM order_item_refunds;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM website_pageviews;
SELECT * FROM website_sessions;

SELECT * FROM website_pageviews
	WHERE website_session_id = 1059;
    
SELECT DISTINCT utm_source, utm_campaign, http_referer 
	FROM website_sessions
    WHERE created_at < "2012-11-27";



--                    						"ANALYZING TRAFFIC SOURCES"
-- ANALYZING TOP TRAFFIC SOURCES
/*
1-ASSIGNMENT: FINDING TOP TRAFFIC SOURCES
(Dated - April 12,2012)
# To find where the bulk of website sessions are coming from, through yesterday(april 11,2012)
# Breakdown by UTM SOURCE, CAMPAIGN and REFERRING DOMAIN
*/
SELECT 
	utm_source,
    utm_campaign,
    http_referer,
	COUNT(DISTINCT website_session_id) sessions
    FROM website_sessions
    WHERE created_at < "2012-04-12"
    GROUP BY 1,2,3
    ORDER BY 4 DESC;
    



/*
2-ASSIGNMENT: FINDING GSEARCH CONVERSION RATE
(Dated - April 14,2012)
# Found that "Gsearch nonbrand" is the major traffic source
# To understand if those sessions are driving sales
# To calculate the CONVERSION RATE (CVR) from session to order
# Need a CVR of at least 4%
*/
SELECT 
	COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT website_sessions.website_session_id) CVR
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-04-14"
		AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand";
	



-- 											BID OPTIMIZATION AND TREND ANALYSIS
/*
3-ASSIGNMENT: GSEARCH VOLUME TRENDS
(Dated - May 10, 2012)
# Based on the (previous result) conversion rate of Gsearch nonbrand: They bid down it on 15th April, 2012
# To pull gsearch nonbrand trended session volume, by week, to see if the bid changes have caused volume to drop at all
*/
SELECT MIN(DATE(created_at)) AS week_start,
	COUNT(DISTINCT website_session_id) AS sessions
    FROM website_sessions
    WHERE created_at < "2012-05-10"
		AND utm_source = "gsearch"
        AND utm_campaign = "nonbrand"
	GROUP BY 
		WEEK(created_at),
        YEAR(created_at);
        




-- 													BID OPTIMIZATION FOR PAID TRAFFIC
/*
4-ASSIGNMENT: GSEARCH DEVICE-LEVEL PERFORMANCE
# To pull conversion rates from session to order, by DEVICE TYPE
*/
SELECT 
	website_sessions.device_type,
	COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT website_sessions.website_session_id) CVR
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-05-11"
		AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand"
	GROUP BY website_sessions.device_type;
    




-- 												TRENDING WITH GRANULAR SEGMENTS
/*
5-ASSIGNMENT: GSEARCH DEVICE LEVEL TRENDS (NO.OF SESSIONS)
(Dated - June 9, 2012)
# The bid was raised for gsearch nonbrand desktop segment (ref with previous result)
# To pull weekly trends for both desktop and mobile
# "use 2012-04-15 until the bid change as a baseline"
*/
SELECT 
	MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN website_session_id ELSE NULL END) AS desktop_traffic,
	COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) AS mobile_traffic
	FROM website_sessions
    WHERE created_at BETWEEN "2012-04-15" AND "2012-06-09"
		AND utm_source = "gsearch"
        AND utm_campaign = "nonbrand"
	GROUP BY 
		WEEK(created_at),
		YEAR(created_at);
	
    



-- 		   								ANALYZING WEBSITE PERFORMANCE
-- ANALYZING TOP WEBSITE CONTENT (analyzing top website pages & entry pages)
/*
6-ASSIGNMENT: TOP WEBSITE PAGES
(Dated - June 9, 2012)
# To pull most-viewed website pages, ranked by session volume
*/
SELECT 
	pageview_url,
	COUNT(DISTINCT website_pageview_id) AS pg_views
	FROM website_pageviews
    WHERE created_at < "2012-06-09"
    GROUP BY 1
    ORDER BY 2 DESC;
    



/*
7-ASSIGNMENT: TOP ENTRY PAGES
(Dated - June 12, 2012)
# To pull the list of the TOP ENTRY PAGES and rank them on entry volume
*/
CREATE TEMPORARY TABLE lander
SELECT 
    website_session_id,
    MIN(website_pageview_id) min_pgview
	FROM website_pageviews
    WHERE created_at < "2012-06-12"
    GROUP BY website_session_id;
    
SELECT * FROM lander;

SELECT 
	website_pageviews.pageview_url AS entry_pg,
    COUNT(DISTINCT lander.website_session_id) hits_on_lander
    FROM lander
    LEFT JOIN website_pageviews
    ON lander.min_pgview = website_pageviews.website_pageview_id
    GROUP BY 1;
    




-- (LANDING PAGE PERFORMANCE AND TESTING)
-- 											ANALYZING BOUNCE RATES & LANDING PAGE TESTS
/*
8-ASSIGNMENT: BOUNCE RATE ANALYSIS
(Dated - June 14, 2012)
# All traffic is landing on home page (from previous result)
# To pull: Sessions, Bounced sessions, Bounce rate
*/
CREATE TEMPORARY TABLE min_pgv_of_each_sessions
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pgview
	FROM website_pageviews
    WHERE created_at < "2012-06-14"
    GROUP BY website_session_id;
    
SELECT * FROM min_pgv_of_each_sessions;

CREATE TEMPORARY TABLE landing_pgs
SELECT 
	min_pgv_of_each_sessions.website_session_id,
    website_pageviews.pageview_url
	FROM min_pgv_of_each_sessions
    LEFT JOIN website_pageviews
    ON min_pgv_of_each_sessions.min_pgview = website_pageviews.website_pageview_id;
    
SELECT * FROM landing_pgs;

CREATE TEMPORARY TABLE bounced_only
SELECT 
	landing_pgs.website_session_id,
    landing_pgs.pageview_url,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS count_of_pgvs
	FROM landing_pgs
    LEFT JOIN website_pageviews
    ON landing_pgs.website_session_id = website_pageviews.website_session_id
    GROUP BY 1,2
    HAVING count_of_pgvs = 1;

SELECT * FROM bounced_only;

CREATE TEMPORARY TABLE bounce_for_ref
SELECT 
	landing_pgs.pageview_url,	
	landing_pgs.website_session_id,
    bounced_only.website_session_id AS bounced_sessions
	FROM landing_pgs
	LEFT JOIN bounced_only
    ON landing_pgs.website_session_id = bounced_only.website_session_id
    ORDER BY 2;
    
SELECT * FROM bounce_for_ref;

SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) sessions_count,
    COUNT(DISTINCT bounced_sessions) bounced_sessions_count,
    COUNT(DISTINCT bounced_sessions) / COUNT(DISTINCT website_session_id) AS bounce_rate
	FROM bounce_for_ref
    GROUP BY 1;
    



-- 												ANALYZING LANDING PAGE TESTS
/*
9-ASSIGNMENT: HELP ANALYZING LANDING PAGE TEST
(Dated - July 28, 2012)
# New custom landing page (/lander-1) in a 50/50 test against the homepage (/home) for gsearch nonbrand traffic was ran
# To pull the bounce rates for the two groups - to evaluate the new page
# Look at the time period where /lander-1 was getting traffic - for fair comparison
*/
SELECT 
    MIN(created_at) first_created_at,
    MIN(website_pageview_id) first_pgview_id
    FROM website_pageviews
    WHERE 
        pageview_url = "/lander-1"
        AND created_at < "2012-07-28";                                           -- RESULT-1


-- analyze between 2012-06-19 and 2012-07-28

CREATE TEMPORARY TABLE first_pgv
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) first_pg_id
	FROM website_pageviews
    INNER JOIN website_sessions
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE website_sessions.created_at < "2012-07-28"
		AND website_pageviews.website_pageview_id > 23504
        AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand"
    GROUP BY 1;
    
SELECT * FROM first_pgv;

CREATE TEMPORARY TABLE first_landed
SELECT 
    first_pgv.website_session_id,
	first_pgv.first_pg_id,
    website_pageviews.pageview_url
    FROM first_pgv
    LEFT JOIN website_pageviews
    ON first_pgv.first_pg_id = website_pageviews.website_pageview_id;
-- SELECT * FROM website_pageviews WHERE website_session_id= 11616
SELECT * FROM first_landed;

CREATE TEMPORARY TABLE bounced_pageviews
SELECT
	first_landed.website_session_id,
    first_landed.pageview_url,
	COUNT(DISTINCT website_pageviews.website_pageview_id) AS pg_bounced
    FROM first_landed
    LEFT JOIN website_pageviews
    ON first_landed.website_session_id = website_pageviews.website_session_id
    GROUP BY 1,2
    HAVING pg_bounced = 1;
    
SELECT * FROM bounced_pageviews;

CREATE TEMPORARY TABLE bounced_pageviews_ref
SELECT 
	first_landed.pageview_url,
    first_landed.website_session_id,
    bounced_pageviews.website_session_id AS sessions_bounced
    FROM first_landed
    LEFT JOIN bounced_pageviews
    ON first_landed.website_session_id =  bounced_pageviews.website_session_id;
    
SELECT * FROM bounced_pageviews_ref;

SELECT
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT sessions_bounced) AS bounced_sessions,
    COUNT(DISTINCT sessions_bounced)/COUNT(DISTINCT website_session_id) AS bounce_rate
    FROM bounced_pageviews_ref
    GROUP BY 1;
    



/*
10-ASSIGNMENT: LANDING PAGE TREND ANALYSIS
(Dated - August 31, 2012)
# To pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1 
# To pull overall paid search bounce rate trended weekly
*/
CREATE TEMPORARY TABLE first_landed
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) first_pg_id,
    COUNT(website_pageviews.website_pageview_id) count_of_pg
	FROM website_pageviews
    LEFT JOIN website_sessions
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE 
		website_sessions.created_at > "2012-06-01"
        AND website_sessions.created_at < "2012-08-31"
        AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand"
	GROUP BY 1;
    
SELECT * FROM first_landed;

CREATE TEMPORARY TABLE web_sess_firstpg
SELECT 
	first_landed.website_session_id,
    first_landed.first_pg_id,
    first_landed.count_of_pg,
    website_pageviews.pageview_url,
    DATE(created_at) created_at
    FROM first_landed
    LEFT JOIN website_pageviews
    ON first_landed.first_pg_id = website_pageviews.website_pageview_id;
    
SELECT * FROM web_sess_firstpg;

SELECT 
	MIN(created_at) AS week_start,
    COUNT(DISTINCT CASE WHEN pageview_url = "/home" THEN website_session_id END) AS home_traffic,
	COUNT(DISTINCT CASE WHEN pageview_url = "/lander-1" THEN website_session_id END) AS lander_1_traffic,
    COUNT(DISTINCT CASE WHEN count_of_pg = 1 THEN website_session_id END) / COUNT(DISTINCT website_session_id) AS bounce_rate
    FROM web_sess_firstpg
    GROUP BY YEARWEEK(created_at);
    



--                                     ANALYZING AND TESTING CONVERSION FUNNELS
/*
11-ASSIGNMENT: ANALYZING CONVERSION FUNNELS
(Dated - September 5, 2012)
To build a full conversion funnel, analyzing how many GSEARCH customers make it to each step (Since AUGUST 5)
*/    

/*
SELECT DISTINCT website_pageviews.pageview_url
	FROM website_sessions
     LEFT JOIN website_pageviews
     ON website_sessions.website_session_id = website_pageviews.website_session_id
     WHERE website_sessions.created_at > "2012-08-05"
		AND website_sessions.created_at < "2012-09-05"
        AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand"; 
*/     															-- for checking distinct pageview_url

CREATE TEMPORARY TABLE count_conversion_funnel
SELECT
	COUNT(website_session_id) sessions,
    -- SUM(lander_pg) to_lander_1,
    SUM(products_pg) to_products,
    SUM(fuzzy_pg) to_fuzzy,
    SUM(cart_pg) to_cart,
    SUM(shipping_pg) to_shipping,
    SUM(billing_pg) to_billing,
    SUM(thanks_pg) to_thanks
	
    FROM (SELECT
		website_session_id,
		MAX(lander_1) lander_pg,
		MAX(products) products_pg,
		MAX(fuzzy) fuzzy_pg,
		MAX(cart) cart_pg,
		MAX(shipping) shipping_pg,
		MAX(billing) billing_pg,
		MAX(thanks) thanks_pg
		FROM (SELECT 
			website_sessions.website_session_id,
			website_pageviews.pageview_url,
			CASE WHEN website_pageviews.pageview_url = "/lander-1" THEN 1 ELSE 0 END AS lander_1,
			CASE WHEN website_pageviews.pageview_url = "/products" THEN 1 ELSE 0 END AS products,
			CASE WHEN website_pageviews.pageview_url = "/the-original-mr-fuzzy" THEN 1 ELSE 0 END AS fuzzy,
			CASE WHEN website_pageviews.pageview_url = "/cart" THEN 1 ELSE 0 END AS cart,
			CASE WHEN website_pageviews.pageview_url = "/shipping" THEN 1 ELSE 0 END AS shipping,
			CASE WHEN website_pageviews.pageview_url = "/billing" THEN 1 ELSE 0 END AS billing,
			CASE WHEN website_pageviews.pageview_url = "/thank-you-for-your-order" THEN 1 ELSE 0 END AS thanks
		FROM website_sessions
		LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
		WHERE website_sessions.created_at > "2012-08-05"
			AND website_sessions.created_at < "2012-09-05"
			AND website_sessions.utm_source = "gsearch"
			AND website_sessions.utm_campaign = "nonbrand") AS table_1
	
		GROUP BY website_session_id) AS table_2;
        
SELECT * FROM count_conversion_funnel;																-- result - 1

SELECT 
	sessions,
    (to_products / sessions) rate_to_products,
    (to_fuzzy / to_products) rate_to_fuzzy,
    (to_cart / to_fuzzy) rate_to_cart,
    (to_shipping / to_cart) rate_to_shipping,
    (to_billing / to_shipping) rate_to_billing,
    (to_thanks / to_billing) rate_to_thanks
    FROM count_conversion_funnel;																	-- result - 2





/*
12-ASSIGNMENT: CONVERSION FUNNEL TEST RESULTS
(Dated - November 10, 2012)
To see whether /billing-2 is doing any better than the original /billing page
To pull what % of sessions on those pages end up placing an order
All traffic, not just for search visitors
*/	

-- finding the first time /billing-2 was seen
SELECT
	MIN(DATE(created_at)) date_billing2,
    MIN(website_pageview_id) pv_id_billing2
    FROM website_pageviews
    WHERE pageview_url = "/billing-2"
		AND created_at < "2012-11-10";               -- result - date: 2012-09-10    ;     pv_id: 53550
        
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
	COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT website_pageviews.website_session_id) AS cvr 
    FROM website_pageviews
    LEFT JOIN orders
    ON website_pageviews.website_session_id = orders.website_session_id
    WHERE 
		pageview_url IN ("/billing", "/billing-2")
        AND website_pageviews.created_at > "2012-09-10"
		AND website_pageviews.created_at < "2012-11-10"
        AND website_pageviews.website_pageview_id >= 53550
	GROUP BY pageview_url;
    




--                                           MID-COURSE PROJECT

-- (Dated - November 27, 2012)
-- 1 - monthly trends for gsearch sessions and orders

SELECT
	YEAR(website_sessions.created_at) year,
    MONTH(website_sessions.created_at) month,
	-- MIN(DATE(website_sessions.created_at)) month_start,
    COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id) / COUNT(DISTINCT website_sessions.website_session_id) session_to_order_cvr
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-11-27"
		AND website_sessions.utm_source = "gsearch"
    GROUP BY YEAR(website_sessions.created_at), MONTH(website_sessions.created_at);
    
-- 2 - splitting out nonbrand and brand campaigns separately
  
SELECT 
	YEAR(website_sessions.created_at) year,
    MONTH(website_sessions.created_at) month,
	-- MIN(DATE(website_sessions.created_at)) month_start,
	COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN website_sessions.website_session_id END) brand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN orders.website_session_id END) brand_orders,
    (COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN orders.website_session_id END) / 
		COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN website_sessions.website_session_id END)) AS brand_cvr,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN website_sessions.website_session_id END) nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN orders.website_session_id END) nonbrand_orders,
    (COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN orders.website_session_id END) /
		COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN website_sessions.website_session_id END)) AS nonbrand_cvr
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-11-27"
		AND website_sessions.utm_source = "gsearch"
    GROUP BY 1, 2;
    
-- 3 - to pull monthly sessions and orders split by device type for Gsearch nonbrand

SELECT 
	YEAR(website_sessions.created_at) year,
    MONTH(website_sessions.created_at) month,
	-- MIN(DATE(website_sessions.created_at)) month_start,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = "mobile" THEN website_sessions.website_session_id END) mobile_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = "mobile" THEN orders.website_session_id END) mobile_orders,
    (COUNT(DISTINCT CASE WHEN website_sessions.device_type = "mobile" THEN orders.website_session_id END) /
		COUNT(DISTINCT CASE WHEN website_sessions.device_type = "mobile" THEN website_sessions.website_session_id END)) AS mobile_cvr,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = "desktop" THEN website_sessions.website_session_id END) desktop_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = "desktop" THEN orders.website_session_id END) desktop_orders,
    (COUNT(DISTINCT CASE WHEN website_sessions.device_type = "desktop" THEN orders.website_session_id END) /
		COUNT(DISTINCT CASE WHEN website_sessions.device_type = "desktop" THEN website_sessions.website_session_id END)) AS desktop_cvr
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-11-27"
		AND website_sessions.utm_source = "gsearch"
        AND website_sessions.utm_campaign = "nonbrand"
    GROUP BY 1, 2;
    
-- 4 - to pull monthly trends for Gsearch, alongside monthly trends for each of the other channels

SELECT 
	YEAR(website_sessions.created_at) year,
    MONTH(website_sessions.created_at) month,
    
    COUNT(DISTINCT CASE WHEN utm_source = "gsearch" THEN website_sessions.website_session_id END) gsearch_sessions,    
    COUNT(DISTINCT CASE WHEN utm_source = "bsearch" THEN website_sessions.website_session_id END) bsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id END) organic_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id END) direct_sessions
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-11-27"
    GROUP BY 1, 2;
    
-- 5 - session to order conversion rates by months

SELECT
	YEAR(website_sessions.created_at) year,
    MONTH(website_sessions.created_at) month,
    COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id) / COUNT(DISTINCT website_sessions.website_session_id) session_to_order_cvr
	FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at < "2012-11-27"
    GROUP BY 1, 2;
    
-- 6  
-- for the gsearch lander test, please estimate the revenue that test earned us (Hint: look at the increase in CVR from the test 
-- (Jun 19 - July 28), and use nonbrand sessions and revenue since then to calculate incremental value)

-- SELECT DISTINCT pageview_url FROM website_pageviews WHERE created_at > "2012-06-19" AND created_at < "2012-07-28";

/*
SELECT MIN(website_pageview_id) 
	FROM website_pageviews
    LEFT JOIN website_sessions
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE utm_source = "gsearch"
		AND pageview_url = "/lander-1";
*/

CREATE TEMPORARY TABLE landers
SELECT 
	website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) landing_pg
    FROM website_sessions
    LEFT JOIN website_pageviews
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE utm_source = "gsearch"
		AND website_pageview_id >= 23504
        AND website_sessions.created_at > "2012-06-19"
        AND website_sessions.created_at < "2012-07-28"
	GROUP BY 1;
    
SELECT * FROM landers;
    
CREATE TEMPORARY TABLE landers_url
SELECT 
	landers.website_session_id,
    landers.landing_pg,
    website_pageviews.pageview_url
    FROM landers
    LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = landers.website_session_id
		WHERE website_pageviews.pageview_url IN ("/home", "/lander-1");
        
SELECT * FROM landers_url;

SELECT
	landers_url.pageview_url,
	COUNT(DISTINCT landers_url.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT landers_url.website_session_id) AS cvr
    FROM landers_url
    LEFT JOIN orders
    ON landers_url.website_session_id = orders.website_session_id
    GROUP BY 1;
    
-- 7 - full conversion funnel from each of the two landing pages to order (jun 19 - jul 28)

CREATE TEMPORARY TABLE cv_from_landers
SELECT 
		website_session_id,
		MAX(home_pg) home_pg,
        MAX(lander_1) lander_1,
		MAX(prod_pg) prod_pg,
		MAX(mrfuzzy) mrfuzzy,
		MAX(cart_pg) cart_pg,
		MAX(ship_pg) ship_pg,
		MAX(bill_pg) bill_pg,
		MAX(thanks_pg) thanks_pg 
	FROM(
    
		SELECT 
			website_pageviews.website_session_id,
			CASE WHEN pageview_url="/home" THEN 1 ELSE 0 END AS home_pg,
            CASE WHEN pageview_url="/lander-1" THEN 1 ELSE 0 END AS lander_1,
			CASE WHEN pageview_url="/products" THEN 1 ELSE 0 END AS prod_pg,
			CASE WHEN pageview_url="/the-original-mr-fuzzy" THEN 1 ELSE 0 END mrfuzzy,
			CASE WHEN pageview_url="/cart" THEN 1 ELSE 0 END AS cart_pg,
			CASE WHEN pageview_url="/shipping" THEN 1 ELSE 0 END AS ship_pg,
			CASE WHEN pageview_url="/billing" THEN 1 ELSE 0 END AS bill_pg,
			CASE WHEN pageview_url="/thank-you-for-your-order" THEN 1 ELSE 0 END AS thanks_pg
		FROM website_sessions LEFT JOIN website_pageviews
			ON website_sessions.website_session_id = website_pageviews.website_session_id
				WHERE utm_source="gsearch"
					AND utm_campaign="nonbrand"
                    AND website_sessions.created_at > "2012-06-19"
                    AND website_sessions.created_at < "2012-07-28") clickthrough
	GROUP BY 1;

SELECT 
	lander_segments,
    to_prod_pg/sessions AS lander_click_rate,
    to_mrfuzzy/to_prod_pg AS prod_click_rate,
    to_cart_pg/to_mrfuzzy AS mrfuzzy_click_rate,
    to_ship_pg/to_cart_pg AS cart_click_rate,
    to_bill_pg/to_ship_pg AS ship_click_rate,
    to_thanks_pg/to_bill_pg AS bill_click_rate
    FROM (

SELECT CASE 
	WHEN home_pg=1 THEN "home_pg" 
	WHEN lander_1=1 THEN "lander_1"
    END AS lander_segments,
    COUNT(DISTINCT website_session_id) sessions,
    SUM(prod_pg) to_prod_pg,
	SUM(mrfuzzy) to_mrfuzzy,
    SUM(cart_pg) to_cart_pg,
    SUM(ship_pg) to_ship_pg,
    SUM(bill_pg) to_bill_pg,
    SUM(thanks_pg) to_thanks_pg
FROM cv_from_landers
GROUP BY 1) clickthrough_rt
GROUP BY 1;

-- 8 - quantifying the imapct of billing test
-- revenue per billing session, and to pull the no. of billing page sessions for the past month (sep 10 - nov 10)

SELECT
	billing_pg,
	COUNT(DISTINCT website_session_id) sessions,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) orders_per_session,
    SUM(price_usd)/COUNT(DISTINCT website_session_id) rev_per_session
FROM(
	SELECT
		website_pageviews.website_session_id,
        website_pageviews.pageview_url AS billing_pg,
        orders.order_id,
        orders.price_usd
        FROM website_pageviews LEFT JOIN orders
			ON website_pageviews.website_session_id = orders.website_session_id
		WHERE website_pageviews.pageview_url IN ('/billing', '/billing-2')
			AND website_pageviews.created_at > "2012-09-10"
            AND website_pageviews.created_at < "2012-11-10") billing_pg
	
GROUP BY 1;

-- for past month
SELECT 
	COUNT(DISTINCT website_session_id) AS billing_sessions_last_month
FROM website_pageviews
WHERE pageview_url IN ('/billing', '/billing-2')
	AND created_at BETWEEN "2012-10-27" AND "2012-11-27";





-- 													CHANNEL PORTFOLIO OPTIMIZATION
-- 13 - ASSIGNMENT: EXPANDED CHANNEL PORTFOLIO
-- (Dated - November 29, 2012)
-- additional to gsearch, we launched a second paid search challen, bsearch around AUGUST 22
-- To pull weekly trended session volume since then and compare to gsearch nonbrand
-- 								so I can get a sense for how important this will for the business

SELECT 
	MIN(DATE(created_at)) week_start,
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" THEN website_session_id END) gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" THEN website_session_id END) bsearch_sessions
    FROM website_sessions 
    WHERE created_at > "2012-08-22"
		AND created_at < "2012-11-29"
	GROUP BY YEARWEEK(created_at);
    




-- 14 - ASSIGNMENT: COMPARING CHANNELS
-- (Dated - nov 30, 2012)
-- To know about bsearch nonbrand campaign
-- to pull the percentage oftraffic coming on mobile and compare that to g search
-- aggregate data since 22 august

SELECT
	utm_source,
	COUNT(DISTINCT website_session_id) sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id END) mob_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id END) / COUNT(DISTINCT website_session_id) AS mob_percent
    FROM website_sessions
    WHERE created_at > "2012-08-22"
		AND created_at < "2012-11-30" 
        AND utm_campaign = "nonbrand"
        -- AND utm_source IN ("gsearch", "bsearch")
	GROUP BY 1;
    



-- 15 - ASSIGNMENT: MULTI-CHANNEL BIDDING
-- (Dated - dec 1, 2012)
-- TO pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the data by device type
-- analyze data from august 22 to sep 18 (since pre-holiday campaign for gsearch starting on 19th sep)
    
SELECT
	device_type,
	utm_source,
	COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.website_session_id) orders,
    COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT website_sessions.website_session_id) cvr
    FROM website_sessions LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at > "2012-08-22"
		AND website_sessions.created_at < "2012-09-18" 
        AND utm_campaign = "nonbrand"
        -- AND utm_source IN ("gsearch", "bsearch")
	GROUP BY 1, 2;
    



-- 16 - ASSIGNMENT: IMPACT OF BID CHANGES
-- (dated - Dec 22, 2012)
-- bsearch nonbrand bid was made down on DEC 2nd
-- to pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since NOV 4th
-- include a comparison metric to show bsearch as percent of gserach for each device 

SELECT 
	MIN(DATE(created_at)) week_start,
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type="desktop" THEN website_session_id END) AS g_desktop,
	COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type="desktop" THEN website_session_id END) AS b_desktop,
    (COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type="desktop" THEN website_session_id END)/
		COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type="desktop" THEN website_session_id END)) b_to_g_desktop,
    
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type="mobile" THEN website_session_id END) AS g_mob,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type="mobile" THEN website_session_id END) AS b_mob,
    (COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type="mobile" THEN website_session_id END)/
		COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type="mobile" THEN website_session_id END)) b_to_g_mobile
        
	FROM website_sessions
    WHERE created_at > "2012-11-04"
		AND created_at < "2012-12-22"
        AND utm_campaign = "nonbrand"
	GROUP BY YEARWEEK(created_at);
    




-- 17 - ASSIGNMENT: SITE TRAFFIC BREAKDOWN
-- (Dated - dec 23, 2012)
-- pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as a % of paid search nonbrand
-- SELECT DISTINCT utm_source, utm_campaign,  http_referer FROM website_sessions WHERE created_at< "2012-12-23";
SELECT 
		YEAR(created_at) year,
		MONTH(created_at) month,
		COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id END) AS nonbrand,
		COUNT(DISTINCT CASE WHEN utm_campaign="brand" THEN website_session_id END) AS brand,
		(COUNT(DISTINCT CASE WHEN utm_campaign="brand" THEN website_session_id END)/
			COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id END)) brand_to_nonbrand_percent,
		COUNT(DISTINCT CASE WHEN http_referer IS NULL AND utm_source IS NULL THEN website_session_id END) AS direct,
		(COUNT(DISTINCT CASE WHEN http_referer IS NULL AND utm_source IS NULL THEN website_session_id END)/
			COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id END)) AS direct_to_nonbrand_percent,
		COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ("https://www.gsearch.com", "https://www.bsearch.com") THEN website_session_id END) AS organic,
		(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ("https://www.gsearch.com", "https://www.bsearch.com") THEN website_session_id END)/
			COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id END)) AS organic_to_nonbrand_percent
	FROM website_sessions
    WHERE created_at < "2012-12-23"
    GROUP BY 1,2;
    
    



-- 18 - ASSIGNMENT: UNDERSTANDING SEASONALITY
-- (Dated - Jan 3, 2013)
-- 2012's monthly and weekly volume pattern

SELECT 
	YEAR(website_sessions.created_at) yr,
    MONTH(website_sessions.created_at) month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.website_session_id) AS orders
	FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE YEAR(website_sessions.created_at) = "2012"
    GROUP BY 1,2;															-- MONTHLY TRENDS
    
SELECT 
	MIN(DATE(website_sessions.created_at)) week_start,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.website_session_id) AS orders
	FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE YEAR(website_sessions.created_at) = "2012"
    GROUP BY YEARWEEK(website_sessions.created_at);							-- WEEKLY TRENDS
    



-- 19 - ASSIGNMENT: DATA FOR CUSTOMER SERVICE
-- (Dated - jan 5, 2013)
-- average website session volume, by hour of day and by day week
-- avoid the holiday time period (sep 15 - nov 15, 2012)

SELECT 
	hr,
    ROUND(AVG(CASE WHEN days=0 THEN sessions ELSE NULL END),1) monday,
    ROUND(AVG(CASE WHEN days=1 THEN sessions ELSE NULL END),1) tuesday,
    ROUND(AVG(CASE WHEN days=2 THEN sessions ELSE NULL END),1) wednesday,
    ROUND(AVG(CASE WHEN days=3 THEN sessions ELSE NULL END),1) thursday,
    ROUND(AVG(CASE WHEN days=4 THEN sessions ELSE NULL END),1) friday,
    ROUND(AVG(CASE WHEN days=5 THEN sessions ELSE NULL END),1) saturday,
    ROUND(AVG(CASE WHEN days=6 THEN sessions ELSE NULL END),1) sunday
    FROM (SELECT 
		DATE(created_at) date,
        WEEKDAY(created_at) days,
        HOUR(created_at) hr,
        COUNT(DISTINCT website_session_id) sessions
        FROM website_sessions
        WHERE created_at BETWEEN "2012-09-15" AND "2012-11-15"
        GROUP BY HOUR(created_at), WEEKDAY(created_at), DATE(created_at)) AS daily_hrly
	GROUP BY 1
    ORDER BY 1;
    



-- 20 - ASSIGNMENT: SALES TRENDS
-- (Dated - jan 4, 2013)
-- pull monthly trends to date for no. of sales, total revenue, and total margin generated for the business

SELECT 
	YEAR(created_at) yr,
    MONTH(created_at) mo,
	COUNT(DISTINCT order_id) no_of_sales,
    SUM(price_usd) revenue,
    SUM(price_usd - cogs_usd) margin
    FROM orders
    WHERE created_at < "2013-01-04"
    GROUP BY 1, 2;
    



-- 21 - ASSIGNMENT: IMPACT ON NEW PRODUCT LAUNCH
-- (Dated - april 5, 2013)
-- to pull monthly order volume, overall cvr, revenue per session, and breakdown of sales by product (since APRIL 1, 2012)

SELECT 
	YEAR(website_sessions.created_at) yr,
    MONTH(website_sessions.created_at) mo,
    COUNT(DISTINCT orders.order_id) orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) cvr,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id END) AS product_1_sales,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id END) AS product_2_sales
    FROM website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at > "2012-04-01" 
		AND website_sessions.created_at < "2013-04-05"
	GROUP BY 1, 2;
    



-- 22 - ASSIGNMENT: HELP WITH THE USER PATHING
-- (Dated - april 6, 2013)
-- to look at sessions which hit the /products page and seee where they went next
-- to pull clickthrough rates from /products since the new product launch on JANUARY 6th 2013 by products
-- compare to the 3 months leading up to launch as a baseline

CREATE TEMPORARY TABLE products_pgview
SELECT
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < "2013-01-06" THEN "pre_product_2" 
        WHEN created_at >= "2013-01-06" THEN "post_product_2"
        ELSE "check"
        END AS time_period
	FROM website_pageviews
    WHERE created_at > "2012-10-06"
		AND created_at < "2013-04-06"
        AND pageview_url = "/products";
        
SELECT * FROM products_pgview;

CREATE TEMPORARY TABLE clickthrough_to_nxtpg
SELECT
	products_pgview.time_period,
    products_pgview.website_session_id,
    MIN(website_pageviews.website_pageview_id) min_pv_id
    FROM products_pgview LEFT JOIN website_pageviews 
    ON products_pgview.website_session_id = website_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > products_pgview.website_pageview_id
	GROUP BY 1, 2;
    
SELECT * FROM clickthrough_to_nxtpg;

 SELECT DISTINCT pageview_url FROM clickthrough_to_nxtpg LEFT JOIN website_pageviews ON min_pv_id = website_pageview_id;

CREATE TEMPORARY TABLE product_url
SELECT time_period,
	   clickthrough_to_nxtpg.website_session_id,
       -- clickthrough_to_nxtpg.min_pv_id,
       pageview_url
       FROM clickthrough_to_nxtpg LEFT JOIN website_pageviews
       ON clickthrough_to_nxtpg.min_pv_id = website_pageviews.website_pageview_id;

SELECT * FROM product_url;

SELECT
	time_period,
	COUNT(DISTINCT website_session_id) sessions,
    COUNT(DISTINCT CASE WHEN pageview_url IS NOT NULL THEN website_session_id END) w_nxt_pg,
    (COUNT(DISTINCT CASE WHEN pageview_url IS NOT NULL THEN website_session_id END)/
		COUNT(DISTINCT website_session_id)) AS pct_w_nxt_pg,
	COUNT(DISTINCT CASE WHEN pageview_url="/the-original-mr-fuzzy" THEN website_session_id END) AS to_mrFuzzy,
    (COUNT(DISTINCT CASE WHEN pageview_url="/the-original-mr-fuzzy" THEN website_session_id END)/
		COUNT(DISTINCT website_session_id)) AS pct_to_mrFuzzy,
	COUNT(DISTINCT CASE WHEN pageview_url="/the-forever-love-bear" THEN website_session_id END) AS to_lovebear,
    (COUNT(DISTINCT CASE WHEN pageview_url="/the-forever-love-bear" THEN website_session_id END)/
		COUNT(DISTINCT website_session_id)) AS pct_to_lovebear
	FROM product_url
    GROUP BY 1
    ORDER BY 1 DESC;
    



-- 23 - ASSIGNMENT: PRODUCT CONVERSION FUNNELS
-- (Dated - april 10, 2013)
-- conversion funnels from each (two) product page to conversion (since jan 6th)
-- produce a comparison between the two conversion funnels, for all website traffic

CREATE TEMPORARY TABLE products_pgv
SELECT website_session_id,
	website_pageview_id,
    pageview_url AS product_pg
    FROM website_pageviews
    WHERE created_at > "2013-01-06"
		AND created_at < "2013-04-10"
        AND pageview_url IN ("/the-original-mr-fuzzy", "/the-forever-love-bear");
        
SELECT * FROM products_pgv;

SELECT DISTINCT
	website_pageviews.pageview_url
    FROM products_pgv LEFT JOIN website_pageviews
    ON products_pgv.website_session_id = website_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > products_pgv.website_pageview_id
        AND website_pageviews.pageview_url NOT IN ("/billing");
        
SELECT
	product_pg,
	COUNT(DISTINCT website_session_id) product_pg,
    SUM(to_cart_pg) to_cart_pg,
		SUM(to_cart_pg)/COUNT(DISTINCT website_session_id) rate_to_cart_pg,
    SUM(to_shipping_pg) to_shipping_pg,
		SUM(to_shipping_pg)/SUM(to_cart_pg) rate_to_shipping_pg,
    SUM(to_billing_pg) to_billing_pg,
		SUM(to_billing_pg)/SUM(to_shipping_pg) rate_to_billing_pg,
    SUM(to_thanks_pg) to_thanks_pg,
		SUM(to_thanks_pg)/SUM(to_billing_pg) rate_to_thanks_pg
FROM(
SELECT 
	website_session_id,
    product_pg,
    MAX(cart_pg) to_cart_pg,
    MAX(shipping_pg) to_shipping_pg,
    MAX(billing_pg) to_billing_pg,
    MAX(thanks_pg) to_thanks_pg
FROM(
    SELECT 
		products_pgv.website_session_id,
		product_pg,
		CASE WHEN pageview_url="/cart" THEN 1 ELSE 0 END AS cart_pg,
		CASE WHEN pageview_url="/shipping" THEN 1 ELSE 0 END AS shipping_pg,
		CASE WHEN pageview_url="/billing-2" THEN 1 ELSE 0 END AS billing_pg,
		CASE WHEN pageview_url="/thank-you-for-your-order" THEN 1 ELSE 0 END AS thanks_pg
		FROM products_pgv LEFT JOIN website_pageviews
			ON products_pgv.website_session_id = website_pageviews.website_session_id
			AND website_pageviews.website_pageview_id > products_pgv.website_pageview_id) AS pg_funnel
            
	GROUP BY 1, 2) AS funnel_analysis
GROUP BY 1;




-- 24 - ASSIGNMENT: CROSS SELLING PERFORMANCE
-- (Dated - nov 22, 2013)
-- on 25th sep, we started giving customers the option to add a 2nd product while on the /cart page
-- compare the month before vs the month after the change
-- to pull CTR(click through rate) from the /cart page, avg products per order, AOV(avg order value) 
							-- and overall revenue per /cart page view

CREATE TEMPORARY TABLE cart_sessions
SELECT CASE
	WHEN created_at < "2013-09-25" THEN "pre_cross_selling"
	WHEN created_at >= "2013-09-25" THEN "post_cross_selling"
    END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pgv_id
    FROM website_pageviews
	WHERE created_at BETWEEN "2013-08-25" AND "2013-10-25"
		AND pageview_url="/cart";

CREATE TEMPORARY TABLE pgv_after_cart
SELECT 
	cart_sessions.time_period,
	cart_sessions.cart_session_id,
	MIN(website_pageviews.website_pageview_id) AS pgv_after_cart
	FROM cart_sessions LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = cart_sessions.cart_session_id
		AND website_pageviews.website_pageview_id > cart_sessions.cart_pgv_id
	GROUP BY 1, 2
		HAVING 
			MIN(website_pageviews.website_pageview_id) IS NOT NULL;
            
CREATE TEMPORARY TABLE session_orders
SELECT 
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
    FROM cart_sessions INNER JOIN orders
		ON cart_sessions.cart_session_id = orders.website_session_id;
			
SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) cart_sessions,
    -- SUM(clicked_after_cart) sessions_clicked_after_cart,
    SUM(clicked_after_cart)/COUNT(DISTINCT cart_session_id) cart_CTR,
    -- SUM(placed_order) sessions_placed_order,
    -- SUM(items_purchased) items_purchased,
    SUM(items_purchased)/SUM(placed_order) products_per_order,
    -- SUM(price_usd) total_revenue,
    SUM(price_usd)/SUM(items_purchased) avg_order_value,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) revenue_per_cart_session
FROM(

	SELECT
		cart_sessions.time_period,
		cart_sessions.cart_session_id,
		CASE WHEN pgv_after_cart.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_after_cart,
		CASE WHEN session_orders.cart_session_id IS NULL THEN 0 ELSE 1 END AS placed_order,
		items_purchased,
		price_usd
		FROM cart_sessions 
			LEFT JOIN pgv_after_cart
				ON cart_sessions.cart_session_id = pgv_after_cart.cart_session_id
			LEFT JOIN session_orders
				ON cart_sessions.cart_session_id = session_orders.cart_session_id
		ORDER BY 2) cart_sessions

GROUP BY 1
ORDER BY 1 DESC;





-- 25 - ASSIGNMENT: RECENT PRODUCT LAUNCH
-- (Dated - jan 12, 2014)
-- new product was launched on dec 12, 2013 (Birthday Bear)
-- pull a pre-post analysis comparing the month before vs. the month after, in terms of
-- 					cvr, AOV (avg order value), products per order and revenue per session

SELECT * FROM orders;
SELECT 
	CASE 
		WHEN website_sessions.created_at < "2013-12-12" THEN "pre_birthday_bear"
        WHEN website_sessions.created_at >= "2013-12-12" THEN "post_birthday_bear" 
	ELSE "happy_birthday" END AS time_period,
    -- COUNT(DISTINCT website_sessions.website_session_id),
    -- COUNT(DISTINCT orders.order_id),
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) session_to_order_cvr,
    SUM(price_usd)/SUM(items_purchased) avg_order_value,
    SUM(items_purchased)/COUNT(DISTINCT orders.order_id) prod_per_order,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) rev_per_session
FROM website_sessions LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at BETWEEN "2013-11-12" AND "2014-01-12"
    GROUP BY 1 ORDER BY 1 DESC;
    



-- 26 - ASSIGNMENT: QUALITY ISSUE AND REFUNDS
-- (Dated - oct 15, 2014)
-- mr.fuzzy supplier had some quality issus which weren't corrected until sep 2013
-- Then they had a major prblm where the bears' arms were falling off in aug/sep 2014
-- as a result, we replaced them with a new supplier on sep 16, 2014
-- to pull monthly product refund rates, by product, and confirm our quality issues are now fixed

-- select * from order_item_refunds;
-- select * from order_items;    
SELECT 
	YEAR(order_items.created_at) yr,
    MONTH(order_items.created_at) mo,
    COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_items.order_item_id ELSE NULL END) p1_orders,
    (COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_item_refunds.order_item_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN order_items.product_id=1 THEN order_items.order_item_id ELSE NULL END)) p1_refund_rate,
        
	COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_items.order_item_id ELSE NULL END) p2_orders,
    (COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_item_refunds.order_item_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN order_items.product_id=2 THEN order_items.order_item_id ELSE NULL END)) p2_refund_rate,
        
	COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_items.order_item_id ELSE NULL END) p3_orders,
    (COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_item_refunds.order_item_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN order_items.product_id=3 THEN order_items.order_item_id ELSE NULL END)) p3_refund_rate,
        
	COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_items.order_item_id ELSE NULL END) p4_orders,
    (COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_item_refunds.order_item_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN order_items.product_id=4 THEN order_items.order_item_id ELSE NULL END)) p4_refund_rate
    
	FROM order_items LEFT JOIN order_item_refunds
    ON order_items.order_item_id = order_item_refunds.order_item_id
    WHERE order_items.created_at < "2014-10-15"
    GROUP BY 1, 2;
    



-- 27 - ASSIGNMENT: REPEAT VISITORS
-- (Dated - nov 1, 2014) 
-- to pull on how many of our website visitors come back for another session (2014 to date)
/*
SELECT 
	DISTINCT SUM(is_repeat_session)
	FROM website_sessions
    WHERE created_at > "2014-01-01"
		AND created_at < "2014-11-01"
	GROUP BY user_id                                       -- customers repetitions
*/

SELECT 
	repetitions,
    COUNT(user_id) repeters
    FROM(
		SELECT 
			user_id,
			SUM(is_repeat_session) repetitions
		FROM website_sessions
		WHERE created_at > "2014-01-01"
			AND created_at < "2014-11-01"
		GROUP BY user_id) repeating_customers
	GROUP BY 1
    ORDER BY 1;  
    



-- 28 - ASSIGNMENT: DEEPER DIVE ON REPEAT
-- (Dated - nov 3, 2014)
-- to pull min, max and avg time between the first and second session for customers who come back (2014 to date)

CREATE TEMPORARY TABLE repeat_sessions
SELECT 
    user_id,
    SUM(is_repeat_session) repeaters
    FROM website_sessions
    WHERE created_at > "2014-01-01"
		AND created_at < "2014-11-03" 
	GROUP BY 1
    HAVING SUM(is_repeat_session)=1;

SELECT * FROM  repeat_sessions;

CREATE TEMPORARY TABLE second_time_only
SELECT 
	user_id,
	MIN(created_at) second_visit
    FROM website_sessions
    WHERE is_repeat_session=1
    GROUP BY 1;
    
CREATE TEMPORARY TABLE repeat_only_once
SELECT 
	repeat_sessions.user_id,
    second_visit
    FROM repeat_sessions LEFT JOIN second_time_only 
    ON repeat_sessions.user_id = second_time_only.user_id;
    
CREATE TEMPORARY TABLE once_repeated_customers
SELECT
	repeat_only_once.user_id,
    website_sessions.created_at,
    website_sessions.is_repeat_session
    FROM repeat_only_once LEFT JOIN website_sessions
    ON repeat_only_once.user_id = website_sessions.user_id;
    
SELECT
	MIN(date_dif) min_date_dif,
    MAX(date_dif) max_date_dif,
    AVG(date_dif) avg_date_dif FROM(
	
    SELECT 
		user_id,
		MIN(first_visit) first_visit,
		MIN(second_visit) second_visit,
		DATEDIFF(MIN(second_visit), MIN(first_visit)) date_dif
		FROM(
			
            SELECT 
				user_id,
				CASE WHEN is_repeat_session=0 THEN created_at END AS first_visit,
				CASE WHEN is_repeat_session=1 THEN created_at END AS second_visit
				FROM once_repeated_customers) final_table_1
	
    GROUP BY user_id) final_table_2;
    



-- 29 - ASSIGNMENT: REPEAT CHANNEL MIX
-- (Dated - nov 5, 2014)
-- comparing new vs repeat sessions by channel (2014 to date)
-- are they direct type-in or we are paying with paid search
	
SELECT 
	CASE 
		WHEN http_referer IS NULL THEN "direct_traffic"
        WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN "organic_search"
        WHEN utm_campaign="brand" THEN "brand_paid"
        WHEN utm_campaign="nonbrand" THEN "nonbrand_paid"
        WHEN utm_source="socialbook" THEN "socialbook_paid" END AS channel_grp,
	
    COUNT(DISTINCT CASE WHEN is_repeat_session=0 THEN website_session_id END) new_sessions,
	COUNT(DISTINCT CASE WHEN is_repeat_session=1 THEN website_session_id END) repeat_sessions
    FROM website_sessions
    WHERE created_at > "2014-01-01"
		AND created_at < "2014-11-05"
	GROUP BY 1
    ORDER BY 3 DESC;
    



-- 30 - ASSIGNMENT: TOP WEBSITE PAGES
-- (Dated - nov 8, 2014)
-- comparision of cvr and revenue per session for repeat sessions vs new sessions (2014 to date)
    
SELECT 
	is_repeat_session,
	COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.order_id) orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) cvr,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) rev_per_session
	FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    WHERE website_sessions.created_at >= "2014-01-01"
		AND website_sessions.created_at < "2014-11-08"
	GROUP BY is_repeat_session;
    



-- 													FINAL COURSE PROJECT

-- 1 - to show volume growth
-- to pull overall session and order volume, trended by quarter for the life of the business
-- handle data since the most recent quarter is incomplete
SELECT 
	YEAR(website_sessions.created_at) yr,
    QUARTER(website_sessions.created_at) quar,
    COUNT(DISTINCT website_sessions.website_session_id) sessions,
    COUNT(DISTINCT orders.order_id) orders
    FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    -- WHERE YEAR(website_sessions.created_at) NOT IN (2015)
    GROUP BY 1, 2
    ORDER BY 1, 2;
    
-- 2 - showcase all efficiency improvements
-- to show quarterly figures since we launched, for session to order conversion rate,
-- 					revenue per order, and revenue per session
SELECT 
	YEAR(website_sessions.created_at) yr,
    QUARTER(website_sessions.created_at) quar,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) conversion_rate,
    ROUND(SUM(price_usd)/COUNT(DISTINCT orders.order_id),2) revenue_per_order,
    ROUND(SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id),2) revenue_per_session
    FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    -- WHERE YEAR(website_sessions.created_at) NOT IN (2015)
    GROUP BY 1, 2
    ORDER BY 1, 2;
    
-- 3 - to pull quarterly view of orders from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic and direct search
				-- checking specific channels
    
-- SELECT DISTINCT utm_source, utm_campaign, http_referer FROM website_sessions;
SELECT
	YEAR(website_sessions.created_at) yr,
    QUARTER(website_sessions.created_at) quar,
	COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND utm_campaign="nonbrand" THEN orders.order_id END) gsearch_nonbrand,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND utm_campaign="nonbrand" THEN orders.order_id END) bsearch_nonbrand,
    COUNT(DISTINCT CASE WHEN utm_source="socialbook" OR utm_campaign="brand" THEN orders.order_id END) brand_search,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id END) organic_search,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id END) direct_type_in
    FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    GROUP BY 1, 2
    ORDER BY 1, 2;
    
-- 4 
-- cvr for each channels by quarter, make a note of any periods of major improvements or optimizations
SELECT
	yr, quar,
    gsearch_nonbrand_orders / gsearch_nonbrand_sessions AS gsearch_nonbrand_CVR,
    bsearch_nonbrand_orders / bsearch_nonbrand_sessions AS bsearch_nonbrand_CVR,
    brand_search_orders / brand_search_sessions AS brand_search_CVR,
    organic_search_orders / organic_search_sessions AS organic_search_CVR,
    direct_type_in_orders / direct_type_in_sessions AS direct_type_in_CVR
    FROM
(SELECT
	YEAR(website_sessions.created_at) yr,
    QUARTER(website_sessions.created_at) quar,
    
	COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND utm_campaign="nonbrand" THEN orders.order_id END) gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND utm_campaign="nonbrand" THEN website_sessions.website_session_id END) gsearch_nonbrand_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND utm_campaign="nonbrand" THEN orders.order_id END) bsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND utm_campaign="nonbrand" THEN website_sessions.website_session_id END) bsearch_nonbrand_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source="socialbook" OR utm_campaign="brand" THEN orders.order_id END) brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source="socialbook" OR utm_campaign="brand" THEN website_sessions.website_session_id END) brand_search_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id END) organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id END) organic_search_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id END) direct_type_in_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id END) direct_type_in_sessions
    
    FROM website_sessions LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
    GROUP BY 1, 2
    ORDER BY 1, 2) AS channels

GROUP BY 1, 2
ORDER BY 1, 2;

-- 5
-- to pull monthly trends for revenue and margin by product, along with total sales and revenue

-- SELECT DISTINCT product_id, product_name FROM products;
SELECT
	YEAR(created_at) yr,
    MONTH(created_at) mon,
    
    SUM(CASE WHEN product_id=1 THEN price_usd END) mrfuzzy_revenue,
    SUM(CASE WHEN product_id=1 THEN (price_usd - cogs_usd) END) mrfuzzy_margin,
    
    SUM(CASE WHEN product_id=2 THEN price_usd END) lovebear_revenue,
    SUM(CASE WHEN product_id=2 THEN (price_usd - cogs_usd) END) lovebear_margin,
    
    SUM(CASE WHEN product_id=3 THEN price_usd END) birthday_revenue,
    SUM(CASE WHEN product_id=3 THEN (price_usd - cogs_usd) END) birthday_margin,
    
    SUM(CASE WHEN product_id=4 THEN price_usd END) minibear_revenue,
    SUM(CASE WHEN product_id=4 THEN (price_usd - cogs_usd) END) minibear_margin,
    
    SUM(price_usd) total_revenue,
    SUM(price_usd - cogs_usd) total_margin
    FROM order_items
    GROUP BY 1, 2
    ORDER BY 1, 2;
    
-- 6
-- to pull monthly sessions to the /products page, and show how the % of those sessions clicking through aother page has changed 
-- 							over time, along side with a view of how conversion from /products to placing an order has improved

CREATE TEMPORARY TABLE products_pgv
SELECT 
	website_session_id,
    website_pageview_id AS products_pgv_id,
    created_at
    FROM website_pageviews
    WHERE pageview_url="/products";
    
SELECT 
	YEAR(products_pgv.created_at) yr,
    MONTH(products_pgv.created_at) mon,
    COUNT(DISTINCT products_pgv.website_session_id) clicked_products,
    COUNT(DISTINCT website_pageviews.website_session_id) clicked_another_pg,
    COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT products_pgv.website_session_id) rate_clicked_another_pg,
    COUNT(DISTINCT orders.website_session_id) placed_order,
    COUNT(DISTINCT orders.website_session_id)/COUNT(DISTINCT products_pgv.website_session_id) rate_products_to_order
    FROM products_pgv
    LEFT JOIN website_pageviews
    ON products_pgv.website_session_id = website_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > products_pgv.products_pgv_id
	LEFT JOIN orders
    ON orders.website_session_id = products_pgv.website_session_id
    GROUP BY 1, 2;
    
-- 7
-- 4th product as primary product since DECEMBER 05, 2014
-- to pull sales data since then, and show how well each product cross-sells from one another
 
 CREATE TEMPORARY TABLE primary_products
SELECT order_id, primary_product_id, created_at FROM orders WHERE created_at > "2014-12-05"; 
 
SELECT 
	primary_product_id,
    COUNT(DISTINCT order_id) total_orders,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=1 THEN order_id END) AS x_sell_p1,
	COUNT(DISTINCT CASE WHEN cross_sell_product_id=2 THEN order_id END) AS x_sell_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=3 THEN order_id END) AS x_sell_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=4 THEN order_id END) AS x_sell_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=1 THEN order_id END)/COUNT(DISTINCT order_id) x_sell_p1_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=2 THEN order_id END)/COUNT(DISTINCT order_id) x_sell_p2_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=3 THEN order_id END)/COUNT(DISTINCT order_id) x_sell_p3_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id=4 THEN order_id END)/COUNT(DISTINCT order_id) x_sell_p4_rt
FROM(
	SELECT
		primary_products.*,
        order_items.product_id AS cross_sell_product_id
        FROM primary_products LEFT JOIN order_items
        ON primary_products.order_id = order_items.order_id
			AND is_primary_item=0) cross_sell
GROUP BY 1;

-- 8
-- open ended - conversion funnel for each product
-- SELECT DISTINCT pageview_url FROM website_pageviews;


SELECT 
	prd_name,
    home_pg/(SELECT SUM(home_pg) home_pg_total FROM conversion_values) AS rate_through_home_pg,
    prod_pg/home_pg,
    cart_pg/prod_pg AS rate_through_cart_pg,
    ship_pg/cart_pg AS rate_through_ship_pg,
    bill_pg/ship_pg AS rate_through_bill_pg,
    thanks_pg/bill_pg AS rate_through_thanks_pg
    FROM (

-- CREATE TEMPORARY TABLE conversion_values
SELECT 
	CASE WHEN mrfuzzy=1 THEN "mrfuzzy"
		 WHEN lovebear=1 THEN "lovebear"
         WHEN bdaybear=1 THEN "bdaybear"
         WHEN minibear=1 THEN "minibear"
	ELSE "bounced_from_prd_pg"
    END AS prd_name,
    SUM(home_pg) AS home_pg,
    SUM(prod_pg) AS prod_pg,
    SUM(cart_pg) AS cart_pg,
    SUM(ship_pg) AS ship_pg,
    SUM(bill_pg) AS bill_pg,
    SUM(thanks_pg) AS thanks_pg
FROM(
    
	SELECT 
		website_session_id,
		MAX(home_pg) home_pg,
		MAX(prod_pg) prod_pg,
		MAX(mrfuzzy) mrfuzzy,
		MAX(lovebear) lovebear,
		MAX(bdaybear) bdaybear,
		MAX(minibear) minibear,
		MAX(cart_pg) cart_pg,
		MAX(ship_pg) ship_pg,
		MAX(bill_pg) bill_pg,
		MAX(thanks_pg) thanks_pg 
	FROM(
    
		SELECT 
			website_session_id,
			CASE WHEN pageview_url="/home" OR pageview_url="/lander-1" OR pageview_url="/lander-2" OR
					pageview_url="/lander-3" OR pageview_url="/lander-4" OR pageview_url="/lander-5" THEN 1 ELSE 0 END AS home_pg,
			CASE WHEN pageview_url="/products" THEN 1 ELSE 0 END AS prod_pg,
			CASE WHEN pageview_url="/the-original-mr-fuzzy" THEN 1 ELSE 0 END mrfuzzy,
			CASE WHEN pageview_url="/the-forever-love-bear" THEN 1 ELSE 0 END lovebear, 
			CASE WHEN pageview_url="/the-birthday-sugar-panda" THEN 1 ELSE 0 END bdaybear, 
			CASE WHEN pageview_url="/the-hudson-river-mini-bear" THEN 1 ELSE 0 END minibear,
			CASE WHEN pageview_url="/cart" THEN 1 ELSE 0 END AS cart_pg,
			CASE WHEN pageview_url="/shipping" THEN 1 ELSE 0 END AS ship_pg,
			CASE WHEN pageview_url="/billing" OR pageview_url="/billing-2" THEN 1 ELSE 0 END AS bill_pg,
			CASE WHEN pageview_url="/thank-you-for-your-order" THEN 1 ELSE 0 END AS thanks_pg
		FROM website_pageviews) funnel
		GROUP BY 1) funnel_1
GROUP BY 1) F2
GROUP BY 1
ORDER BY rate_through_home_pg DESC;



-- 											(OR)



WITH pageviews AS (
    SELECT 
        website_session_id,
        MAX(CASE WHEN pageview_url IN ('/home', '/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5') THEN 1 ELSE 0 END) AS homepg,
        MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END) AS prodpg,
        MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy,
        MAX(CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END) AS lovebear,
        MAX(CASE WHEN pageview_url = '/the-birthday-sugar-panda' THEN 1 ELSE 0 END) AS bdaybear,
        MAX(CASE WHEN pageview_url = '/the-hudson-river-mini-bear' THEN 1 ELSE 0 END) AS minibear,
        MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cartpg,
        MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shippg,
        MAX(CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS billpg,
        MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankspg
    FROM website_pageviews
    GROUP BY website_session_id
),
funnel AS (
    SELECT
        'mr_fuzzy' AS product,
        SUM(mrfuzzy) AS product_views,
        SUM(CASE WHEN mrfuzzy = 1 THEN cartpg END) AS to_cart,
        SUM(CASE WHEN mrfuzzy = 1 THEN shippg END) AS to_ship,
        SUM(CASE WHEN mrfuzzy = 1 THEN billpg END) AS to_bill,
        SUM(CASE WHEN mrfuzzy = 1 THEN thankspg END) AS to_thanks
    FROM pageviews
    UNION ALL
    SELECT
        'love_bear' AS product,
        SUM(lovebear) AS product_views,
        SUM(CASE WHEN lovebear = 1 THEN cartpg END) AS to_cart,
        SUM(CASE WHEN lovebear = 1 THEN shippg END) AS to_ship,
        SUM(CASE WHEN lovebear = 1 THEN billpg END) AS to_bill,
        SUM(CASE WHEN lovebear = 1 THEN thankspg END) AS to_thanks
    FROM pageviews
    UNION ALL
    SELECT
        'birthday_bear' AS product,
        SUM(bdaybear) AS product_views,
        SUM(CASE WHEN bdaybear = 1 THEN cartpg END) AS to_cart,
        SUM(CASE WHEN bdaybear = 1 THEN shippg END) AS to_ship,
        SUM(CASE WHEN bdaybear = 1 THEN billpg END) AS to_bill,
        SUM(CASE WHEN bdaybear = 1 THEN thankspg END) AS to_thanks
    FROM pageviews
    UNION ALL
    SELECT
        'mini_bear' AS product,
        SUM(minibear) AS product_views,
        SUM(CASE WHEN minibear = 1 THEN cartpg END) AS to_cart,
        SUM(CASE WHEN minibear = 1 THEN shippg END) AS to_ship,
        SUM(CASE WHEN minibear = 1 THEN billpg END) AS to_bill,
        SUM(CASE WHEN minibear = 1 THEN thankspg END) AS to_thanks
    FROM pageviews
)
SELECT
    product,
    product_views,
    to_cart,
    to_ship,
    to_bill,
    to_thanks,
    CAST(to_cart AS FLOAT) / product_views AS cart_conversion,
    CAST(to_ship AS FLOAT) / product_views AS ship_conversion,
    CAST(to_bill AS FLOAT) / product_views AS bill_conversion,
    CAST(to_thanks AS FLOAT) / product_views AS thanks_conversion
FROM funnel; 
    

    
    
