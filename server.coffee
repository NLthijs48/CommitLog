exports.onHttp = (request) !->
	if !request.data?
		log 'HTTP: no data'
		return

	parsed = JSON.parse request.data
	if !parsed?
		log 'HTTP: could not parse data'
		return

	Db.shared.set 'received', parsed

	if parsed.push?.changes?
		general = {}
		general.repositoryName = parsed.repository?.name
		general.repositoryFullName = parsed.repository?.full_name
		general.received = new Date()/1000
		general.source = "BitBucket"

		for change in parsed.push.changes
			if !change.commits?
				log 'no commits in change'
				continue

			if change.new?.type is "branch" and change.new?.name isnt "master"
				log 'not on master branch'
				return

			# If the push had more than 5 commits truncated will be true and only the last 5 commits are in here
			# First commit is newest and we want the oldest commit to have the lowest id, so reverse
			for commit in change.commits.reverse()
				commitData = {}
				user = commit.author?.user
				commitData.byName = user?.display_name
				commitData.byUsername = user?.username
				commitData.byUUID = user?.uuid
				commitData.avatar = user?.links?.avatar?.href
				commitData.message = commit.message
				commitData.date = commit.date
				commitData.hash = commit.hash
				commitData.url = commit.links?.html?.href
				applyKeysToObject general, commitData

				# Get next id
				commitMaxId = Db.shared.get('commitMaxId') || 0
				commitMaxId++
				Db.shared.set 'commitMaxId', commitMaxId

				# Set commit data
				Db.shared.set 'commits', commitMaxId, commitData
				log 'BitBucket Commit: '+commitData.message

				# Send notification
				Event.create
					unit: 'commit'
					text: 'Commit: '+general.repositoryName+': '+commit.message
	else if parsed.commits and parsed.commits.length > 0
		general = {}
		general.repositoryName = parsed.repository?.name
		general.repositoryFullName = parsed.repository?.full_name
		general.repositoryUrl = parsed.repository?.url
		general.received = new Date()/1000
		general.source = "GitHub"

		for commit in parsed.commits
			commitData = {}
			commitData.message = commit.message
			commitData.date = commit.timestamp
			commitData.hash = commit.hash
			commitData.byName = commit.author?.name
			commitData.byUsername = commit.author?.username
			commitData.byEmail = commit.author?.email
			commitData.avatar = "https://avatars.githubusercontent.com/"+(commit.author?.username)
			commitData.commitUrl = commit.url
			applyKeysToObject general, commitData

			# Get next id
			commitMaxId = Db.shared.get('commitMaxId') || 0
			commitMaxId++
			Db.shared.set 'commitMaxId', commitMaxId

			# Set commit data
			Db.shared.set 'commits', commitMaxId, commitData
			log 'Github Commit: '+commitData.message

			# Send notification
			Event.create
				unit: 'commit'
				text: 'Commit: '+general.repositoryName+': '+commit.message
	else
		log 'no changes listed in the data'


applyKeysToObject = (source, target) !->
	for key, value of source
		target[key] = value