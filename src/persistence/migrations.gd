## Liste ordonnée des migrations SQLite. La version du schéma est stockée dans PRAGMA user_version.
## Règle : ne jamais modifier une migration publiée ; en ajouter une nouvelle à la fin.
extends RefCounted

const ALL: Array[Dictionary] = [
	{
		"version": 1,
		"name": "initial_career",
		"statements": [
			"""CREATE TABLE career (
				id TEXT PRIMARY KEY NOT NULL,
				name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 64),
				game_date TEXT NOT NULL,  -- date de jeu ISO AAAA-MM-JJ (current_date est un mot réservé SQLite)
				status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired')),
				created_at TEXT NOT NULL
			);""",
		],
	},
]


static func latest_version() -> int:
	return ALL[ALL.size() - 1]["version"]
