USE acnh;

SELECT * FROM outfit_colors;

# Check distinct colors
SELECT distinct(`Color 1`) from accessories
ORDER BY `Color 1`;

# Create a separate table for colors and give unique numbers 
CREATE TABLE colors (
id INT, color VARCHAR(255));

INSERT INTO colors(id, color)
VALUES (1, "Beige"),
		(3, "Black"), 
        (7, "Blue"), 
        (15, "Brown"), 
        (31, "Colorful"), 
        (63, "Gray"), 
        (127, "Green"), 
        (255, "Light Blue"), 
        (511, "Orange"), 
        (1023, "Pink"), 
        (2047, "Purple"), 
        (4095, "Red"), 
        (8191, "White"), 
        (16383, "Yellow");
        
SELECT * FROM colors;

# Create a separate table of color usage info of outfit items
DROP TABLE IF EXISTS outfit_colors;
CREATE TABLE outfit_colors 

WITH outfit_colors AS (
SELECT "AC" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM accessories
UNION ALL
SELECT "BA" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM bags
UNION ALL
SELECT "TO" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM tops
UNION ALL
SELECT "BO" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM bottoms
UNION ALL
SELECT "DR" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM dressup
UNION ALL
SELECT "HE" as inventory,  `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM headwear
UNION ALL
SELECT "SH" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM shoes
UNION ALL
SELECT "SO" as inventory, `Internal ID` as internal_id, Name, `Color 1` as main_color, `Color 2` as second_color, Style FROM socks)

SELECT * FROM outfit_colors;


# Main Color / Second Color Popularity
SELECT 
	C1.main_color as Color, 
    C1.main_counts, 
    RANK() OVER (ORDER BY C1.main_counts DESC) as main_rank,
    C2.second_counts,
    RANK() OVER (ORDER BY C2.second_counts DESC) as second_rank
FROM
(SELECT 
	main_color, 
	COUNT(DISTINCT(internal_id)) as main_counts 
FROM outfit_colors 
GROUP BY main_color) as C1
INNER JOIN 
(SELECT
	second_color, 
	COUNT(DISTINCT(internal_id)) as second_counts 
FROM outfit_colors 
GROUP BY second_color) as C2
ON C1.main_color = C2.second_color
ORDER BY main_rank;


# The item with the most number of color variation per inventory category
SELECT inventory, Name, count(main_color) as counts,
	dense_rank() over (partition by inventory order by count(main_color) desc) as inventory_counts_rank
FROM outfit_colors
GROUP BY inventory, Name
ORDER BY inventory desc;

# Ordered Combination Popularity
SELECT 
	c1.main_color as color_a, c1.second_color as color_b, 
    c1.combie_order_counts as combie_counts_ab,
    DENSE_RANK () OVER (ORDER BY c1.combie_order_counts DESC) as combie_counts_ab_rank,
	c2.combie_order_counts as combie_counts_ba,
    DENSE_RANK () OVER (ORDER BY c2.combie_order_counts DESC) as combie_counts_ba_rank
FROM
(SELECT main_color, second_color, count(internal_id) as combie_order_counts
FROM outfit_colors
GROUP BY main_color, second_color) as C1
INNER JOIN 
(SELECT main_color, second_color, count(internal_id) as combie_order_counts
FROM outfit_colors
GROUP BY main_color, second_color) as C2
ON C1.main_color = C2.second_color AND C2.main_color = C1.second_color
ORDER BY abs(c1.combie_order_counts - c2.combie_order_counts);


# Combination Popularity
WITH combie_pop AS (
	SELECT 
		count(t3.internal_id) as counts, 
        total_score 
	FROM (
		SELECT 
			t1.internal_id, 
            main_color, 
            second_color, 
            main_color_score + second_color_score as total_score
		FROM (
			SELECT 
				oc.internal_id, 
                oc.main_color, 
                c.id as main_color_score
			FROM outfit_colors as oc
			INNER JOIN colors as c
			ON oc.main_color = c.color) as t1
	INNER JOIN (
		SELECT 
			oc.internal_id, 
            oc.second_color, 
            c.id as second_color_score
		FROM outfit_colors as oc
		INNER JOIN colors as c
		ON oc.second_color = c.color) as t2
ON t1.internal_id = t2.internal_id) as t3
GROUP BY total_score
ORDER BY total_score desc), 

color_combie AS (
	SELECT 
		max(c1.color) as color_a, 
		min(c2.color) as color_b, 
		c1.id+c2.id as total_score
	FROM colors as c1
	CROSS JOIN
	colors as c2
	GROUP BY c1.id+c2.id
	ORDER BY c1.id+c2.id ASC)

SELECT 
	cc.color_a, 
    cc.color_b, 
    cp.counts,
    dense_rank() OVER (ORDER BY counts DESC) as counts_rank
FROM color_combie as cc
INNER JOIN combie_pop as cp
ON cc.total_score = cp.total_score
ORDER BY counts DESC;



# Main Color - Style Breakdown
SELECT Style, main_color, min(style_counts), min(style_color_counts)
FROM (SELECT main_color, 
		Style, 
        count(internal_id) over (partition by Style) as style_counts, 
        count(internal_id) over (partition by Style, main_color) as style_color_counts FROM outfit_colors
	ORDER BY style_counts desc) as t1
GROUP BY main_color, Style



