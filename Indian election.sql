SELECT * FROM partywise_results;

SELECT * FROM partywise_results WHERE Party = 'Communist Party of India - CPI';

SELECT * FROM constituencywise_details;

SELECT * FROM constituencywise_results;

SELECT * FROM states_details;

SELECT * FROM statewise_results;

SELECT party as Party_name, won as Seats_won
from partywise_results
where party LIKE '%india%';


-- Total Seats

SELECT DISTINCT COUNT(Parliament_Constituency) AS Total_Seats
FROM constituencywise_results;


--	What are the total number of seats available for the election in each state?
SELECT s.state, COUNT(cr.Parliament_Constituency) AS Total_seats
FROM states_details as s
INNER JOIN statewise_results as sr on s.State_ID = sr.State_ID
INNER JOIN constituencywise_results as cr on cr.Parliament_Constituency = sr.Parliament_Constituency
GROUP BY s.State

-- Total seats won by NDA alliance

SELECT 
	SUM(CASE 
			WHEN party IN (
				'Bharatiya Janata Party - BJP',
				'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
				'Dravida Munnetra Kazhagam - DMK'
				) THEN WON
				ELSE 0
				END) AS NDA_Total_seats_won
from partywise_results


-- Seats won by NDA alliance parties

SELECT party as Party_name, won as Seats_won
FROM partywise_results
where party in (
				'Bharatiya Janata Party - BJP',
				'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
				'Dravida Munnetra Kazhagam - DMK'
				)


-- Total Seats won by I.N.D.I.A. alliance

SELECT
	SUM(CASE WHEN party IN (
				'All India Majlis-E-Ittehadul Muslimeen - AIMIM',
				'All India Trinamool Congress - AITC',
				'Communist Party of India - CPI',
				'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
				'Communist Party of India  (Marxist) - CPI(M)',
				'Indian National Congress - INC',
				'Indian Union Muslim League - IUML'
			) THEN Won
			ELSE 0
			END) as INDIA_Alliance_parties
FROM partywise_results


-- Seats won by I.N.D.I.A. alliance parties

SELECT party as Party_name, Won as Seats_won
from partywise_results
where party IN (
				'All India Majlis-E-Ittehadul Muslimeen - AIMIM',
				'All India Trinamool Congress - AITC',
				'Communist Party of India - CPI',
				'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
				'Communist Party of India  (Marxist) - CPI(M)',
				'Indian National Congress - INC',
				'Indian Union Muslim League - IUML'
			)
order by Seats_won desc;

-- Add a new column field in the partywise_results to get the party aliance as NDA, I.N.D.I.A. and others

ALTER TABLE partywise_results
ADD Party_alliance VARCHAR(50)

UPDATE partywise_results
SET Party_alliance = 'I.N.D.I.A'
WHERE party LIKE '%INDIA%'


UPDATE partywise_results
SET Party_alliance = 'NDA'
WHERE party LIKE '%AAM%'
	OR party LIKE '%SOM%'
	OR party LIKE '%INDEPENDENT%'
	OR party LIKE '%NATIONALIST%'
	OR party LIKE '%RASHTRIYA%'


UPDATE partywise_results
SET Party_alliance = 'Others'
WHERE Party_alliance IS NULL


SELECT Party_alliance, SUM(Won) Total_seats_won
FROM partywise_results
GROUP BY Party_alliance
ORDER BY Total_seats_won DESC

SELECT party, won
from partywise_results
where party_alliance = 'NDA'
ORDER BY won desc

-- Winning candidate’s name, their party votes, total votes, and margin of victory for a specific state and constituency

SELECT 
	cr.Winning_candidate,
	pr.party,
	cr.total_votes,
	cr.margin,
	s.state,
	cr.constituency_name
FROM
	constituencywise_results cr
inner join 
	partywise_results pr on cr.Party_ID = pr.Party_ID
inner join 
	statewise_results sr on cr.Parliament_Constituency = sr.Parliament_Constituency
inner join 
	states_details s on sr.State_ID = s.state_id
where 
	cr.Constituency_Name = 'LAKSHADWEEP'

-- What's the distribution EVM notes versus portal votes for candidates in a specific constituency

SELECT 
	cd.EVM_votes,
	cd.Postal_votes,
	cd.Total_votes,
	cd.candidate,
	cr.Constituency_name
FROM 
	constituencywise_results cr 
JOIN 
	constituencywise_details cd on cr.Constituency_ID = cd.Constituency_ID
where 
	cr.Constituency_Name = 'AMETHI'


-- Which party won the most seat in a state, and how many seats did each party win?

