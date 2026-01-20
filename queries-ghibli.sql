SELECT * FROM ghibli;

SELECT DISTINCT(country_or_place_of_residence) FROM ghibli;
SELECT DISTINCT(gender) FROM ghibli;
SELECT DISTINCT(species) FROM ghibli;

-- Questions

-- 1. Find the average age and percentage of characters by gender.

SELECT gender, 
       AVG(age) AS average_age,
	   (COUNT(*)::numeric / total.total_count) * 100 AS percentage
FROM ghibli
CROSS JOIN (
    SELECT COUNT(*) AS total_count
    FROM ghibli
) AS total
GROUP BY gender, total_count
ORDER BY average_age DESC;

--2. Retrieve the top 3 countries or places of residence with the height more than highest average height of characters.

WITH ranked_heights AS (
    SELECT 
        country_or_place_of_residence,
        height_cm,
        RANK() OVER (PARTITION BY country_or_place_of_residence ORDER BY height_cm DESC) AS height_rank
    FROM ghibli
    WHERE height_cm > (SELECT AVG(height_cm) FROM ghibli)
)

SELECT country_or_place_of_residence, height_cm
FROM ranked_heights
WHERE height_rank = 1
ORDER BY height_cm DESC
LIMIT 3;

--3. Find characters who share the same set of special powers.

WITH character_powers AS (
    SELECT
        character_name,
        UNNEST(string_to_array(special_powers, ', ')) AS powers
    FROM
        ghibli
    WHERE
        special_powers IS NOT NULL
        AND special_powers <> 'N/A'
)

SELECT
    cp1.character_name AS character1,
    cp2.character_name AS character2,
    cp1.powers
FROM
    character_powers cp1
JOIN
    character_powers cp2 ON cp1.powers = cp2.powers
                          AND cp1.character_name < cp2.character_name
GROUP BY
    cp1.character_name, cp2.character_name, cp1.powers
ORDER BY
    character1, character2;
              
--4. Calculate the total number of characters and the percentage of characters by species.

SELECT species,
       COUNT(*) AS total_number_of_characters,
       (COUNT(*)::numeric/total.total_count)*100 AS percentage
FROM ghibli
CROSS JOIN(
          SELECT COUNT(*) AS total_count
          FROM ghibli
) AS total
GROUP BY species, total_count
ORDER BY 2 DESC;

--5. Identify characters with unique special powers not shared by any other character.

WITH Split AS (
    SELECT
        character_name,
        UNNEST(string_to_array(special_powers, ', ')) AS individual_power
    FROM
        ghibli
)
SELECT
    character_name,
    individual_power
FROM
    Split
WHERE
    individual_power IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM Split AS s2
        WHERE Split.character_name <> s2.character_name
        AND Split.individual_power = s2.individual_power
    );

--6. Rank (can use either RANK() or ROWNUMBER()) movies based on the height of characters in descending order.
SELECT character_name, 
       height_cm AS Height,
	   RANK() OVER(PARTITION BY character_name ORDER BY height_cm DESC) AS height_rank
FROM ghibli
GROUP BY character_name, height_cm
ORDER BY 2 DESC;

--OR

SELECT character_name, 
       height_cm AS Height,
	   ROW_NUMBER() OVER(ORDER BY height_cm DESC) AS height_rank
FROM ghibli
GROUP BY character_name, height_cm
ORDER BY 2 DESC;

--7. Find characters who have appeared in movies released after year 200 and have a height above the average height of characters in their respective movies.

SELECT character_name, 
       gh.movie,
	   height_cm,
	   release_date
FROM ghibli AS gh
JOIN (
     SELECT movie,
            AVG(height_cm) AS Average_height
     FROM ghibli
     GROUP BY movie) AS avg_ht
ON gh.movie = avg_ht.movie
WHERE release_date > 2000  AND gh.height_cm > avg_ht.Average_height;

--8. How many powers does a character have?

WITH powers AS (
    SELECT
        character_name,
        UNNEST(string_to_array(special_powers, ', ')) AS individual_powers
    FROM
        ghibli
)

SELECT
    character_name,
    STRING_AGG(individual_powers, ', ') AS all_powers,
    COUNT(DISTINCT CASE WHEN individual_powers <> 'N/A' THEN individual_powers END) AS power_count
FROM
    powers
GROUP BY
    character_name
ORDER BY
    power_count DESC;