SELECT 
	p.party,
	COUNT(cr.Constituency_ID) AS Seats_won
FROM
	constituencywise_results cr
JOIN
	partywise_results p on cr.Party_ID = p.Party_ID
JOIN
	statewise_results sr on cr.Parliament_Constituency = sr.Parliament_Constituency
JOIN 
	states_details s on sr.State_ID = s.State_ID
where 
	s.State = 'Andhra Pradesh'
GROUP BY 
	P.Party
ORDER BY 
	Seats_won DESC


-- What's the total number of seats won by each party alliance (NDA, I.N.D.I.A, and Others) 
-- in each state for the India Election 2024


SELECT 
	s.State,
	SUM(CASE WHEN p.Party_alliance = 'NDA' THEN 1 ELSE 0 END) AS NDA_Seats_Won,
	SUM(CASE WHEN p.Party_alliance = 'I.N.D.I.A' THEN 1 ELSE 0 END) AS INDIA_Seats_Won,
	SUM(CASE WHEN p.Party_alliance = 'Others' THEN 1 ELSE 0 END) AS Other_Seats_Won
FROM
	constituencywise_results cr
JOIN
	partywise_results p on cr.Party_ID = p.Party_ID
JOIN
	statewise_results sr on cr.Parliament_Constituency = sr.Parliament_Constituency
JOIN 
	states_details s on sr.State_ID = s.State_ID

GROUP BY 
	s.State



-- Which candidate received the highest number of EVM votes in each constituency (Top 10)

SELECT TOP 10
	cr.Constituency_Name,
	cd.Constituency_ID,
	cd.Candidate,
	cd.EVM_Votes

FROM
	constituencywise_details cd
JOIN 
	constituencywise_results cr on cd.Constituency_ID = cr.Constituency_ID
WHERE
	cd.EVM_Votes = (
		SELECT MAX(cd1.EVM_Votes)
		FROM constituencywise_details cd1
		WHERE cd1.Constituency_ID = cd.Constituency_ID
	)
ORDER BY 
	cd.EVM_Votes DESC


-- Which candidate won and which was the runner up in each constituency of the state of the 2024 election

WITH RankedCandidates AS (
    SELECT 
        cd.Constituency_ID,
        cd.Candidate,
        cd.Party,
        cd.EVM_Votes,
        cd.Postal_Votes,
        cd.EVM_Votes + cd.Postal_Votes AS Total_Votes,
        ROW_NUMBER() OVER (PARTITION BY cd.Constituency_ID ORDER BY cd.EVM_Votes + cd.Postal_Votes DESC) AS VoteRank
    FROM 
        constituencywise_details cd
    JOIN 
        constituencywise_results cr ON cd.Constituency_ID = cr.Constituency_ID
    JOIN 
        statewise_results sr ON cr.Parliament_Constituency = sr.Parliament_Constituency
    JOIN 
        states_details s ON sr.State_ID = s.State_ID
    WHERE 
        s.State = 'Maharashtra'
)

SELECT 
    cr.Constituency_Name,
    MAX(CASE WHEN rc.VoteRank = 1 THEN rc.Candidate END) AS Winning_Candidate,
    MAX(CASE WHEN rc.VoteRank = 2 THEN rc.Candidate END) AS Runnerup_Candidate
FROM 
    RankedCandidates rc
JOIN 
    constituencywise_results cr ON rc.Constituency_ID = cr.Constituency_ID
GROUP BY 
    cr.Constituency_Name
ORDER BY 
    cr.Constituency_Name;


-- For the state of Maharashtra, what are the total number of seats, total number of candidates, total number of parties, total votes (including EVM and postal), and the breakdown of EVM and postal votes?

SELECT 
    COUNT(DISTINCT cr.Constituency_ID) AS Total_Seats,
    COUNT(DISTINCT cd.Candidate) AS Total_Candidates,
    COUNT(DISTINCT p.Party) AS Total_Parties,
    SUM(cd.EVM_Votes + cd.Postal_Votes) AS Total_Votes,
    SUM(cd.EVM_Votes) AS Total_EVM_Votes,
    SUM(cd.Postal_Votes) AS Total_Postal_Votes
FROM 
    constituencywise_results cr
JOIN 
    constituencywise_details cd ON cr.Constituency_ID = cd.Constituency_ID
JOIN 
    statewise_results sr ON cr.Parliament_Constituency = sr.Parliament_Constituency
JOIN 
    states_details s ON sr.State_ID = s.State_ID
JOIN 
    partywise_results p ON cr.Party_ID = p.Party_ID
WHERE 
    s.State = 'Maharashtra';


